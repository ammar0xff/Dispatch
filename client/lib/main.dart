import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';

import 'firebase_options.dart'; // Firebase configuration
import 'screens/dashboard_screen.dart'; // Dashboard Screen
import 'screens/login_screen.dart'; // Login Screen
import 'screens/tasks_screen.dart'; // Tasks Screen
import 'screens/qr_scanner_screen.dart'; // QR Scanner Screen
import 'screens/about_screen.dart'; // About Screen
import 'screens/lock_check_screen.dart'; // Lock Check Screen
import 'utils/permissions_handler.dart'; // Permissions Handler
import 'utils/location_service.dart'; // Location Service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Request necessary permissions
    await requestLocationPermission();
    await PermissionsHandler.requestPermissions();
    await disableBatteryOptimization();

    // Check if the app is locked
    final bool isLocked = await checkIfLocked();

    // Get stored user credentials
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('username');
    final String? password = prefs.getString('password');

    // Determine the initial screen based on app state
    final Widget initialScreen = isLocked
        ? LockCheckScreen()
        : (username != null && password != null ? MainScreen(user: username) : LoginScreen());

    // Run the app
    runApp(QRClientApp(initialScreen: initialScreen));

    // Initialize background services if the app is not locked
    if (!isLocked) {
      await requestNotificationPermission();
      await initializeService();

      if (username != null) {
        LocationService.startPeriodicLocationUpdates(username);
      }
    }
  } catch (e) {
    // Handle initialization errors
    runApp(ErrorApp("Failed to initialize app: $e"));
  }
}

/// Check if the app is locked by querying Firebase
Future<bool> checkIfLocked() async {
  final DatabaseReference lockRef = FirebaseDatabase.instance.ref("locked");
  final DatabaseEvent event = await lockRef.once();
  return event.snapshot.value == true;
}

/// Request location permission
Future<void> requestLocationPermission() async {
  var status = await Permission.location.status;
  if (status.isDenied) {
    status = await Permission.location.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }
}

/// Request notification permission
Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

/// Disable battery optimization
Future<void> disableBatteryOptimization() async {
  if (await Permission.ignoreBatteryOptimizations.isDenied) {
    await Permission.ignoreBatteryOptimizations.request();
  }
}

/// Initialize the background service
Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'Foreground Service', // title
    description: 'This channel is used for the foreground service.',
    importance: Importance.high, // Set importance to High
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'QR Client',
      initialNotificationContent: 'App is running in the background',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

/// Background service start handler
Future<void> onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'my_foreground', // id
      'Foreground Service', // title
      description: 'This channel is used for the foreground service.', // description
      importance: Importance.high, // importance
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    service.setForegroundNotificationInfo(
      title: "QR Client",
      content: "App is running in the background",
    );

    // Enable wake lock to keep the CPU awake
    WakelockPlus.enable();

    // Configure location settings for continuous updates
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // High accuracy
      distanceFilter: 0, // Receive updates even if the device hasn't moved
    );

    // Listen to location updates
    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final String? username = prefs.getString('username');

          if (username != null) {
            await LocationService.updateLocation(username, position);
          }
        } catch (e) {
          print("Failed to upload location: $e");
        }
      },
    );

    // Stop the service when requested
    service.on('stopService').listen((event) {
      WakelockPlus.disable();
      service.stopSelf();
    });
  }
}

/// iOS background service handler
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

/// Main app widget
class QRClientApp extends StatelessWidget {
  final Widget initialScreen;

  const QRClientApp({Key? key, required this.initialScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Prevent screen from sleeping
    WakelockPlus.enable();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}

/// Error app widget
class ErrorApp extends StatelessWidget {
  final String errorMessage;

  const ErrorApp(this.errorMessage, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(
          child: Text("Error initializing app: $errorMessage"),
        ),
      ),
    );
  }
}

/// Main screen with bottom navigation
class MainScreen extends StatefulWidget {
  final String user;

  const MainScreen({Key? key, required this.user}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _widgetOptions.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  static final List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(user: 'user'), // Replace with actual user
    const TasksScreen(),
    QRScannerScreen(),
    AboutScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _tabController.animateTo(index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'QR Scanner'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}