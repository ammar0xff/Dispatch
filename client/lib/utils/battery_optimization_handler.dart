import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class BatteryOptimizationHandler {
  static const platform = MethodChannel('com.example.wirya_qr_client/battery_optimization');

  static Future<void> requestDisableBatteryOptimizations(BuildContext context) async {
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      bool? result = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Disable Battery Optimizations'),
          content: Text('To ensure the app runs smoothly in the background, please disable battery optimizations for this app.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('OK'),
            ),
          ],
        ),
      );

      if (result == true) {
        await platform.invokeMethod('requestDisableBatteryOptimizations');
      }
    }
  }
}
