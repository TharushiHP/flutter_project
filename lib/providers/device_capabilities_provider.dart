import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import '../models/device_info.dart';
import 'dart:async';

class DeviceCapabilitiesProvider with ChangeNotifier {
  // Geolocation (for store locator, delivery tracking)
  Position? _currentPosition;
  bool _locationPermissionGranted = false;
  LocationData? _locationData;

  // Battery (to warn user about low battery during shopping)
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;

  // Connectivity (for online/offline shopping)
  List<ConnectivityResult> _connectivityResults = [ConnectivityResult.none];
  ConnectivityInfo? _connectivityInfo;

  // Camera functionality for product scanning and item photos
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _cameraPermissionGranted = false;

  // Stream subscriptions
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<List<ConnectivityResult>>? _connectivityStream;

  // Getters
  Position? get currentPosition => _currentPosition;
  bool get locationPermissionGranted => _locationPermissionGranted;
  LocationData? get locationData => _locationData;

  int get batteryLevel => _batteryLevel;
  BatteryState get batteryState => _batteryState;

  List<ConnectivityResult> get connectivityResults => _connectivityResults;
  ConnectivityInfo? get connectivityInfo => _connectivityInfo;
  ConnectivityResult get connectivityResult =>
      _connectivityResults.isNotEmpty
          ? _connectivityResults.first
          : ConnectivityResult.none;

  // Camera getters
  List<CameraDescription> get cameras => _cameras;
  CameraController? get cameraController => _cameraController;
  bool get isCameraInitialized => _isCameraInitialized;
  bool get cameraPermissionGranted => _cameraPermissionGranted;

  String get connectivityStatus {
    if (_connectivityResults.contains(ConnectivityResult.wifi)) {
      return 'WiFi Connected';
    } else if (_connectivityResults.contains(ConnectivityResult.mobile)) {
      return 'Mobile Data';
    } else if (_connectivityResults.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    } else if (_connectivityResults.contains(ConnectivityResult.vpn)) {
      return 'VPN';
    } else if (_connectivityResults.contains(ConnectivityResult.other)) {
      return 'Connected';
    } else {
      return 'No Internet';
    }
  }

  String get batteryStatusText {
    String levelText = '$_batteryLevel%';
    switch (_batteryState) {
      case BatteryState.charging:
        return '$levelText (Charging)';
      case BatteryState.discharging:
        return levelText;
      case BatteryState.full:
        return '$levelText (Full)';
      case BatteryState.unknown:
      default:
        return levelText;
    }
  }

  bool get isLowBattery => _batteryLevel < 20;
  bool get isOnline =>
      !_connectivityResults.contains(ConnectivityResult.none) &&
      _connectivityResults.isNotEmpty;

  DeviceCapabilitiesProvider() {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _initializeLocation();
    await _initializeBattery();
    await _initializeConnectivity();
    await _initializeCamera();
  }

