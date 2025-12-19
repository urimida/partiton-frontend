import 'package:json_annotation/json_annotation.dart';

part 'daily_calendar_response_model.g.dart';

@JsonSerializable()
class DailyCalendarResponseModel {
  final bool isSuccess;
  final String code;
  final String message;
  final List<DailyCalendarItem>? result;
  final String? error;

  DailyCalendarResponseModel({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
    this.error,
  });

  factory DailyCalendarResponseModel.fromJson(Map<String, dynamic> json) =>
      _$DailyCalendarResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyCalendarResponseModelToJson(this);
}

@JsonSerializable()
class DailyCalendarItem {
  final String category;
  final int id;
  final String title;
  final String? assigneeName;
  final bool isCompleted;

  DailyCalendarItem({
    required this.category,
    required this.id,
    required this.title,
    this.assigneeName,
    required this.isCompleted,
  });

  factory DailyCalendarItem.fromJson(Map<String, dynamic> json) =>
      _$DailyCalendarItemFromJson(json);

  Map<String, dynamic> toJson() => _$DailyCalendarItemToJson(this);
}














