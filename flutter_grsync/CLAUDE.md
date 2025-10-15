# CLAUDE.md - Flutter GR Sync Development Guide

## Project Overview
Flutter GR Sync is a mobile application for syncing photos from Ricoh GR cameras (GR II, GR III, GR IIIx) via WiFi. It's a complete Flutter rewrite of the original GRSync Python script, providing a modern mobile interface with enhanced user experience while maintaining full functionality compatibility.

## Quick Start
```bash
# Environment: Flutter 3.10+ with Dart 3.0+
# Working Dir: /Users/simontran/code/portal/GRsync/flutter_grsync/
# Reference: ../GRsync.py (original Python implementation)

# Flutter commands
flutter pub get
flutter run
flutter build apk
flutter build ios

# Development tools
flutter analyze
flutter test
flutter doctor

# Code generation (for JSON serialization)
flutter packages pub run build_runner build
```

## Architecture Overview

### Technology Stack
- **Flutter 3.10+** with Dart 3.0+
- **Material Design 3** for modern UI
- **Provider** for state management
- **HTTP** for camera API communication
- **Path Provider** for file system access
- **JSON Serialization** for data models
- **Permission Handler** for storage permissions

### Core System Features

#### 1. Camera Connection System
Automatic device detection and connection management:
```dart
// Connect to camera at fixed IP
static const String _grHost = 'http://192.168.0.1/';

// Device validation
bool get isSupported => [
  'RICOH GR II',
  'RICOH GR III', 
  'RICOH GR IIIx'
].contains(model);

bool get batteryLevelOk => battery >= 15;
```

#### 2. State Management Pattern
Centralized state management using Provider pattern:
```dart
class GRSyncService extends ChangeNotifier {
  // State variables
  DeviceInfo? _deviceInfo;
  List<Photo> _photos = [];
  SyncStatus _status = SyncStatus.idle;
  
  // Notify UI of changes
  void _setStatus(SyncStatus status, String message) {
    _status = status;
    _statusMessage = message;
    notifyListeners(); // Triggers UI rebuild
  }
}
```

#### 3. Photo Download Pipeline
Multi-step download process with progress tracking:
```dart
Future<void> syncPhotos(SyncSettings settings) async {
  // 1. Fetch photo list from camera
  await fetchPhotoList();
  
  // 2. Filter photos based on user settings
  List<Photo> photosToDownload = _filterPhotosForDownload(settings);
  
  // 3. Download with progress updates
  for (int i = 0; i < photosToDownload.length; i++) {
    await _downloadPhoto(photo, baseDir.path);
    _progress = (i + 1) / _totalCount;
    notifyListeners();
  }
  
  // 4. Shutdown camera connection
  await _shutdownDevice();
}
```

## Critical Model Relationships

### Photo Model
- Fields: `directory`, `filename`, `isDownloaded`, `fileSize`, `dateCreated`
- Computed: `fullPath`, `isJpeg`, `isRaw`
- Serialization: JSON with `@JsonSerializable()`

### DeviceInfo Model
- Fields: `model`, `battery`, `errCode`, `errMsg`
- Validation: `isSupported`, `batteryLevelOk`, `hasError`
- Maps directly to camera's `/v1/props` API response

### SyncSettings Model
- Configuration: `downloadAll`, `jpegOnly`, `rawOnly`, `lastNPhotos`
- Start point: `startDirectory`, `startFile`
- Storage: `destinationPath`
- Immutable with `copyWith()` pattern

## API Communication

### Camera Endpoints
The app communicates with camera's built-in HTTP server:

```dart
// Device information and battery status
GET http://192.168.0.1/v1/props
Response: { "model": "RICOH GR III", "battery": 85, "errCode": 200 }

// Photo list with directory structure
GET http://192.168.0.1/v1/photos
Response: {
  "errCode": 200,
  "dirs": [
    {
      "name": "100RICOH",
      "files": ["R0000001.JPG", "R0000001.DNG", ...]
    }
  ]
}

// Download individual photo
GET http://192.168.0.1/v1/photos/100RICOH/R0000001.JPG
Response: Binary photo data

// Shutdown camera after sync
POST http://192.168.0.1/v1/device/finish
Body: {}
```

