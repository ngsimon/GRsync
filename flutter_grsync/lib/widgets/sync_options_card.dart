import 'package:flutter/material.dart';
import '../models/sync_settings.dart';

class SyncOptionsCard extends StatefulWidget {
  final SyncSettings settings;
  final Function(SyncSettings) onSettingsChanged;
  final VoidCallback onFetchPhotos;
  final VoidCallback onStartSync;
  final bool isEnabled;

  const SyncOptionsCard({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onFetchPhotos,
    required this.onStartSync,
    required this.isEnabled,
  });

  @override
  State<SyncOptionsCard> createState() => _SyncOptionsCardState();
}

class _SyncOptionsCardState extends State<SyncOptionsCard> {
  final TextEditingController _lastNPhotosController = TextEditingController();
  final TextEditingController _startDirController = TextEditingController();
  final TextEditingController _startFileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  @override
  void didUpdateWidget(SyncOptionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    _lastNPhotosController.text = widget.settings.lastNPhotos?.toString() ?? '';
    _startDirController.text = widget.settings.startDirectory ?? '';
    _startFileController.text = widget.settings.startFile ?? '';
  }

  void _updateSettings(SyncSettings Function(SyncSettings) updater) {
    final newSettings = updater(widget.settings);
    widget.onSettingsChanged(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            
            const SizedBox(height: 16),
            
            // Download mode
            Text(
              'Download Mode',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            RadioListTile<bool>(
              title: const Text('Download all photos'),
              value: true,
              groupValue: widget.settings.downloadAll,
              onChanged: widget.isEnabled ? (value) {
                _updateSettings((s) => s.copyWith(downloadAll: value));
              } : null,
            ),
            
            RadioListTile<bool>(
              title: const Text('Download from specific point'),
              value: false,
              groupValue: widget.settings.downloadAll,
              onChanged: widget.isEnabled ? (value) {
                _updateSettings((s) => s.copyWith(downloadAll: value));
              } : null,
            ),
            
            if (!widget.settings.downloadAll) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startDirController,
                      enabled: widget.isEnabled,
                      decoration: const InputDecoration(
                        labelText: 'Start Directory',
                        hintText: '100RICOH',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(startDirectory: value.isEmpty ? null : value));
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _startFileController,
                      enabled: widget.isEnabled,
                      decoration: const InputDecoration(
                        labelText: 'Start File',
                        hintText: 'R0000005.JPG',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _updateSettings((s) => s.copyWith(startFile: value.isEmpty ? null : value));
                      },
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // File type filter
            Text(
              'File Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            CheckboxListTile(
              title: const Text('JPEG only'),
              value: widget.settings.jpegOnly,
              onChanged: widget.isEnabled ? (value) {
                _updateSettings((s) => s.copyWith(
                  jpegOnly: value ?? false,
                  rawOnly: false,
                ));
              } : null,
            ),
            
            CheckboxListTile(
              title: const Text('RAW only'),
              value: widget.settings.rawOnly,
              onChanged: widget.isEnabled ? (value) {
                _updateSettings((s) => s.copyWith(
                  rawOnly: value ?? false,
                  jpegOnly: false,
                ));
              } : null,
            ),
            
            const SizedBox(height: 16),
            
            // Last N photos
            TextField(
              controller: _lastNPhotosController,
              enabled: widget.isEnabled,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Download last N photos (optional)',
                hintText: 'Leave empty to download all',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final intValue = int.tryParse(value);
                _updateSettings((s) => s.copyWith(lastNPhotos: intValue));
              },
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isEnabled ? widget.onFetchPhotos : null,
                    icon: const Icon(Icons.list),
                    label: const Text('Fetch Photo List'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isEnabled ? widget.onStartSync : null,
                    icon: const Icon(Icons.download),
                    label: const Text('Start Sync'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _lastNPhotosController.dispose();
    _startDirController.dispose();
    _startFileController.dispose();
    super.dispose();
  }
}