// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Photo _$PhotoFromJson(Map<String, dynamic> json) => Photo(
      directory: json['directory'] as String,
      filename: json['filename'] as String,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      fileSize: json['fileSize'] as int?,
      dateCreated: json['dateCreated'] == null
          ? null
          : DateTime.parse(json['dateCreated'] as String),
    );

Map<String, dynamic> _$PhotoToJson(Photo instance) => <String, dynamic>{
      'directory': instance.directory,
      'filename': instance.filename,
      'isDownloaded': instance.isDownloaded,
      'fileSize': instance.fileSize,
      'dateCreated': instance.dateCreated?.toIso8601String(),
    };