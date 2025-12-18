import 'package:json_annotation/json_annotation.dart';

part 'chore_auto_assign_response_model.g.dart';

@JsonSerializable()
class ChoreAutoAssignResponseModel {
  final bool isSuccess;
  final String code;
  final String message;
  final String? result;
  final String? error;

  ChoreAutoAssignResponseModel({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
    this.error,
  });

  factory ChoreAutoAssignResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ChoreAutoAssignResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChoreAutoAssignResponseModelToJson(this);
}

