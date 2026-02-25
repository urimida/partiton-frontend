import 'package:json_annotation/json_annotation.dart';

part 'chore_auto_assign_response_model.g.dart';

@JsonSerializable()
class ChoreAutoAssignResponseModel {
  final bool isSuccess;
  final String code;
  final String message;
  final List<ChoreAssignmentItem>? result;
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

@JsonSerializable()
class ChoreAssignmentItem {
  final int userId;
  final int choreId;
  final String date;

  ChoreAssignmentItem({
    required this.userId,
    required this.choreId,
    required this.date,
  });

  factory ChoreAssignmentItem.fromJson(Map<String, dynamic> json) =>
      _$ChoreAssignmentItemFromJson(json);  Map<String, dynamic> toJson() => _$ChoreAssignmentItemToJson(this);
}