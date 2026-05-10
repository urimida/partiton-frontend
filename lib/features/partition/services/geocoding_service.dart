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

class GeocodingService {
  static const String _kakaoLocalBase = 'https://dapi.kakao.com';

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
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final docs = data['documents'] as List<dynamic>;
      if (docs.isEmpty) return null;

      final doc = docs.first as Map<String, dynamic>;
      // 도로명 주소 우선, 없으면 지번 주소
      final roadAddress = doc['road_address'] as Map<String, dynamic>?;
      if (roadAddress != null) {
        return roadAddress['address_name'] as String?;
      }
      final address = doc['address'] as Map<String, dynamic>?;
      return address?['address_name'] as String?;
    } catch (e) {
      debugPrint('[GeocodingService] 카카오 역지오코딩 실패: $e');
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
  /// 검색 결과에 위·경도 좌표가 포함되므로 별도 상세 조회 불필요
  static Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (query.trim().isEmpty || !hasApiKey) return [];
    try {
      final uri = Uri.https(
        'dapi.kakao.com',
        '/v2/local/search/keyword.json',
        {'query': query, 'size': '7'},
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'KakaoAK ${AppConfig.kakaoRestApiKey}'},
      );
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final docs = data['documents'] as List<dynamic>;

      return docs.map((d) {
        final doc = d as Map<String, dynamic>;
        final placeName = (doc['place_name'] as String?) ?? '';
        final roadAddr = (doc['road_address_name'] as String?) ?? '';
        final lotAddr = (doc['address_name'] as String?) ?? '';
        final displayAddr = roadAddr.isNotEmpty ? roadAddr : lotAddr;

        return PlaceSuggestion(
          placeId: (doc['id'] as String?) ?? '',
          mainText: placeName.isNotEmpty ? placeName : displayAddr,
          secondaryText: placeName.isNotEmpty ? displayAddr : '',
          formattedAddress: placeName.isNotEmpty
              ? '$placeName ($displayAddr)'
              : displayAddr,
          lat: double.tryParse(doc['y'] as String? ?? '') ?? 0,
          lng: double.tryParse(doc['x'] as String? ?? '') ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('[GeocodingService] 카카오 키워드 검색 실패: $e');
      return [];
    }
  }
}
