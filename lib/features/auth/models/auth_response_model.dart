import 'package:json_annotation/json_annotation.dart';
import 'package:partition_app/features/auth/models/user_model.dart';

part 'auth_response_model.g.dart';

@JsonSerializable()
class AuthResponseModel {
  final String token;
  final String refreshToken;
  final UserModel user;

  AuthResponseModel({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);
}

