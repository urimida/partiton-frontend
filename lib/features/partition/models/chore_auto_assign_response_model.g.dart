// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chore_auto_assign_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChoreAutoAssignResponseModel _$ChoreAutoAssignResponseModelFromJson(
        Map<String, dynamic> json) =>
    ChoreAutoAssignResponseModel(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: json['result'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$ChoreAutoAssignResponseModelToJson(
        ChoreAutoAssignResponseModel instance) =>
    <String, dynamic>{
      'isSuccess': instance.isSuccess,
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
      'error': instance.error,
    };
