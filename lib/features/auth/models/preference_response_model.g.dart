// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preference_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PreferenceResponseModel _$PreferenceResponseModelFromJson(
        Map<String, dynamic> json) =>
    PreferenceResponseModel(
      isSuccess: json['isSuccess'] as bool,
      code: json['code'] as String,
      message: json['message'] as String,
      result: (json['result'] as List<dynamic>?)
          ?.map((e) => PreferenceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] as String?,
    );

Map<String, dynamic> _$PreferenceResponseModelToJson(
        PreferenceResponseModel instance) =>
    <String, dynamic>{
      'isSuccess': instance.isSuccess,
      'code': instance.code,
      'message': instance.message,
      'result': instance.result,
      'error': instance.error,
    };

PreferenceItem _$PreferenceItemFromJson(Map<String, dynamic> json) =>
    PreferenceItem(
      choreType: json['choreType'] as String,
      score: (json['score'] as num).toInt(),
    );

Map<String, dynamic> _$PreferenceItemToJson(PreferenceItem instance) =>
    <String, dynamic>{
      'choreType': instance.choreType,
      'score': instance.score,
    };
