import 'package:json_annotation/json_annotation.dart';

part 'photo.g.dart';

@JsonSerializable()
class Photo {
  final String directory;
  final String filename;
  final bool isDownloaded;
  final int? fileSize;
  final DateTime? dateCreated;

  const Photo({
    required this.directory,
    required this.filename,
    this.isDownloaded = false,
    this.fileSize,
    this.dateCreated,
  });

  String get fullPath => '$directory/$filename';
  
  bool get isJpeg => filename.toUpperCase().endsWith('.JPG');
  bool get isRaw => filename.toUpperCase().endsWith('.DNG') || filename.toUpperCase().endsWith('.RAW');

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);
  Map<String, dynamic> toJson() => _$PhotoToJson(this);

  Photo copyWith({
    String? directory,
    String? filename,
    bool? isDownloaded,
    int? fileSize,
    DateTime? dateCreated,
  }) {
    return Photo(
      directory: directory ?? this.directory,
      filename: filename ?? this.filename,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      fileSize: fileSize ?? this.fileSize,
      dateCreated: dateCreated ?? this.dateCreated,
    );
  }
}