### Error Handling Pattern
Consistent error handling across all API calls:
```dart
try {
  final response = await http.get(uri).timeout(Duration(seconds: 5));
  
  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode}');
  }
  
  final data = jsonDecode(response.body);
  if (data['errCode'] != 200) {
    throw Exception('API Error: ${data['errMsg']}');
  }
  
  return processResponse(data);
} catch (e) {
  _setError(e.toString());
  return null;
}
```

## UI Architecture

### Widget Hierarchy
```
MaterialApp
└── ChangeNotifierProvider<GRSyncService>
    └── HomeScreen
        ├── DeviceStatusCard        # Connection status
        ├── SyncOptionsCard         # Download configuration
        ├── ProgressCard            # Download progress
        └── PhotoListCard           # Photo list display
```

### Responsive Design Pattern
Cards-based layout that works on phones and tablets:
```dart
SingleChildScrollView(
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      DeviceStatusCard(...),
      SizedBox(height: 16),
      if (service.isConnected) ...[
        SyncOptionsCard(...),
        // Conditional rendering based on state
      ],
    ],
  ),
)
```

### State-Driven UI Updates
UI automatically updates when service state changes:
```dart
Consumer<GRSyncService>(
  builder: (context, service, child) {
    return Column(
      children: [
        if (service.status == SyncStatus.downloading)
          ProgressCard(
            progress: service.progress,
            message: service.statusMessage,
          ),
        if (service.error != null)
          ErrorCard(error: service.error),
      ],
    );
  },
)
```

## File System Management

### Storage Structure
Photos are organized matching camera directory structure:
```
Documents/GRSync/
├── 100RICOH/
│   ├── R0000001.JPG    # JPEG files
│   ├── R0000001.DNG    # RAW files
│   └── ...
├── 101RICOH/
│   └── ...
```

### Duplicate Detection
Efficient local file scanning to avoid re-downloads:
```dart
Future<void> _checkLocalFiles() async {
  final directory = await getApplicationDocumentsDirectory();
  final grSyncDir = Directory('${directory.path}/GRSync');
  
  _localFiles = await _scanLocalFiles(grSyncDir.path);
  
  // Update photo download status
  _photos = _photos.map((photo) {
    final isDownloaded = _localFiles.contains(photo.fullPath);
    return photo.copyWith(isDownloaded: isDownloaded);
  }).toList();
}
```

### Platform-Specific Paths
```dart
// Android: /storage/emulated/0/Android/data/.../files/Documents/GRSync/
// iOS: ~/Documents/GRSync/
final directory = await getApplicationDocumentsDirectory();
final baseDir = Directory('${directory.path}/GRSync');
```

## Common Patterns and Solutions

### 1. Async State Updates
**Pattern**: Update UI immediately, then perform async operations
```dart
void startSync() {
  _setStatus(SyncStatus.downloading, 'Starting download...');
  _performAsyncDownload().then((result) {
    _setStatus(SyncStatus.completed, 'Download completed');
  }).catchError((error) {
    _setError(error.toString());
  });
}
```

### 2. Photo Filtering Logic
**Pattern**: Chain filters for flexible photo selection
```dart
List<Photo> _filterPhotosForDownload(SyncSettings settings) {
  List<Photo> filtered = List.from(_photos);
  
  // File type filter
  if (settings.jpegOnly) {
    filtered = filtered.where((photo) => photo.isJpeg).toList();
  }
  
  // Quantity limit
  if (settings.lastNPhotos != null) {
    filtered = filtered.sublist(filtered.length - settings.lastNPhotos!);
  }
  
  // Remove already downloaded
  filtered = filtered.where((photo) => !photo.isDownloaded).toList();
  
  return filtered;
}
```

