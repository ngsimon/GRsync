import 'package:flutter/material.dart';
import '../models/device_info.dart';

class DeviceStatusCard extends StatelessWidget {
  final DeviceInfo? deviceInfo;
  final bool isConnected;
  final VoidCallback onConnect;

  const DeviceStatusCard({
    super.key,
    required this.deviceInfo,
    required this.isConnected,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Device Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (!isConnected) ...[
              const Text('Not connected to Ricoh GR camera'),
              const SizedBox(height: 8),
              const Text(
                'Make sure you are connected to the camera\'s WiFi network (RICOH_XXXXX)',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onConnect,
                child: const Text('Connect to Camera'),
              ),
            ] else ...[
              _buildInfoRow('Model', deviceInfo!.model),
              _buildInfoRow('Battery Level', '${deviceInfo!.battery}%'),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Connected and ready',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}