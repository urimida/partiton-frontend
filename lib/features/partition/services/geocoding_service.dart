import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:partition_app/core/config/app_config.dart';

class PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String formattedAddress;
  final double lat;
  final double lng;

  const PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
  });
}

/// 카카오 검색 결과 래퍼 — 결과 목록과 에러 메시지를 함께 반환
typedef SearchResult = ({List<PlaceSuggestion> results, String? error});

class GeocodingService {
  /// 카카오 REST API 키 유효성 확인
  static bool get hasApiKey {
    const k = AppConfig.kakaoRestApiKey;
    return k.isNotEmpty && k != 'YOUR_KAKAO_REST_API_KEY';
  }

  // ── 역지오코딩 (좌표 → 주소) ─────────────────────────────────────────────

  /// 위도·경도 → 주소 문자열
  /// 카카오 coord2address API 우선, 실패 시 기기 내장 지오코더 폴백
  static Future<String?> reverseGeocode(double lat, double lng) async {
    if (hasApiKey) {
      final kakaoResult = await _kakaoReverseGeocode(lat, lng);
      if (kakaoResult != null) return kakaoResult;
    }
    return _deviceReverseGeocode(lat, lng);
  }

  static Future<String?> _kakaoReverseGeocode(double lat, double lng) async {
    // 1단계: coord2address — 법정동 도로명/지번 상세주소
    final detailed = await _coord2Address(lat, lng);
    if (detailed != null) return detailed;

    // 2단계: coord2regioncode — 행정동 주소 (fallback)
    return _coord2RegionCode(lat, lng);
  }

  /// /v2/local/geo/coord2address.json — 도로명주소 우선, 없으면 지번주소
  static Future<String?> _coord2Address(double lat, double lng) async {
    try {
      final uri = Uri.https(
        'dapi.kakao.com',
        '/v2/local/geo/coord2address.json',
        {'x': '$lng', 'y': '$lat'},
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'KakaoAK ${AppConfig.kakaoRestApiKey}'},
      );
      debugPrint('[GeocodingService] coord2address 응답: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('[GeocodingService] coord2address 오류: ${response.body}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final docs = data['documents'] as List<dynamic>;
      if (docs.isEmpty) return null;

      final doc = docs.first as Map<String, dynamic>;
      // 도로명주소 우선 (JS 샘플의 road_address.address_name)
      final roadAddress = doc['road_address'] as Map<String, dynamic>?;
      if (roadAddress != null) {
        final name = roadAddress['address_name'] as String?;
        if (name != null && name.isNotEmpty) return name;
      }
      // 지번주소 fallback (JS 샘플의 address.address_name)
      final address = doc['address'] as Map<String, dynamic>?;
      return address?['address_name'] as String?;
    } catch (e) {
      debugPrint('[GeocodingService] coord2address 예외: $e');
      return null;
    }
  }

  /// /v2/local/geo/coord2regioncode.json — 행정동(H) 주소
  /// JS 샘플의 geocoder.coord2RegionCode() 에 해당
  static Future<String?> _coord2RegionCode(double lat, double lng) async {
    try {
      final uri = Uri.https(
        'dapi.kakao.com',
        '/v2/local/geo/coord2regioncode.json',
        {'x': '$lng', 'y': '$lat'},
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'KakaoAK ${AppConfig.kakaoRestApiKey}'},
      );
      debugPrint(
          '[GeocodingService] coord2regioncode 응답: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('[GeocodingService] coord2regioncode 오류: ${response.body}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final docs = data['documents'] as List<dynamic>;
      if (docs.isEmpty) return null;

      // JS 샘플처럼 region_type === 'H' (행정동) 인 항목 우선 사용
      for (final d in docs) {
        final doc = d as Map<String, dynamic>;
        if (doc['region_type'] == 'H') {
          final name = doc['address_name'] as String?;
          if (name != null && name.isNotEmpty) return name;
        }
      }
      // 행정동 없으면 첫 번째 결과 사용
      return (docs.first as Map<String, dynamic>)['address_name'] as String?;
    } catch (e) {
      debugPrint('[GeocodingService] coord2regioncode 예외: $e');
      return null;
    }
  }

