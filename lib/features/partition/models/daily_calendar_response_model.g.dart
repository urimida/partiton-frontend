// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_calendar_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyCalendarResponseModel _$DailyCalendarResponseModelFromJson(
        Map<String, dynamic> json) =>
    DailyCalendarResponseModel(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: (json['result'] as List<dynamic>?)
          ?.map((e) => DailyCalendarItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$DailyCalendarResponseModelToJson(
        DailyCalendarResponseModel instance) =>
    <String, dynamic>{
      'isSuccess': instance.isSuccess,
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
      'error': instance.error,
    };

DailyCalendarItem _$DailyCalendarItemFromJson(Map<String, dynamic> json) =>
    DailyCalendarItem(
      category: json['category'] as String,
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      assigneeName: json['assigneeName'] as String?,
      isCompleted: json['isCompleted'] as bool,
      isOwner: json['isOwner'] as bool?,
    );

Map<String, dynamic> _$DailyCalendarItemToJson(DailyCalendarItem instance) =>
    <String, dynamic>{
      'category': instance.category,
      'id': instance.id,
      'title': instance.title,
      'assigneeName': instance.assigneeName,
      'isCompleted': instance.isCompleted,
      'isOwner': instance.isOwner,
    };
