import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../services/gr_sync_service.dart';
import '../models/sync_settings.dart';
import '../widgets/device_status_card.dart';
import '../widgets/sync_options_card.dart';
import '../widgets/photo_list_card.dart';
import '../widgets/progress_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SyncSettings _syncSettings = const SyncSettings(destinationPath: '');

  @override
  void initState() {
    super.initState();
    _initializeDestinationPath();
  }

  Future<void> _initializeDestinationPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final defaultPath = '${directory.path}/GRSync';
    
    setState(() {
      _syncSettings = _syncSettings.copyWith(destinationPath: defaultPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GR Sync'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GRSyncService>().reset();
            },
            tooltip: 'Reset Connection',
          ),
        ],
      ),
      body: Consumer<GRSyncService>(
        builder: (context, service, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DeviceStatusCard(
                  deviceInfo: service.deviceInfo,
                  isConnected: service.isConnected,
                  onConnect: () => service.connectToDevice(),
                ),
                
                const SizedBox(height: 16),
                
                if (service.isConnected) ...[
                  SyncOptionsCard(
                    settings: _syncSettings,
                    onSettingsChanged: (settings) {
                      setState(() {
                        _syncSettings = settings;
                      });
                    },
                    onFetchPhotos: () => service.fetchPhotoList(),
                    onStartSync: () => service.syncPhotos(_syncSettings),
                    isEnabled: service.status == SyncStatus.idle,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (service.status == SyncStatus.downloading || 
                      service.status == SyncStatus.fetchingPhotos ||
                      service.status == SyncStatus.connecting) ...[
                    ProgressCard(
                      status: service.status,
                      message: service.statusMessage,
                      progress: service.progress,
                      downloadedCount: service.downloadedCount,
                      totalCount: service.totalCount,
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  if (service.error != null) ...[
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Error',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              service.error!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  if (service.photos.isNotEmpty) ...[
                    PhotoListCard(
                      photos: service.photos,
                      settings: _syncSettings,
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}