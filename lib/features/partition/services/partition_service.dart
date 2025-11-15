import 'package:partition_app/core/config/app_config.dart';
import 'package:partition_app/core/network/api_client.dart';
import 'package:partition_app/core/network/api_exception.dart';
import 'package:partition_app/features/partition/models/partition_model.dart';

class PartitionService {
  final ApiClient _apiClient = ApiClient();

  Future<List<PartitionModel>> getPartitions() async {
    try {
      final response = await _apiClient.get(AppConfig.partitionsEndpoint);
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data
          .map((json) => PartitionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PartitionModel> getPartitionById(String id) async {
    try {
      final endpoint = AppConfig.partitionDetailEndpoint.replaceAll('{id}', id);
      final response = await _apiClient.get(endpoint);
      return PartitionModel.fromJson(response.data);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PartitionModel> createPartition({
    required String name,
    String? description,
    required String type,
    int? size,
    String? status,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConfig.partitionsEndpoint,
        data: {
          'name': name,
          if (description != null) 'description': description,
          'type': type,
          if (size != null) 'size': size,
          if (status != null) 'status': status ?? 'active',
        },
      );
      return PartitionModel.fromJson(response.data);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PartitionModel> updatePartition(
    String id, {
    String? name,
    String? description,
    String? type,
    int? size,
    int? usedSize,
    String? status,
  }) async {
    try {
      final endpoint = AppConfig.partitionDetailEndpoint.replaceAll('{id}', id);
      final response = await _apiClient.put(
        endpoint,
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (type != null) 'type': type,
          if (size != null) 'size': size,
          if (usedSize != null) 'usedSize': usedSize,
          if (status != null) 'status': status,
        },
      );
      return PartitionModel.fromJson(response.data);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deletePartition(String id) async {
    try {
      final endpoint = AppConfig.partitionDetailEndpoint.replaceAll('{id}', id);
      await _apiClient.delete(endpoint);
    } catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

