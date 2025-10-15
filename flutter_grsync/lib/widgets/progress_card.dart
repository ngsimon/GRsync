import 'package:flutter/material.dart';
import '../services/gr_sync_service.dart';

class ProgressCard extends StatelessWidget {
  final SyncStatus status;
  final String message;
  final double progress;
  final int downloadedCount;
  final int totalCount;

  const ProgressCard({
    super.key,
    required this.status,
    required this.message,
    required this.progress,
    required this.downloadedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 8),
                Text(
                  _getStatusTitle(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 16),
            
            if (status == SyncStatus.downloading) ...[
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$downloadedCount / $totalCount photos'),
                  Text('${(progress * 100).toInt()}%'),
                ],
              ),
            ] else if (status == SyncStatus.fetchingPhotos || status == SyncStatus.connecting) ...[
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case SyncStatus.connecting:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStatus.fetchingPhotos:
        return const Icon(Icons.list, color: Colors.blue);
      case SyncStatus.downloading:
        return const Icon(Icons.download, color: Colors.green);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }

  String _getStatusTitle() {
    switch (status) {
      case SyncStatus.connecting:
        return 'Connecting';
      case SyncStatus.fetchingPhotos:
        return 'Fetching Photos';
      case SyncStatus.downloading:
        return 'Downloading';
      case SyncStatus.completed:
        return 'Completed';
      default:
        return 'Status';
    }
  }
}