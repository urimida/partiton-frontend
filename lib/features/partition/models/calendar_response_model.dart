import 'package:json_annotation/json_annotation.dart';

part 'calendar_response_model.g.dart';

@JsonSerializable()
class CalendarResponseModel {
  final bool isSuccess;
  final String code;
  final String message;
  final List<CalendarDayItem>? result;
  final String? error;

  CalendarResponseModel({
    required this.isSuccess,
    required this.code,
    required this.message,
    this.result,
    this.error,
  });

  factory CalendarResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CalendarResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarResponseModelToJson(this);
}

@JsonSerializable()
class CalendarDayItem {
  final String date;
  final int choreCount;
  final int scheduleCount;
  final int utilityBillsCount;

  CalendarDayItem({
    required this.date,
    required this.choreCount,
    required this.scheduleCount,
    required this.utilityBillsCount,
  });

  factory CalendarDayItem.fromJson(Map<String, dynamic> json) =>
      _$CalendarDayItemFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarDayItemToJson(this);
}














