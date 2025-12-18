import 'package:json_annotation/json_annotation.dart';

part 'kakao_auth_response_model.g.dart';

@JsonSerializable()
class KakaoAuthResponseModel {
  final bool isSuccess;
  final String code;
  final String message;
  final KakaoAuthResult? result;
  final String? error;

  KakaoAuthResponseModel({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
    this.error,
  });

  factory KakaoAuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$KakaoAuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$KakaoAuthResponseModelToJson(this);
}

@JsonSerializable()
class KakaoAuthResult {
  final String grantType;
  @JsonKey(name: 'accessToken')
  final String accessToken;
  @JsonKey(name: 'refreshToken')
  final String refreshToken;
  @JsonKey(name: 'accessTokenExpiresIn')
  final int accessTokenExpiresIn;
  @JsonKey(name: 'userRole')
  final String userRole;

  KakaoAuthResult({
    required this.grantType,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresIn,
    required this.userRole,
  });

  factory KakaoAuthResult.fromJson(Map<String, dynamic> json) =>
      _$KakaoAuthResultFromJson(json);

  Map<String, dynamic> toJson() => _$KakaoAuthResultToJson(this);
}



