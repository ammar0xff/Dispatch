import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Database package
import 'package:geocoding/geocoding.dart'; // Import geocoding package
import 'package:geolocator/geolocator.dart'; // Import geolocator package
import '../utils/telegram_logger.dart'; // Import the TelegramLogger

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  String scannedData = "";
  bool isLoading = false;
  String errorMessage = "";
  bool isBeepSoundEnabled = true;
  final AudioPlayer audioPlayer = AudioPlayer();
  Map<String, dynamic>? qrProfileInfo;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isBeepSoundEnabled = prefs.getBool('isBeepSoundEnabled') ?? true;
    });
  }

  void _onDetect(BarcodeCapture barcodeCapture) async {
    final barcode = barcodeCapture.barcodes.first;
    if (scannedData.isEmpty) {
      setState(() {
        scannedData = barcode.rawValue!;
        isLoading = true;
        errorMessage = "";
      });
      try {
        await _processScan(scannedData);
        if (isBeepSoundEnabled) {
          await audioPlayer.play(AssetSource('beep.mp3')); // Play beep sound
        }
        // Reset scannedData after a short delay to allow scanning another QR code
        Future.delayed(Duration(seconds: 2), () {
          setState(() {
            scannedData = "";
          });
        });
      } catch (e) {
        setState(() {
          errorMessage = "Error processing scan: $e";
        });
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _processScan(String uniqueId) async {
    // Fetch QR profile info
    DatabaseReference profileRef = FirebaseDatabase.instance.ref("profiles/$uniqueId");
    DatabaseEvent event = await profileRef.once();
    if (event.snapshot.value != null) {
      setState(() {
        qrProfileInfo = Map<String, dynamic>.from(event.snapshot.value as Map);
      });

      // Get current location
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      String scanLocation = "Unknown location";
      if (placemarks.isNotEmpty) {
        scanLocation = placemarks.first.locality ?? "Unknown location";
      }

      // Get the logged-in user's name
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      // Send log to Telegram Bot
      await TelegramLogger.sendLog(qrProfileInfo!, username ?? "Unknown user", scanLocation, position.latitude, position.longitude);
    } else {
      setState(() {
        errorMessage = "Profile not found.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("QR Scanner")),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: _onDetect,
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: isLoading
                  ? CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 20), // Add space above the text
                        Text(scannedData.isNotEmpty ? "Scanned: $scannedData" : "Scan a QR code"),
                        if (qrProfileInfo != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(
                                  "Name: ${qrProfileInfo!['name']}",
                                  style: TextStyle(color: Colors.green, fontSize: 18),
                                ),
                                Text(
                                  "Category: ${qrProfileInfo!['category']}",
                                  style: TextStyle(color: Colors.green, fontSize: 18),
                                ),
                                Text(
                                  "Phone: ${qrProfileInfo!['phone']}",
                                  style: TextStyle(color: Colors.green, fontSize: 18),
                                ),
                                Text(
                                  "Location: ${qrProfileInfo!['location']}",
                                  style: TextStyle(color: Colors.green, fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        if (errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              errorMessage,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
