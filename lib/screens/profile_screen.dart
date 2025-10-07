import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/device_capabilities_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // User Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green,
                        child: Text(
                          authProvider.userName
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              'U',
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        authProvider.userName ?? 'User',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authProvider.userEmail ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Menu Options
              _buildMenuCard(
                context,
                icon: Icons.edit,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),

              _buildMenuCard(
                context,
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'App preferences and configuration',
                onTap: () {
                  _showSettingsDialog(context);
                },
              ),

              _buildMenuCard(
                context,
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help and contact support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help feature coming soon!')),
                  );
                },
              ),

              _buildMenuCard(
                context,
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version and information',
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('About Grocery Store'),
                          content: const Text(
                            'Grocery Store App v1.0.0\n\n'
                            'A Flutter demonstration app showcasing:\n'
                            '• State management with Provider\n'
                            '• Authentication integration\n'
                            '• Device sensor capabilities\n'
                            '• Local data storage\n'
                            '• API connectivity\n\n'
                            'Developed for MAD Assignment',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Consumer2<ThemeProvider, DeviceCapabilitiesProvider>(
            builder:
                (context, themeProvider, deviceProvider, child) => AlertDialog(
                  title: const Text('Settings'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Permissions Section
                          const Text(
                            'Permissions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Location Permission
                          Card(
                            child: ListTile(
                              leading: Icon(
                                Icons.location_on,
                                color:
                                    deviceProvider.locationPermissionGranted
                                        ? Colors.green
                                        : Colors.orange,
                              ),
                              title: const Text('Location Access'),
                              subtitle: Text(
                                deviceProvider.locationPermissionGranted
                                    ? 'Granted - Used for delivery tracking'
                                    : 'Not granted - Tap to enable location services',
                              ),
                              trailing:
                                  deviceProvider.locationPermissionGranted
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                      : ElevatedButton(
                                        onPressed: () async {
                                          // Show loading dialog
                                          showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder:
                                                (context) => const AlertDialog(
                                                  content: Row(
                                                    children: [
                                                      CircularProgressIndicator(),
                                                      SizedBox(width: 16),
                                                      Text(
                                                        'Requesting permission...',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          );

                                          try {
                                            await deviceProvider
                                                .requestPermissions();
                                          } finally {
                                            if (context.mounted) {
                                              Navigator.pop(
                                                context,
                                              ); // Close loading dialog
                                            }
                                          }

                                          if (context.mounted) {
                                            if (deviceProvider
                                                .locationPermissionGranted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Location permission granted successfully!',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else {
                                              // Check if permanently denied
                                              bool canOpenSettings =
                                                  await deviceProvider
                                                      .canOpenLocationSettings();

                                              if (context.mounted) {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (context) => AlertDialog(
                                                        title: const Text(
                                                          'Permission Required',
                                                        ),
                                                        content: Text(
                                                          canOpenSettings
                                                              ? 'Location permission was permanently denied. Please enable it in device settings.'
                                                              : 'Location permission was denied. Please try again or enable it manually in device settings.',
                                                        ),
                                                        actions: [
                                                          if (canOpenSettings)
                                                            TextButton(
                                                              onPressed: () async {
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                                await deviceProvider
                                                                    .openLocationSettings();
                                                              },
                                                              child: const Text(
                                                                'Open Settings',
                                                              ),
                                                            ),
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                    ),
                                                            child: const Text(
                                                              'OK',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                        child: const Text('Grant'),
                                      ),
                            ),
                          ),

                          // Camera Permission
                          Card(
                            child: ListTile(
                              leading: Icon(
                                Icons.camera_alt,
                                color:
                                    deviceProvider.cameraPermissionGranted
                                        ? Colors.green
                                        : Colors.orange,
                              ),
                              title: const Text('Camera Access'),
                              subtitle: Text(
                                deviceProvider.cameraPermissionGranted
                                    ? 'Granted - Used for product scanning'
                                    : 'Not granted - Tap to enable camera access',
                              ),
                              trailing:
                                  deviceProvider.cameraPermissionGranted
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                      : ElevatedButton(
                                        onPressed: () async {
                                          await deviceProvider
                                              .requestPermissions();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  deviceProvider
                                                          .cameraPermissionGranted
                                                      ? 'Camera permission granted!'
                                                      : 'Camera permission denied. You can enable it in device settings.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text('Grant'),
                                      ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Theme Settings Section
                          const Text(
                            'Theme Settings',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Light Mode Option
                          RadioListTile<ThemeMode>(
                            title: const Text('Light Mode'),
                            subtitle: const Text('Use light theme'),
                            value: ThemeMode.light,
                            groupValue: themeProvider.themeMode,
                            onChanged: (value) {
                              if (value != null) {
                                themeProvider.setLightMode();
                              }
                            },
                          ),

                          // Dark Mode Option
                          RadioListTile<ThemeMode>(
                            title: const Text('Dark Mode'),
                            subtitle: const Text('Use dark theme'),
                            value: ThemeMode.dark,
                            groupValue: themeProvider.themeMode,
                            onChanged: (value) {
                              if (value != null) {
                                themeProvider.setDarkMode();
                              }
                            },
                          ),

                          // System Mode Option
                          RadioListTile<ThemeMode>(
                            title: const Text('System Default'),
                            subtitle: const Text('Follow system theme'),
                            value: ThemeMode.system,
                            groupValue: themeProvider.themeMode,
                            onChanged: (value) {
                              if (value != null) {
                                themeProvider.setSystemMode();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
          ),
    );
  }
}
