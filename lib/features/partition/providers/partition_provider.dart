import 'package:flutter/foundation.dart';
import 'package:partition_app/features/partition/models/partition_model.dart';
import 'package:partition_app/features/partition/services/partition_service.dart';
import 'package:partition_app/core/network/api_exception.dart';

class PartitionProvider extends ChangeNotifier {
  final PartitionService _partitionService = PartitionService();

  List<PartitionModel> _partitions = [];
  PartitionModel? _selectedPartition;
  bool _isLoading = false;
  String? _errorMessage;

  List<PartitionModel> get partitions => _partitions;
  PartitionModel? get selectedPartition => _selectedPartition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPartitions() async {
    _setLoading(true);
    _clearError();

    try {
      _partitions = await _partitionService.getPartitions();
      _setLoading(false);
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _setError('파티션 목록을 불러오는 중 오류가 발생했습니다.');
      _setLoading(false);
    }
  }

  Future<void> loadPartitionById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      _selectedPartition = await _partitionService.getPartitionById(id);
      _setLoading(false);
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
    } catch (e) {
      _setError('파티션 정보를 불러오는 중 오류가 발생했습니다.');
      _setLoading(false);
    }
  }

  Future<bool> createPartition({
    required String name,
    String? description,
    required String type,
    int? size,
    String? status,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final newPartition = await _partitionService.createPartition(
        name: name,
        description: description,
        type: type,
        size: size,
        status: status,
      );
      _partitions.add(newPartition);
      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('파티션 생성 중 오류가 발생했습니다.');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updatePartition(
    String id, {
    String? name,
    String? description,
    String? type,
    int? size,
    int? usedSize,
    String? status,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedPartition = await _partitionService.updatePartition(
        id,
        name: name,
        description: description,
        type: type,
        size: size,
        usedSize: usedSize,
        status: status,
      );

      final index = _partitions.indexWhere((p) => p.id == id);
      if (index != -1) {
        _partitions[index] = updatedPartition;
      }

      if (_selectedPartition?.id == id) {
        _selectedPartition = updatedPartition;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('파티션 수정 중 오류가 발생했습니다.');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deletePartition(String id) async {
    _setLoading(true);
    _clearError();

    try {
      await _partitionService.deletePartition(id);
      _partitions.removeWhere((p) => p.id == id);

      if (_selectedPartition?.id == id) {
        _selectedPartition = null;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('파티션 삭제 중 오류가 발생했습니다.');
      _setLoading(false);
      return false;
    }
  }

  void selectPartition(PartitionModel? partition) {
    _selectedPartition = partition;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}