### 3. Progress Tracking
**Pattern**: Update progress during long operations
```dart
for (int i = 0; i < photos.length; i++) {
  _setStatus(SyncStatus.downloading, 'Photo ${i + 1}/${photos.length}');
  
  await downloadPhoto(photos[i]);
  
  _progress = (i + 1) / photos.length;
  _downloadedCount++;
  notifyListeners(); // Trigger UI update
}
```

### 4. Network Timeout Handling
**Pattern**: All network requests use consistent timeouts
```dart
final response = await http.get(uri).timeout(
  const Duration(seconds: 5),
  onTimeout: () => throw TimeoutException('Camera not responding'),
);
```

## Development Workflow

### Code Generation
Run after modifying models with `@JsonSerializable`:
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Testing Strategy
```bash
# Unit tests for service logic
flutter test test/services/gr_sync_service_test.dart

# Widget tests for UI components
flutter test test/widgets/device_status_card_test.dart

# Integration tests
flutter drive --target=test_driver/app.dart
```

### Debugging Tools
```dart
// Enable HTTP logging
import 'package:http/http.dart' as http;
debugPrint('API Request: ${response.request}');
debugPrint('API Response: ${response.body}');

// State debugging
void debugPrintState() {
  debugPrint('Photos: ${_photos.length}');
  debugPrint('Status: $_status');
  debugPrint('Progress: $_progress');
}
```

## Build and Deployment

### Android Build
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS Build
```bash
flutter build ios --release
```

### Required Permissions
Ensure these permissions are configured:
- **Internet**: Camera communication
- **WiFi State**: Network status
- **Storage**: Photo downloads

## Performance Considerations

### Memory Management
- Use `Stream` for large photo lists
- Implement photo thumbnail caching
- Clear completed downloads from memory

### Network Optimization
- Implement retry logic for failed downloads
- Use chunked downloads for large RAW files
- Cache photo metadata to reduce API calls

### Battery Efficiency
- Stop background operations when app not visible
- Use WiFi-only downloads
- Implement download pause/resume

## Error Recovery

### Common Issues and Solutions

#### 1. Camera Not Reachable
```dart
// Check WiFi connection
if (!await connectivity.checkConnectivity() == ConnectivityResult.wifi) {
  throw Exception('Please connect to camera WiFi network');
}

// Verify camera IP
final ping = await InternetAddress.lookup('192.168.0.1');
if (ping.isEmpty) {
  throw Exception('Camera not found on network');
}
```

#### 2. Low Battery Warning
```dart
if (deviceInfo.battery < 15) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Low Battery'),
      content: Text('Camera battery is ${deviceInfo.battery}%. Please charge before syncing.'),
    ),
  );
}
```

#### 3. Storage Space Check
```dart
final availableSpace = await DiskSpace.getFreeDiskSpace();
final requiredSpace = photos.fold<int>(0, (sum, photo) => sum + (photo.fileSize ?? 0));

if (availableSpace < requiredSpace) {
  throw Exception('Insufficient storage space');
}
```

## Migration from Python Script

### Feature Parity Matrix
| Python GRSync | Flutter GR Sync | Status |
|---------------|-----------------|--------|
| Device detection | ✅ DeviceInfo model | Complete |
| Battery check | ✅ batteryLevelOk | Complete |
| Photo listing | ✅ fetchPhotoList() | Complete |
| Duplicate skip | ✅ isDownloaded flag | Complete |
| JPEG/RAW filter | ✅ jpegOnly/rawOnly | Complete |
| Last N photos | ✅ lastNPhotos | Complete |
| Progress display | ✅ ProgressCard UI | Enhanced |
| Directory creation | ✅ Auto-create dirs | Complete |
| Camera shutdown | ✅ _shutdownDevice() | Complete |

### Enhanced Features in Flutter
- **Visual Progress**: Real-time progress bars and status
- **Photo Preview**: Thumbnail display in photo list
- **Settings Persistence**: Remember user preferences
- **Offline Mode**: View downloaded photos without camera
- **Batch Operations**: Select multiple photos for action

