class SyncSettings {
  final bool downloadAll;
  final bool jpegOnly;
  final bool rawOnly;
  final int? lastNPhotos;
  final String? startDirectory;
  final String? startFile;
  final String destinationPath;

  const SyncSettings({
    this.downloadAll = true,
    this.jpegOnly = false,
    this.rawOnly = false,
    this.lastNPhotos,
    this.startDirectory,
    this.startFile,
    required this.destinationPath,
  });

  bool get hasStartPoint => startDirectory != null && startFile != null;
  bool get hasFileTypeFilter => jpegOnly || rawOnly;

  SyncSettings copyWith({
    bool? downloadAll,
    bool? jpegOnly,
    bool? rawOnly,
    int? lastNPhotos,
    String? startDirectory,
    String? startFile,
    String? destinationPath,
  }) {
    return SyncSettings(
      downloadAll: downloadAll ?? this.downloadAll,
      jpegOnly: jpegOnly ?? this.jpegOnly,
      rawOnly: rawOnly ?? this.rawOnly,
      lastNPhotos: lastNPhotos ?? this.lastNPhotos,
      startDirectory: startDirectory ?? this.startDirectory,
      startFile: startFile ?? this.startFile,
      destinationPath: destinationPath ?? this.destinationPath,
    );
  }
}