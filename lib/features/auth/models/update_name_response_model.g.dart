// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_name_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateNameResponseModel _$UpdateNameResponseModelFromJson(
        Map<String, dynamic> json) =>
    UpdateNameResponseModel(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: json['result'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$UpdateNameResponseModelToJson(
        UpdateNameResponseModel instance) =>
    <String, dynamic>{
      'isSuccess': instance.isSuccess,
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
      'error': instance.error,
    };
