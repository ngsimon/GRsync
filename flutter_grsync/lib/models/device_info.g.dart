// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => DeviceInfo(
      model: json['model'] as String,
      battery: json['battery'] as int,
      errCode: json['errCode'] as int,
      errMsg: json['errMsg'] as String?,
    );

Map<String, dynamic> _$DeviceInfoToJson(DeviceInfo instance) => <String, dynamic>{
      'model': instance.model,
      'battery': instance.battery,
      'errCode': instance.errCode,
      'errMsg': instance.errMsg,
    };