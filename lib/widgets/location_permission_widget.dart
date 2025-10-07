import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_capabilities_provider.dart';

class LocationPermissionWidget extends StatelessWidget {
  final Widget child;
  final bool showDialogIfDenied;

  const LocationPermissionWidget({
    super.key,
    required this.child,
    this.showDialogIfDenied = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceCapabilitiesProvider>(
      builder: (context, deviceProvider, _) {
        // If location permission is granted, show the child widget
        if (deviceProvider.locationPermissionGranted) {
          return child;
        }

        // If permission not granted, show permission request UI
        return Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 64,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Location Permission Required',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This feature requires location access to provide delivery tracking and find nearby stores.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await deviceProvider.requestPermissions();

                      if (showDialogIfDenied &&
                          !deviceProvider.locationPermissionGranted &&
                          context.mounted) {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Permission Denied'),
                                content: const Text(
                                  'Location permission was denied. You can manually enable it in your device settings under App Permissions.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                        );
                      }
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Grant Location Permission'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // Show child anyway (for cases where location is optional)
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => child),
                      );
                    },
                    child: const Text('Continue without location'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Quick function to show location permission dialog
Future<void> showLocationPermissionDialog(BuildContext context) async {
  final deviceProvider = Provider.of<DeviceCapabilitiesProvider>(
    context,
    listen: false,
  );

  if (deviceProvider.locationPermissionGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location permission already granted!')),
    );
    return;
  }

  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Enable Location Services'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, size: 48, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Enable location services to:\n\n'
                '• Track delivery progress\n'
                '• Find nearby stores\n'
                '• Get location-based offers\n'
                '• Estimate delivery times',
                textAlign: TextAlign.left,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await deviceProvider.requestPermissions();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        deviceProvider.locationPermissionGranted
                            ? 'Location permission granted successfully!'
                            : 'Permission denied. You can enable it in device settings.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Enable'),
            ),
          ],
        ),
  );
}
