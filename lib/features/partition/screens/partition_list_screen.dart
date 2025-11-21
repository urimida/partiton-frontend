import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:partition_app/core/router/app_router.dart';
import 'package:partition_app/features/partition/models/partition_model.dart';
import 'package:partition_app/features/partition/providers/partition_provider.dart';
import 'package:partition_app/features/auth/providers/auth_provider.dart';

class PartitionListScreen extends StatefulWidget {
  const PartitionListScreen({super.key});

  @override
  State<PartitionListScreen> createState() => _PartitionListScreenState();
}

class _PartitionListScreenState extends State<PartitionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PartitionProvider>().loadPartitions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('파티션 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.settings);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(AppRouter.login);
              }
            },
          ),
        ],
      ),
      body: Consumer<PartitionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.partitions.isEmpty) {
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
                    onPressed: () => provider.loadPartitions(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (provider.partitions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storage, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    '파티션이 없습니다',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreatePartitionDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('파티션 생성'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadPartitions(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.partitions.length,
              itemBuilder: (context, index) {
                final partition = provider.partitions[index];
                return _PartitionCard(partition: partition);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePartitionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreatePartitionDialog(BuildContext context) {
    // TODO: 파티션 생성 다이얼로그 구현
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파티션 생성'),
        content: const Text('파티션 생성 기능은 추후 구현 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

class _PartitionCard extends StatelessWidget {
  final PartitionModel partition;

  const _PartitionCard({required this.partition});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(partition.status),
          child: const Icon(Icons.storage, color: Colors.white),
        ),
        title: Text(partition.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (partition.description != null)
              Text(partition.description!),
            const SizedBox(height: 4),
            Text('타입: ${partition.type}'),
            if (partition.size != null)
              Text(
                '사용량: ${partition.formattedUsedSize} / ${partition.formattedSize}',
              ),
            LinearProgressIndicator(
              value: partition.usagePercentage / 100,
              backgroundColor: Colors.grey[300],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () {
            // TODO: 파티션 상세 화면은 더 이상 사용하지 않음
            // Navigator.of(context).pushNamed(
            //   AppRouter.partitionDetail,
            //   arguments: partition.id,
            // );
          },
        ),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppRouter.partitionDetail,
            arguments: partition.id,
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

