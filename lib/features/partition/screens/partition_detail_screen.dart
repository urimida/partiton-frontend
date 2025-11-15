import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:partition_app/core/router/app_router.dart';
import 'package:partition_app/features/partition/providers/partition_provider.dart';

class PartitionDetailScreen extends StatefulWidget {
  final String partitionId;

  const PartitionDetailScreen({
    super.key,
    required this.partitionId,
  });

  @override
  State<PartitionDetailScreen> createState() => _PartitionDetailScreenState();
}

class _PartitionDetailScreenState extends State<PartitionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartitionProvider>().loadPartitionById(widget.partitionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('파티션 상세'),
      ),
      body: Consumer<PartitionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedPartition == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadPartitionById(widget.partitionId),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final partition = provider.selectedPartition;
          if (partition == null) {
            return const Center(
              child: Text('파티션을 찾을 수 없습니다.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partition.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (partition.description != null) ...[
                          const SizedBox(height: 8),
                          Text(partition.description!),
                        ],
                        const Divider(),
                        _DetailRow(
                          label: '타입',
                          value: partition.type,
                        ),
                        _DetailRow(
                          label: '상태',
                          value: partition.status,
                        ),
                        if (partition.size != null) ...[
                          _DetailRow(
                            label: '전체 크기',
                            value: partition.formattedSize,
                          ),
                          _DetailRow(
                            label: '사용된 크기',
                            value: partition.formattedUsedSize,
                          ),
                          _DetailRow(
                            label: '사용률',
                            value: '${partition.usagePercentage.toStringAsFixed(2)}%',
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: partition.usagePercentage / 100,
                            backgroundColor: Colors.grey[300],
                          ),
                        ],
                        _DetailRow(
                          label: '생성일',
                          value: partition.createdAt.toString().split('.').first,
                        ),
                        if (partition.updatedAt != null)
                          _DetailRow(
                            label: '수정일',
                            value: partition.updatedAt!.toString().split('.').first,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: 수정 기능 구현
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('수정 기능은 추후 구현 예정입니다.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('수정'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('삭제 확인'),
                            content: const Text('정말 이 파티션을 삭제하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && mounted) {
                          final success = await provider.deletePartition(partition.id);
                          if (success && mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('파티션이 삭제되었습니다.'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('삭제'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

