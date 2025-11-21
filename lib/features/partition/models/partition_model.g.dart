// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partition_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PartitionModel _$PartitionModelFromJson(Map<String, dynamic> json) =>
    PartitionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      size: (json['size'] as num?)?.toInt(),
      usedSize: (json['usedSize'] as num?)?.toInt(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      userId: json['userId'] as String?,
    );

Map<String, dynamic> _$PartitionModelToJson(PartitionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': instance.type,
      'size': instance.size,
      'usedSize': instance.usedSize,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'userId': instance.userId,
    };
