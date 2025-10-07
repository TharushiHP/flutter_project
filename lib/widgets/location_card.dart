import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Card widget to display GPS location information
class LocationCard extends StatelessWidget {
  final Position position;

  const LocationCard({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coordinates
          Row(
            children: [
              const Icon(Icons.place, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Coordinates',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Latitude and Longitude
          _buildLocationRow('Latitude', position.latitude.toStringAsFixed(6)),
          const SizedBox(height: 4),
          _buildLocationRow('Longitude', position.longitude.toStringAsFixed(6)),
          const SizedBox(height: 4),
          _buildLocationRow(
            'Altitude',
            '${position.altitude.toStringAsFixed(1)} m',
          ),
          const SizedBox(height: 4),
          _buildLocationRow(
            'Accuracy',
            '±${position.accuracy.toStringAsFixed(1)} m',
          ),

          const SizedBox(height: 8),

          // Timestamp
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Updated: ${_formatTimestamp(position.timestamp)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
