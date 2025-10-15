import 'package:json_annotation/json_annotation.dart';

part 'device_info.g.dart';

@JsonSerializable()
class DeviceInfo {
  final String model;
  final int battery;
  final int errCode;
  final String? errMsg;

  const DeviceInfo({
    required this.model,
    required this.battery,
    required this.errCode,
    this.errMsg,
  });

  bool get isSupported => [
    'RICOH GR II',
    'RICOH GR III', 
    'RICOH GR IIIx'
  ].contains(model);

  bool get batteryLevelOk => battery >= 15;
  bool get hasError => errCode != 200;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => _$DeviceInfoFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);
}