  static Future<String?> _deviceReverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = <String>[
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
          p.administrativeArea!,
        if (p.subAdministrativeArea != null &&
            p.subAdministrativeArea!.isNotEmpty)
          p.subAdministrativeArea!
        else if (p.locality != null && p.locality!.isNotEmpty)
          p.locality!,
        if (p.thoroughfare != null && p.thoroughfare!.isNotEmpty)
          p.thoroughfare!
        else if (p.subLocality != null && p.subLocality!.isNotEmpty)
          p.subLocality!,
        if (p.subThoroughfare != null && p.subThoroughfare!.isNotEmpty)
          p.subThoroughfare!,
      ];
      return parts.isNotEmpty ? parts.join(' ') : null;
    } catch (e) {
      debugPrint('[GeocodingService] 기기 역지오코딩 실패: $e');
      return null;
    }
  }

  // ── 주소 검색 (카카오 키워드 검색) ────────────────────────────────────────

  /// 키워드로 장소·주소 검색 (카카오 Local keyword API)
  /// 반환: (results, error) — error != null 이면 API 오류 메시지
  static Future<SearchResult> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      return (results: <PlaceSuggestion>[], error: null);
    }
    if (!hasApiKey) {
      return (results: <PlaceSuggestion>[], error: '카카오 REST API 키가 설정되지 않았어요.');
    }

    try {
      final uri = Uri.https(
        'dapi.kakao.com',
        '/v2/local/search/keyword.json',
        {'query': query, 'size': '7'},
      );
      debugPrint('[GeocodingService] 검색 요청 → $uri');

      final response = await http.get(
        uri,
        headers: {'Authorization': 'KakaoAK ${AppConfig.kakaoRestApiKey}'},
      );

      debugPrint('[GeocodingService] 검색 응답: ${response.statusCode}');

      if (response.statusCode != 200) {
        final body = response.body;
        debugPrint('[GeocodingService] 검색 오류 바디: $body');

        // 카카오 에러 코드 파싱
        String errorMsg = '검색 오류 (${response.statusCode})';
        try {
          final errData = json.decode(body) as Map<String, dynamic>;
          final msg = errData['msg'] as String?;
          final code = errData['code'];
          if (msg != null) errorMsg = '$msg (code: $code)';
        } catch (_) {}

        if (response.statusCode == 401) {
          errorMsg = 'API 키 인증 실패 — REST API 키를 확인해주세요.';
        } else if (response.statusCode == 403) {
          errorMsg = 'API 권한 없음 — 카카오 개발자 콘솔에서\n"카카오 지도" API를 활성화해주세요.';
        }
        return (results: <PlaceSuggestion>[], error: errorMsg);
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final docs = data['documents'] as List<dynamic>;
      debugPrint('[GeocodingService] 검색 결과: ${docs.length}건');

      if (docs.isEmpty) {
        return (results: <PlaceSuggestion>[], error: null);
      }

      final suggestions = docs.map((d) {
        final doc = d as Map<String, dynamic>;
        final placeName = (doc['place_name'] as String?) ?? '';
        final roadAddr = (doc['road_address_name'] as String?) ?? '';
        final lotAddr = (doc['address_name'] as String?) ?? '';
        final displayAddr = roadAddr.isNotEmpty ? roadAddr : lotAddr;

        return PlaceSuggestion(
          placeId: (doc['id'] as String?) ?? '',
          mainText: placeName.isNotEmpty ? placeName : displayAddr,
          secondaryText: placeName.isNotEmpty ? displayAddr : '',
          formattedAddress:
              placeName.isNotEmpty ? '$placeName ($displayAddr)' : displayAddr,
          lat: double.tryParse(doc['y'] as String? ?? '') ?? 0,
          lng: double.tryParse(doc['x'] as String? ?? '') ?? 0,
        );
      }).toList();

      return (results: suggestions, error: null);
    } catch (e) {
      debugPrint('[GeocodingService] 카카오 키워드 검색 예외: $e');
      return (results: <PlaceSuggestion>[], error: '네트워크 오류: $e');
    }
  }
}
