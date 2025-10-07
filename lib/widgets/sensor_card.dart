import 'package:flutter/material.dart';
import '../models/device_info.dart';

/// Card widget to display sensor data in a compact format
class SensorCard extends StatelessWidget {
  final SensorData sensorData;

  const SensorCard({super.key, required this.sensorData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: isDark ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sensor type header
            Row(
              children: [
                Icon(
                  _getSensorIcon(sensorData.sensorType),
                  size: 16,
                  color: _getSensorColor(sensorData.sensorType),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    sensorData.sensorType.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getSensorColor(sensorData.sensorType),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Sensor values
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildValueRow(
                    'X',
                    sensorData.values['x'] ?? 0.0,
                    Colors.red,
                  ),
                  _buildValueRow(
                    'Y',
                    sensorData.values['y'] ?? 0.0,
                    Colors.green,
                  ),
                  _buildValueRow(
                    'Z',
                    sensorData.values['z'] ?? 0.0,
                    Colors.blue,
                  ),
                ],
              ),
            ),

            // Timestamp
            Text(
              '${sensorData.timestamp.hour.toString().padLeft(2, '0')}:'
              '${sensorData.timestamp.minute.toString().padLeft(2, '0')}:'
              '${sensorData.timestamp.second.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueRow(String axis, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          axis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  IconData _getSensorIcon(String sensorType) {
    switch (sensorType.toLowerCase()) {
      case 'accelerometer':
        return Icons.speed;
      case 'gyroscope':
        return Icons.rotate_right;
      case 'magnetometer':
        return Icons.explore;
      default:
        return Icons.sensors;
    }
  }

  Color _getSensorColor(String sensorType) {
    switch (sensorType.toLowerCase()) {
      case 'accelerometer':
        return Colors.blue;
      case 'gyroscope':
        return Colors.purple;
      case 'magnetometer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
