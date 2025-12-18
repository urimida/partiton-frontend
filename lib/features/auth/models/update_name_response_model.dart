import 'package:json_annotation/json_annotation.dart';

part 'update_name_response_model.g.dart';

@JsonSerializable()
class UpdateNameResponseModel {
  final bool isSuccess;
  final String code;
  final String message;
  final String? result; // 이름이 string으로 반환됨
  final String? error;

  UpdateNameResponseModel({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
    this.error,
  });

  factory UpdateNameResponseModel.fromJson(Map<String, dynamic> json) =>
      _$UpdateNameResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateNameResponseModelToJson(this);
}

