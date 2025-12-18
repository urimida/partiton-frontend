// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalendarResponseModel _$CalendarResponseModelFromJson(
        Map<String, dynamic> json) =>
    CalendarResponseModel(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: (json['result'] as List<dynamic>?)
          ?.map((e) => CalendarDayItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$CalendarResponseModelToJson(
        CalendarResponseModel instance) =>
    <String, dynamic>{
      'isSuccess': instance.isSuccess,
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
      'error': instance.error,
    };

CalendarDayItem _$CalendarDayItemFromJson(Map<String, dynamic> json) =>
    CalendarDayItem(
      date: json['date'] as String,
      choreCount: (json['choreCount'] as num).toInt(),
      scheduleCount: (json['scheduleCount'] as num).toInt(),
      utilityBillsCount: (json['utilityBillsCount'] as num).toInt(),
    );

Map<String, dynamic> _$CalendarDayItemToJson(CalendarDayItem instance) =>
    <String, dynamic>{
      'date': instance.date,
      'choreCount': instance.choreCount,
      'scheduleCount': instance.scheduleCount,
      'utilityBillsCount': instance.utilityBillsCount,
    };
