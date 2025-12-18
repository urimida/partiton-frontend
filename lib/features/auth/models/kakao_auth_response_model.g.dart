// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kakao_auth_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KakaoAuthResponseModel _$KakaoAuthResponseModelFromJson(
        Map<String, dynamic> json) =>
    KakaoAuthResponseModel(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: json['result'] == null
          ? null
          : KakaoAuthResult.fromJson(json['result'] as Map<String, dynamic>),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$KakaoAuthResponseModelToJson(
        KakaoAuthResponseModel instance) =>
    <String, dynamic>{
      'isSuccess': instance.isSuccess,
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
      'error': instance.error,
    };

KakaoAuthResult _$KakaoAuthResultFromJson(Map<String, dynamic> json) =>
    KakaoAuthResult(
      grantType: json['grantType'] as String,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      accessTokenExpiresIn: (json['accessTokenExpiresIn'] as num).toInt(),
      userRole: json['userRole'] as String,
    );

Map<String, dynamic> _$KakaoAuthResultToJson(KakaoAuthResult instance) =>
    <String, dynamic>{
      'grantType': instance.grantType,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'accessTokenExpiresIn': instance.accessTokenExpiresIn,
      'userRole': instance.userRole,
    };
