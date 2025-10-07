/// Model to hold sensor and device capability data
class DeviceInfo {
  final String? deviceId;
  final String? deviceName;
  final String? platform;
  final String? version;
  final bool isPhysicalDevice;

  DeviceInfo({
    this.deviceId,
    this.deviceName,
    this.platform,
    this.version,
    this.isPhysicalDevice = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'version': version,
      'isPhysicalDevice': isPhysicalDevice,
    };
  }
}

/// Model for sensor data readings
class SensorData {
  final DateTime timestamp;
  final String sensorType;
  final Map<String, dynamic> values;

  SensorData({
    required this.timestamp,
    required this.sensorType,
    required this.values,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'sensorType': sensorType,
      'values': values,
    };
  }
}

/// Model for location data
class LocationData {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final DateTime timestamp;
  final String? address;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    required this.timestamp,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
    };
  }
}

/// Model for network connectivity status
class ConnectivityInfo {
  final bool isConnected;
  final String connectionType;
  final DateTime lastChecked;

  ConnectivityInfo({
    required this.isConnected,
    required this.connectionType,
    required this.lastChecked,
  });

  Map<String, dynamic> toJson() {
    return {
      'isConnected': isConnected,
      'connectionType': connectionType,
      'lastChecked': lastChecked.toIso8601String(),
    };
  }
}
