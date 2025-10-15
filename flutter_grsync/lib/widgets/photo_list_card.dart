import 'package:flutter/material.dart';
import '../models/photo.dart';
import '../models/sync_settings.dart';

class PhotoListCard extends StatelessWidget {
  final List<Photo> photos;
  final SyncSettings settings;

  const PhotoListCard({
    super.key,
    required this.photos,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final filteredPhotos = _getFilteredPhotos();
    final downloadedCount = filteredPhotos.where((p) => p.isDownloaded).length;
    final remainingCount = filteredPhotos.length - downloadedCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library),
                const SizedBox(width: 8),
                Text(
                  'Photo List',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'Total',
                    filteredPhotos.length.toString(),
                    Colors.blue,
                  ),
                  _buildSummaryItem(
                    'Downloaded',
                    downloadedCount.toString(),
                    Colors.green,
                  ),
                  _buildSummaryItem(
                    'Remaining',
                    remainingCount.toString(),
                    Colors.orange,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Filter summary
            if (settings.jpegOnly || settings.rawOnly || settings.lastNPhotos != null) ...[
              Text(
                'Active Filters:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (settings.jpegOnly)
                    Chip(
                      label: const Text('JPEG Only'),
                      backgroundColor: Colors.blue.shade100,
                    ),
                  if (settings.rawOnly)
                    Chip(
                      label: const Text('RAW Only'),
                      backgroundColor: Colors.purple.shade100,
                    ),
                  if (settings.lastNPhotos != null)
                    Chip(
                      label: Text('Last ${settings.lastNPhotos} photos'),
                      backgroundColor: Colors.green.shade100,
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Photo list
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: filteredPhotos.isEmpty
                  ? const Center(
                      child: Text('No photos found'),
                    )
                  : ListView.builder(
                      itemCount: filteredPhotos.length,
                      itemBuilder: (context, index) {
                        final photo = filteredPhotos[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: photo.isDownloaded 
                                ? Colors.green 
                                : Colors.grey.shade300,
                            child: Icon(
                              photo.isDownloaded 
                                  ? Icons.check 
                                  : _getFileTypeIcon(photo),
                              color: photo.isDownloaded 
                                  ? Colors.white 
                                  : Colors.grey.shade600,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            photo.filename,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              decoration: photo.isDownloaded 
                                  ? TextDecoration.lineThrough 
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            photo.directory,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          trailing: photo.isDownloaded
                              ? Icon(
                                  Icons.download_done,
                                  color: Colors.green.shade600,
                                )
                              : Icon(
                                  Icons.download,
                                  color: Colors.grey.shade400,
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Photo> _getFilteredPhotos() {
    List<Photo> filtered = List.from(photos);
    
    // Apply file type filter
    if (settings.jpegOnly) {
      filtered = filtered.where((photo) => photo.isJpeg).toList();
    } else if (settings.rawOnly) {
      filtered = filtered.where((photo) => photo.isRaw).toList();
    }
    
    // Apply last N photos filter
    if (settings.lastNPhotos != null && settings.lastNPhotos! > 0) {
      final limit = settings.lastNPhotos!;
      if (filtered.length > limit) {
        filtered = filtered.sublist(filtered.length - limit);
      }
    }
    
    return filtered;
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  IconData _getFileTypeIcon(Photo photo) {
    if (photo.isJpeg) {
      return Icons.image;
    } else if (photo.isRaw) {
      return Icons.photo_camera;
    } else {
      return Icons.insert_drive_file;
    }
  }
}