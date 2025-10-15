# Flutter GR Sync

A Flutter mobile app for syncing photos from Ricoh GR cameras (GR II, GR III, GR IIIx) via WiFi, based on the original GRSync Python script.

## Features

- **Device Connection**: Automatically detects and connects to supported Ricoh GR cameras
- **Battery Monitoring**: Checks camera battery level before sync operations
- **Flexible Download Options**:
  - Download all photos or from a specific starting point
  - Filter by file type (JPEG only, RAW only)
  - Download last N photos
- **Smart Duplicate Detection**: Automatically skips already downloaded photos
- **Progress Tracking**: Real-time download progress with detailed status
- **Local Storage**: Photos are saved to the device's documents directory

## Supported Devices

- Ricoh GR II
- Ricoh GR III
- Ricoh GR IIIx

## Setup

1. **Connect to Camera WiFi**:
   - Turn on your Ricoh GR camera's WiFi
   - Connect your phone/tablet to the camera's network (SSID: RICOH_XXXXX)

2. **Install and Run**:
   ```bash
   flutter pub get
   flutter run
   ```

## Usage

1. **Connect**: Tap "Connect to Camera" to establish connection
2. **Configure Options**: Set your download preferences:
   - Download mode (all photos or from specific point)
   - File type filters (JPEG/RAW)
   - Number of photos to download
3. **Fetch Photos**: Tap "Fetch Photo List" to see available photos
4. **Start Sync**: Tap "Start Sync" to begin downloading

## App Architecture

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── photo.dart              # Photo data structure
│   ├── device_info.dart        # Camera device information
│   └── sync_settings.dart      # User sync preferences
├── services/                   # Business logic
│   └── gr_sync_service.dart    # Core sync functionality
├── screens/                    # UI screens
│   └── home_screen.dart        # Main app screen
└── widgets/                    # Reusable UI components
    ├── device_status_card.dart # Camera connection status
    ├── sync_options_card.dart  # Download options
    ├── progress_card.dart      # Download progress
    └── photo_list_card.dart    # Photo list display
```

## Key Components

### GRSyncService
- Manages camera connection and communication
- Handles photo list fetching and downloading
- Provides real-time status updates via ChangeNotifier

### Models
- **Photo**: Represents individual photos with metadata
- **DeviceInfo**: Camera information and battery status
- **SyncSettings**: User-configured download preferences

## API Endpoints

The app communicates with the camera using these HTTP endpoints:

- `GET /v1/props` - Device properties and battery level
- `GET /v1/photos` - Photo list and directory structure
- `GET /v1/photos/{path}` - Download individual photos
- `POST /v1/device/finish` - Shutdown camera after sync

## Storage

Photos are saved to:
- **Android**: `/storage/emulated/0/Android/data/com.example.flutter_grsync/files/Documents/GRSync/`
- **iOS**: `~/Documents/GRSync/`

Directory structure matches the camera:
```
GRSync/
├── 100RICOH/
│   ├── R0000001.JPG
│   ├── R0000001.DNG
│   └── ...
├── 101RICOH/
│   └── ...
```

## Error Handling

The app handles common issues:
- Camera not reachable (WiFi connection problems)
- Low battery warnings (< 15%)
- Unsupported device models
- Network timeouts during download
- File system errors

## Development

To extend or modify the app:

1. **Add new camera models**: Update `SUPPORT_DEVICE` list in `GRSyncService`
2. **Modify UI**: Edit widgets in `lib/widgets/`
3. **Add sync options**: Extend `SyncSettings` model
4. **Improve error handling**: Update exception handling in service methods

## Dependencies

- `http`: HTTP client for camera API calls
- `path_provider`: File system access
- `provider`: State management
- `json_annotation`: JSON serialization
- `permission_handler`: Storage permissions

## License

Based on the original GRSync Python script. See LICENSE for details.