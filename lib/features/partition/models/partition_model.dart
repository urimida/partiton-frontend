import 'package:json_annotation/json_annotation.dart';

part 'partition_model.g.dart';

@JsonSerializable()
class PartitionModel {
  final String id;
  final String name;
  final String? description;
  final String type; // 예: 'disk', 'storage', 'category' 등
  final int? size; // 크기 (바이트 단위)
  final int? usedSize; // 사용된 크기
  final String status; // 예: 'active', 'inactive', 'pending'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userId;

  PartitionModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.size,
    this.usedSize,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.userId,
  });

  factory PartitionModel.fromJson(Map<String, dynamic> json) =>
      _$PartitionModelFromJson(json);

  Map<String, dynamic> toJson() => _$PartitionModelToJson(this);

  double get usagePercentage {
    if (size == null || size == 0) return 0.0;
    if (usedSize == null) return 0.0;
    return (usedSize! / size!) * 100;
  }

  String get formattedSize {
    if (size == null) return 'N/A';
    return _formatBytes(size!);
  }

  String get formattedUsedSize {
    if (usedSize == null) return 'N/A';
    return _formatBytes(usedSize!);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

