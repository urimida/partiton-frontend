import 'package:json_annotation/json_annotation.dart';

part 'household_response_model.g.dart';

@JsonSerializable()
class HouseholdResponseModel {
  final bool isSuccess;
  final String code;
  final String message;
  final HouseholdResult? result;
  final String? error;

  HouseholdResponseModel({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
    this.error,
  });

  factory HouseholdResponseModel.fromJson(Map<String, dynamic> json) =>
      _$HouseholdResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$HouseholdResponseModelToJson(this);
}

@JsonSerializable()
class HouseholdResult {
  final String? code; // 그룹 코드
  final String? name; // 그룹명
  final int? id; // 그룹 ID
  final String? role; // 사용자 역할 (LEADER 등)

  HouseholdResult({
    this.code,
    this.name,
    this.id,
    this.role,
  });

  factory HouseholdResult.fromJson(Map<String, dynamic> json) =>
      _$HouseholdResultFromJson(json);

  Map<String, dynamic> toJson() => _$HouseholdResultToJson(this);
}