## Stack & Versions
- Flutter 3.10+, Dart 3.0+
- Provider 6.1+ for state management
- HTTP 1.1+ for network requests
- Path Provider 2.1+ for file system
- JSON Annotation 4.8+ for serialization
- Permission Handler 11.0+ for permissions

## Key Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0              # Camera API communication
  provider: ^6.1.1          # State management
  path_provider: ^2.1.1     # File system access
  json_annotation: ^4.8.1   # Model serialization
  permission_handler: ^11.0.1  # Storage permissions

dev_dependencies:
  json_serializable: ^6.7.1  # Code generation
  build_runner: ^2.4.7       # Build tools
  flutter_lints: ^3.0.0      # Code analysis
```

## Recent Development Status

### ✅ Core Functionality Implemented
- **Camera Communication**: HTTP client with proper error handling
- **Photo Management**: Full CRUD operations with local caching
- **UI Components**: Modern Material Design 3 interface
- **State Management**: Reactive updates using Provider pattern
- **File Operations**: Cross-platform storage with proper permissions

### ✅ Enhanced Features Over Python Script
- **Mobile-First Design**: Touch-friendly interface optimized for phones/tablets
- **Real-Time Updates**: Live progress tracking and status updates
- **Visual Feedback**: Icons, colors, and animations for better UX
- **Error Recovery**: Graceful handling of network and storage issues
- **Settings Persistence**: Remember user preferences between sessions

### 🔄 Future Enhancements
- **Photo Thumbnails**: Generate and cache image previews
- **Batch Selection**: Multi-select photos for targeted downloads
- **Background Sync**: Continue downloads when app backgrounded
- **Cloud Backup**: Optional backup to cloud storage services
- **Camera Settings**: Remote camera configuration capabilities

## Debugging and Troubleshooting

### Debug Mode Features
```dart
// Enable verbose logging
const bool kDebugMode = true;

if (kDebugMode) {
  debugPrint('Camera connection attempt: $_grHost');
  debugPrint('Photos found: ${_photos.length}');
  debugPrint('Download progress: ${(_progress * 100).toInt()}%');
}
```

### Common Debug Commands
```bash
# Check device connection
flutter logs

# Analyze code issues
flutter analyze

# Test on specific device
flutter run -d <device-id>

# Build debug APK
flutter build apk --debug
```

### Performance Profiling
```bash
# Memory usage
flutter run --profile --trace-startup

# Widget inspector
flutter inspector

# Network monitoring
# Use Charles Proxy or similar to monitor HTTP traffic to 192.168.0.1
```

---

*Reference original GRsync.py for compatibility requirements*  
*Test thoroughly with actual Ricoh GR cameras before deployment*  
*Last Updated: August 2025 - Complete Flutter implementation with enhanced mobile UX*

## Critical Implementation Notes

### Camera Network Requirements
- **Fixed IP**: Camera always uses 192.168.0.1 (hardcoded)
- **WiFi Only**: No cellular data, must connect to camera's hotspot
- **Timeout Handling**: 2-5 second timeouts for all HTTP requests
- **Battery Check**: Enforce 15% minimum battery level

### File Handling Patterns
- **Directory Structure**: Mirror camera's folder organization
- **Duplicate Detection**: Compare full file paths, not just names
- **Atomic Downloads**: Complete file before marking as downloaded
- **Error Recovery**: Resume interrupted downloads on app restart

### UI/UX Best Practices
- **State Feedback**: Always show current operation status
- **Progress Tracking**: Granular progress for long operations
- **Error Messages**: User-friendly error descriptions
- **Responsive Design**: Adapt to different screen sizes

### Security Considerations
- **Local Network Only**: No external API calls
- **File Permissions**: Request minimal necessary permissions
- **Data Privacy**: Photos stored locally, no cloud transmission
- **Network Validation**: Verify camera identity before operations

This documentation provides comprehensive guidance for developing, maintaining, and extending the Flutter GR Sync application while maintaining compatibility with the original Python implementation.