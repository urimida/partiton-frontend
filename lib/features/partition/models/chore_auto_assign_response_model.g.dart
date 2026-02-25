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
      result: (json['result'] as List<dynamic>?)
          ?.map((e) => ChoreAssignmentItem.fromJson(e as Map<String, dynamic>))
          .toList(),
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

ChoreAssignmentItem _$ChoreAssignmentItemFromJson(Map<String, dynamic> json) =>
    ChoreAssignmentItem(
      userId: (json['userId'] as num).toInt(),
      choreId: (json['choreId'] as num).toInt(),
      date: json['date'] as String,
    );

Map<String, dynamic> _$ChoreAssignmentItemToJson(
        ChoreAssignmentItem instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'choreId': instance.choreId,
      'date': instance.date,
    };
