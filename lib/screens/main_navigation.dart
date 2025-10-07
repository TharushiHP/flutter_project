import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'location_map_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/device_capabilities_provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const CartScreen(),
    const DeviceStatusScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = ['Home', 'Cart', 'Device Info', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          _currentIndex == 0
              ? null
              : AppBar(
                title: Text(_titles[_currentIndex]),
                centerTitle: true,
                leading:
                    _currentIndex == 1
                        ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            setState(
                              () => _currentIndex = 0,
                            ); // Go back to home
                          },
                        )
                        : null,
                actions: [
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () async {
                          await authProvider.logout();
                          if (mounted && context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          }
                        },
                        tooltip: 'Logout',
                      );
                    },
                  ),
                ],
              ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 0 ? Icons.home : Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 1
                  ? Icons.shopping_cart
                  : Icons.shopping_cart_outlined,
            ),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 2 ? Icons.info : Icons.info_outline),
            label: 'Device Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 3 ? Icons.person : Icons.person_outline,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// New Device Status Screen
class DeviceStatusScreen extends StatelessWidget {
  const DeviceStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceCapabilitiesProvider>(
      builder: (context, deviceProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Introduction Card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Device Info Overview',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This screen provides real-time information about your device capabilities, '
                        'connectivity status, and location services. Use this information to optimize '
                        'your app experience and troubleshoot any issues.',
                        style: TextStyle(color: Colors.blue[600], fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            deviceProvider.updateLocation();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Device information refreshed'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh All Info'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connectivity Status',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            deviceProvider.connectivityResult.name == 'none'
                                ? Icons.wifi_off
                                : Icons.wifi,
                            color:
                                deviceProvider.connectivityResult.name == 'none'
                                    ? Colors.red
                                    : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(deviceProvider.connectivityStatus),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Battery Status',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.battery_std,
                            color:
                                deviceProvider.batteryLevel > 20
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(deviceProvider.batteryStatusText),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            deviceProvider.locationPermissionGranted
                                ? Icons.location_on
                                : Icons.location_off,
                            color:
                                deviceProvider.locationPermissionGranted
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              deviceProvider.locationPermissionGranted
                                  ? deviceProvider.locationString
                                  : 'Location permission not granted',
                            ),
                          ),
                        ],
                      ),
                      if (deviceProvider.locationPermissionGranted)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ElevatedButton(
                            onPressed: () => deviceProvider.updateLocation(),
                            child: const Text('Update Location'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Store Locator
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby Stores',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      if (deviceProvider.locationPermissionGranted)
                        ...deviceProvider.getNearbyStores().map(
                          (store) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(
                                Icons.store,
                                color: Colors.green,
                              ),
                              title: Text(store['name'] as String),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(store['address'] as String),
                                  Text('Distance: ${store['distance']}'),
                                  Text('Hours: ${store['hours']}'),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          ),
                        )
                      else
                        const Text('Location required to show nearby stores'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // App Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('App Version', '1.0.0'),
                      _buildInfoRow('Build Number', '1'),
                      _buildInfoRow('Flutter Version', '3.24.0'),
                      _buildInfoRow('Platform', 'Android/iOS'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Device Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Device Model', 'Simulator/Emulator'),
                      _buildInfoRow('OS Version', 'Android/iOS Latest'),
                      _buildInfoRow(
                        'Screen Resolution',
                        '${MediaQuery.of(context).size.width.toInt()} x ${MediaQuery.of(context).size.height.toInt()}',
                      ),
                      _buildInfoRow(
                        'Pixel Density',
                        '${MediaQuery.of(context).devicePixelRatio}x',
                      ),
                      _buildInfoRow(
                        'Screen Size',
                        '${(MediaQuery.of(context).size.width / 160).toStringAsFixed(1)}" diagonal',
                      ),
                      _buildInfoRow(
                        'Text Scale Factor',
                        '${MediaQuery.of(context).textScaler.scale(1.0).toStringAsFixed(1)}x',
                      ),
                      _buildInfoRow(
                        'Brightness',
                        MediaQuery.of(context).platformBrightness ==
                                Brightness.dark
                            ? 'Dark Mode'
                            : 'Light Mode',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Access to Additional Screens
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Capabilities',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/camera');
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const LocationMapScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.location_on),
                              label: const Text('Location'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
