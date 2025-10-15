import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/photo.dart';
import '../models/device_info.dart';
import '../models/sync_settings.dart';

enum SyncStatus {
  idle,
  connecting,
  fetchingPhotos,
  downloading,
  completed,
  error,
}

class GRSyncService extends ChangeNotifier {
  static const String _grHost = 'http://192.168.0.1/';
  static const String _photoListUri = 'v1/photos';
  static const String _grPropsUri = 'v1/props';
  static const String _shutdownUri = 'v1/device/finish';
  
  DeviceInfo? _deviceInfo;
  List<Photo> _photos = [];
  List<String> _localFiles = [];
  SyncStatus _status = SyncStatus.idle;
  String _statusMessage = '';
  double _progress = 0.0;
  int _downloadedCount = 0;
  int _totalCount = 0;
  String? _error;
  
  // Getters
  DeviceInfo? get deviceInfo => _deviceInfo;
  List<Photo> get photos => _photos;
  SyncStatus get status => _status;
  String get statusMessage => _statusMessage;
  double get progress => _progress;
  int get downloadedCount => _downloadedCount;
  int get totalCount => _totalCount;
  String? get error => _error;
  bool get isConnected => _deviceInfo != null;

  Future<bool> connectToDevice() async {
    _setStatus(SyncStatus.connecting, 'Connecting to Ricoh GR...');
    _error = null;
    
    try {
      final deviceInfo = await _getDeviceInfo();
      if (deviceInfo.hasError) {
        throw Exception('Device error: ${deviceInfo.errMsg}');
      }
      
      if (!deviceInfo.isSupported) {
        throw Exception('Device ${deviceInfo.model} is not supported');
      }
      
      if (!deviceInfo.batteryLevelOk) {
        throw Exception('Battery level (${deviceInfo.battery}%) is too low. Please charge above 15%');
      }
      
      _deviceInfo = deviceInfo;
      _setStatus(SyncStatus.idle, 'Connected to ${deviceInfo.model}');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<DeviceInfo> _getDeviceInfo() async {
    final response = await http.get(
      Uri.parse('$_grHost$_grPropsUri'),
    ).timeout(const Duration(seconds: 5));
    
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch device info: ${response.statusCode}');
    }
    
    final data = jsonDecode(response.body);
    return DeviceInfo.fromJson(data);
  }

  Future<void> fetchPhotoList() async {
    if (_deviceInfo == null) {
      throw Exception('Device not connected');
    }
    
    _setStatus(SyncStatus.fetchingPhotos, 'Fetching photo list...');
    
    try {
      final response = await http.get(
        Uri.parse('$_grHost$_photoListUri'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch photo list: ${response.statusCode}');
      }
      
      final data = jsonDecode(response.body);
      if (data['errCode'] != 200) {
        throw Exception('API Error: ${data['errMsg']}');
      }
      
      final List<Photo> photoList = [];
      for (final dir in data['dirs']) {
        final String dirName = dir['name'];
        for (final fileName in dir['files']) {
          photoList.add(Photo(
            directory: dirName,
            filename: fileName,
          ));
        }
      }
      
      _photos = photoList;
      await _checkLocalFiles();
      _setStatus(SyncStatus.idle, 'Found ${_photos.length} photos on device');
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _checkLocalFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final grSyncDir = Directory('${directory.path}/GRSync');
      
      if (!await grSyncDir.exists()) {
        await grSyncDir.create(recursive: true);
      }
      
      _localFiles = await _scanLocalFiles(grSyncDir.path);
      
      // Update photos with download status
      _photos = _photos.map((photo) {
        final isDownloaded = _localFiles.contains(photo.fullPath);
        return photo.copyWith(isDownloaded: isDownloaded);
      }).toList();
      
    } catch (e) {
      debugPrint('Error checking local files: $e');
    }
  }

  Future<List<String>> _scanLocalFiles(String basePath) async {
    final List<String> files = [];
    final directory = Directory(basePath);
    
    if (await directory.exists()) {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final relativePath = entity.path.substring(basePath.length + 1);
          files.add(relativePath.replaceAll('\\', '/'));
        }
      }
    }
    
    return files;
  }

