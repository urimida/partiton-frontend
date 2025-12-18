// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleResponseModel _$ScheduleResponseModelFromJson(
        Map<String, dynamic> json) =>
    ScheduleResponseModel(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: json['result'] as Map<String, dynamic>?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$ScheduleResponseModelToJson(
        ScheduleResponseModel instance) =>
    <String, dynamic>{
      'isSuccess': instance.isSuccess,
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
      'error': instance.error,
    };
