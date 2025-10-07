import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_capabilities_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/location_card.dart';

/// Screen6: Location and Map Screen - displays GPS location and nearby stores
/// Shows current location, nearby stores, and connectivity status
class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({super.key});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);

    // Initialize location when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DeviceCapabilitiesProvider>();
      provider.updateLocation();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkTheme(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location & Stores'),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Consumer<DeviceCapabilitiesProvider>(
        builder: (context, deviceProvider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              await deviceProvider.updateLocation();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connectivity Status
                  _buildConnectivityStatus(deviceProvider),
                  const SizedBox(height: 16),

                  // Current Location
                  _buildCurrentLocation(deviceProvider),
                  const SizedBox(height: 16),

                  // Location Actions
                  _buildLocationActions(deviceProvider),
                  const SizedBox(height: 16),

                  // Nearby Stores Section
                  _buildNearbyStores(deviceProvider),
                  const SizedBox(height: 16),

                  // Mock Map Section
                  _buildMapSection(deviceProvider),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<DeviceCapabilitiesProvider>().updateLocation();
        },
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: const Icon(Icons.my_location),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConnectivityStatus(DeviceCapabilitiesProvider provider) {
    final isOnline = provider.isOnline;
    final status = provider.connectivityStatus;

    return Card(
      color: isOnline ? Colors.green[50] : Colors.red[50],
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              color: isOnline ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Network Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      color: isOnline ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isOnline)
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocation(DeviceCapabilitiesProvider provider) {
    final hasLocation = provider.currentPosition != null;
    final locationGranted = provider.locationPermissionGranted;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasLocation ? Icons.location_on : Icons.location_off,
                  color: hasLocation ? Colors.blue : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Location',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!locationGranted)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Location permission required')),
                    TextButton(
                      onPressed: () {
                        // Request location permission
                        provider.updateLocation();
                      },
                      child: const Text('Grant'),
                    ),
                  ],
                ),
              )
            else if (hasLocation)
              LocationCard(position: provider.currentPosition!)
            else
              const Text('Location not available'),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationActions(DeviceCapabilitiesProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                  onPressed: () => provider.updateLocation(),
                ),
                ActionChip(
                  avatar: const Icon(Icons.navigation, size: 18),
                  label: const Text('Navigate'),
                  onPressed:
                      provider.currentPosition != null
                          ? () => _showNavigationDialog(context)
                          : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyStores(DeviceCapabilitiesProvider provider) {
    final stores = provider.getNearbyStores();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Nearby Stores',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (stores.isEmpty)
              const Text(
                'No nearby stores found. Enable location to find stores.',
              )
            else
              ...stores.map((store) => _buildStoreListItem(store)),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreListItem(Map<String, dynamic> store) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.green,
        child: Text(
          store['name'].toString().substring(0, 1),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(store['name']),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(store['address']),
          Text(
            '${store['distance']} • ${store['hours']}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.directions),
        onPressed: () => _showDirectionsDialog(context, store),
      ),
    );
  }

  Widget _buildMapSection(DeviceCapabilitiesProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Map View', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Map integration coming soon',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      'This would show an interactive map',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNavigationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Navigation'),
            content: const Text(
              'This would open navigation to the selected store.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showDirectionsDialog(BuildContext context, Map<String, dynamic> store) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Directions to ${store['name']}'),
            content: Text('Navigate to ${store['address']}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // In a real app, this would open maps app
                },
                child: const Text('Navigate'),
              ),
            ],
          ),
    );
  }
}