  // Location Services (for store locator and delivery)
  Future<void> _initializeLocation() async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        _locationPermissionGranted = false;
        notifyListeners();
        return;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('Current location permission: $permission');

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        debugPrint('Permission after request: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          'Location permissions are permanently denied, cannot request permissions.',
        );
        _locationPermissionGranted = false;
        notifyListeners();
        return;
      }

      // Update permission status
      _locationPermissionGranted =
          (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always);

      debugPrint('Location permission granted: $_locationPermissionGranted');

      if (_locationPermissionGranted) {
        try {
          _currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          debugPrint(
            'Current position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}',
          );

          // Listen to position changes for delivery tracking
          _positionStream = Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 100, // Update every 100 meters
            ),
          ).listen((Position position) {
            _currentPosition = position;
            notifyListeners();
          });
        } catch (e) {
          debugPrint('Error getting location: $e');
        }
      }
    } catch (e) {
      debugPrint('Location initialization error: $e');
      _locationPermissionGranted = false;
    }
    notifyListeners();
  }

  Future<void> updateLocation() async {
    if (_locationPermissionGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        notifyListeners();
      } catch (e) {
        debugPrint('Update location error: $e');
      }
    }
  }

  // Battery Services (warn user about low battery during shopping)
  Future<void> _initializeBattery() async {
    try {
      final battery = Battery();
      _batteryLevel = await battery.batteryLevel;
      _batteryState = await battery.batteryState;

      // Listen to battery changes
      battery.onBatteryStateChanged.listen((BatteryState state) {
        _batteryState = state;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Battery error: $e');
    }
    notifyListeners();
  }

  // Connectivity Services (for online/offline features)
  Future<void> _initializeConnectivity() async {
    try {
      _connectivityResults = await Connectivity().checkConnectivity();

      _connectivityStream = Connectivity().onConnectivityChanged.listen((
        List<ConnectivityResult> results,
      ) {
        _connectivityResults = results;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Connectivity error: $e');
    }
    notifyListeners();
  }

  // Camera Services (for product scanning and photos)
  Future<void> _initializeCamera() async {
    try {
      final permission = await Permission.camera.request();
      _cameraPermissionGranted = permission.isGranted;

      if (_cameraPermissionGranted) {
        _cameras = await availableCameras();
        if (_cameras.isNotEmpty) {
          await _setupCamera(_cameras.first);
        }
      }
    } catch (e) {
      debugPrint('Camera error: $e');
    }
    notifyListeners();
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    try {
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      _isCameraInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Camera setup error: $e');
      _isCameraInitialized = false;
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length > 1 && _cameraController != null) {
      await _cameraController!.dispose();
      _isCameraInitialized = false;

      // Find the next camera
      final currentIndex = _cameras.indexOf(_cameraController!.description);
      final nextIndex = (currentIndex + 1) % _cameras.length;

      await _setupCamera(_cameras[nextIndex]);
    }
  }

  Future<XFile?> takePicture() async {
    if (_cameraController != null && _isCameraInitialized) {
      try {
        return await _cameraController!.takePicture();
      } catch (e) {
        debugPrint('Take picture error: $e');
        return null;
      }
    }
    return null;
  }

  // Store location functionality (for finding nearby stores)
  String get locationString {
    if (_currentPosition != null) {
      return 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
          'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}';
    }
    return 'Location unavailable';
  }

  List<Map<String, dynamic>> getNearbyStores() {
    // Mock data for grocery stores - in real app this would use actual store API
    return [
      {
        'name': 'Fresh Market',
        'address': '123 Main St',
        'distance': '0.3 km',
        'hours': '8:00 AM - 10:00 PM',
        'isOpen': true,
      },
      {
        'name': 'SuperValue Grocery',
        'address': '456 Oak Ave',
        'distance': '0.7 km',
        'hours': '7:00 AM - 11:00 PM',
        'isOpen': true,
      },
      {
        'name': 'Organic Corner',
        'address': '789 Green Blvd',
        'distance': '1.2 km',
        'hours': '9:00 AM - 9:00 PM',
        'isOpen': false,
      },
    ];
  }

  // Battery optimization for camera usage
  void optimizeBatteryForCamera() {
    if (_isCameraInitialized && _batteryLevel < 20) {
      // Reduce camera resolution for battery saving
      _setupCameraWithLowerResolution();
    }
  }

  // Public method to request permissions again
  Future<void> requestPermissions() async {
    debugPrint('Requesting permissions...');
    await _initializeLocation();
    await _initializeCamera();
  }

  // Method to check if we can open location settings
  Future<bool> canOpenLocationSettings() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.deniedForever;
    } catch (e) {
      debugPrint('Error checking location settings capability: $e');
      return false;
    }
  }

  // Method to open device location settings
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('Error opening location settings: $e');
    }
  }

  // Debug method to check current permission status
  Future<String> getLocationPermissionStatus() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      return 'Service enabled: $serviceEnabled, Permission: $permission';
    } catch (e) {
      return 'Error checking status: $e';
    }
  }

  Future<void> _setupCameraWithLowerResolution() async {
    if (_cameraController != null && _cameras.isNotEmpty) {
      await _cameraController!.dispose();
      _isCameraInitialized = false;

      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.medium, // Lower resolution for battery saving
        enableAudio: false,
      );

      await _cameraController!.initialize();
      _isCameraInitialized = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _connectivityStream?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }
}
