import 'package:json_annotation/json_annotation.dart';

part 'schedule_response_model.g.dart';

@JsonSerializable()
class ScheduleResponseModel {
  final bool isSuccess;
  final String code;
  final String message;
  final Map<String, dynamic>? result;
  final String? error;

  ScheduleResponseModel({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
    this.error,
  });

  factory ScheduleResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduleResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleResponseModelToJson(this);
}









