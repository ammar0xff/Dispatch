import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/location_service.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("About")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Application Version: 1.0.0", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Developer: Ammar Mohamed\n 01558695202", style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String? username = prefs.getString('username');
                if (username != null) {
                  await LocationService.updateLocation(username, position);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location uploaded successfully")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User not logged in")));
                }
              },
              child: Text("Upload Location"),
            ),
          ],
        ),
      ),
    );
  }
}
