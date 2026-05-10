import 'package:json_annotation/json_annotation.dart';

part 'daily_calendar_response_model.g.dart';

/// Spring/Jackson 등에서 `code`가 숫자로 올 수 있음.
String dailyCalendarApiString(dynamic value) => value?.toString() ?? '';

/// 일정 항목은 `isCompleted`가 null/false인 경우가 있어 null 안전 처리.
bool dailyCalendarApiBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase().trim();
    return v == 'true' || v == '1' || v == 'yes';
  }
  return false;
}

@JsonSerializable()
class DailyCalendarResponseModel {
  final bool isSuccess;
  @JsonKey(fromJson: dailyCalendarApiString)
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
  @JsonKey(fromJson: dailyCalendarApiString)
  final String category;
  final int id;
  @JsonKey(fromJson: dailyCalendarApiString)
  final String title;
  final String? assigneeName;
  @JsonKey(fromJson: dailyCalendarApiBool)
  final bool isCompleted;
  final bool? isOwner;

  DailyCalendarItem({
    required this.category,
    required this.id,
    required this.title,
    this.assigneeName,
    required this.isCompleted,
    this.isOwner,
  });

  factory DailyCalendarItem.fromJson(Map<String, dynamic> json) =>
      _$DailyCalendarItemFromJson(json);

  Map<String, dynamic> toJson() => _$DailyCalendarItemToJson(this);
}















