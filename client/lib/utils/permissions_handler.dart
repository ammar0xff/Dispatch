import 'package:permission_handler/permission_handler.dart';

class PermissionsHandler {
  static Future<void> requestPermissions() async {
    await [
      Permission.location,
      Permission.locationAlways,
      Permission.locationWhenInUse,
      Permission.notification,
      Permission.ignoreBatteryOptimizations,
    ].request();
  }
}