  Future<void> syncPhotos(SyncSettings settings) async {
    if (_photos.isEmpty) {
      await fetchPhotoList();
    }
    
    _setStatus(SyncStatus.downloading, 'Preparing download...');
    
    try {
      List<Photo> photosToDownload = _filterPhotosForDownload(settings);
      
      _totalCount = photosToDownload.length;
      _downloadedCount = 0;
      _progress = 0.0;
      
      if (photosToDownload.isEmpty) {
        _setStatus(SyncStatus.completed, 'No new photos to download');
        return;
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final baseDir = Directory('${directory.path}/GRSync');
      
      for (int i = 0; i < photosToDownload.length; i++) {
        final photo = photosToDownload[i];
        
        _setStatus(
          SyncStatus.downloading,
          'Downloading ${photo.filename} (${i + 1}/${_totalCount})',
        );
        
        final success = await _downloadPhoto(photo, baseDir.path);
        
        if (success) {
          _downloadedCount++;
        }
        
        _progress = (i + 1) / _totalCount;
        notifyListeners();
      }
      
      await _shutdownDevice();
      _setStatus(SyncStatus.completed, 'Downloaded $_downloadedCount/$_totalCount photos');
      
    } catch (e) {
      _setError(e.toString());
    }
  }

  List<Photo> _filterPhotosForDownload(SyncSettings settings) {
    List<Photo> filtered = List.from(_photos);
    
    // Filter by file type
    if (settings.jpegOnly) {
      filtered = filtered.where((photo) => photo.isJpeg).toList();
    } else if (settings.rawOnly) {
      filtered = filtered.where((photo) => photo.isRaw).toList();
    }
    
    // Filter by start point
    if (settings.hasStartPoint) {
      final startPath = '${settings.startDirectory}/${settings.startFile}';
      final startIndex = filtered.indexWhere((photo) => photo.fullPath == startPath);
      if (startIndex >= 0) {
        filtered = filtered.sublist(startIndex);
      }
    }
    
    // Limit by last N photos
    if (settings.lastNPhotos != null && settings.lastNPhotos! > 0) {
      final limit = settings.lastNPhotos!;
      if (filtered.length > limit) {
        filtered = filtered.sublist(filtered.length - limit);
      }
    }
    
    // Remove already downloaded photos
    filtered = filtered.where((photo) => !photo.isDownloaded).toList();
    
    return filtered;
  }

  Future<bool> _downloadPhoto(Photo photo, String basePath) async {
    try {
      final photoUri = _deviceInfo!.model.contains('GR2')
          ? photo.fullPath
          : '$_photoListUri/${photo.fullPath}';
          
      final response = await http.get(
        Uri.parse('$_grHost$photoUri'),
      ).timeout(const Duration(minutes: 2));
      
      if (response.statusCode != 200) {
        return false;
      }
      
      // Ensure directory exists
      final photoDir = Directory('$basePath/${photo.directory}');
      if (!await photoDir.exists()) {
        await photoDir.create(recursive: true);
      }
      
      // Write file
      final file = File('$basePath/${photo.fullPath}');
      await file.writeAsBytes(response.bodyBytes);
      
      return true;
    } catch (e) {
      debugPrint('Failed to download ${photo.fullPath}: $e');
      return false;
    }
  }

  Future<void> _shutdownDevice() async {
    try {
      await http.post(
        Uri.parse('$_grHost$_shutdownUri'),
        headers: {'Content-Type': 'application/json'},
        body: '{}',
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Failed to shutdown device: $e');
    }
  }

  void _setStatus(SyncStatus status, String message) {
    _status = status;
    _statusMessage = message;
    _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _status = SyncStatus.error;
    _error = error;
    _statusMessage = 'Error: $error';
    notifyListeners();
  }

  void reset() {
    _deviceInfo = null;
    _photos.clear();
    _localFiles.clear();
    _status = SyncStatus.idle;
    _statusMessage = '';
    _progress = 0.0;
    _downloadedCount = 0;
    _totalCount = 0;
    _error = null;
    notifyListeners();
  }
}