import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:wirya_qr_admin/qr_display_screen.dart';
import 'package:wirya_qr_admin/profile_edit_screen.dart';

class QRGeneratorScreen extends StatefulWidget {
  @override
  _QRGeneratorScreenState createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  String? generatedQR;
  String? errorMessage;
  File? qrImageFile;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void generateQR() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      setState(() {
        errorMessage = "Name and Phone fields cannot be empty.";
      });
      return;
    }
    try {
      String id = const Uuid().v4();
      Map<String, dynamic> profile = {
        "id": id,
        "name": _nameController.text,
        "location": _locationController.text,
        "phone": _phoneController.text,
        "category": _categoryController.text,
        "timestamp": ServerValue.timestamp,
      };

      await FirebaseDatabase.instance.ref("profiles").child(id).set(profile);
      setState(() {
        generatedQR = id;
        errorMessage = null;
        qrImageFile = null;
      });
      await _generateQrImage(id, _nameController.text);
    } catch (e) {
      setState(() {
        errorMessage = "Failed to generate QR code: $e";
      });
    }
  }

  Future<void> _generateQrImage(String data, String profileName) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
    if (qrValidationResult.status == QrValidationStatus.valid) {
      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );
      final picData = await painter.toImageData(300);
      final directory = await getExternalStorageDirectory(); // Get the external storage directory
      final downloadsDirectory = Directory('${directory!.path}/Download'); // Use the Download folder
      if (!downloadsDirectory.existsSync()) {
        downloadsDirectory.createSync();
      }
      final file = await File('${downloadsDirectory.path}/${profileName}_qr_code.png').create();
      await file.writeAsBytes(picData!.buffer.asUint8List());

      setState(() {
        qrImageFile = file;
      });
    }
  }

  void deleteProfile(String id) async {
    try {
      await FirebaseDatabase.instance.ref("profiles").child(id).remove();
      setState(() {
        if (generatedQR == id) generatedQR = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to delete profile: $e";
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Code Generator")),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: "Location",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: "Phone",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: generateQR,
                  child: const Text("Generate QR Code"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (qrImageFile != null)
                Image.file(qrImageFile!),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance.ref("profiles").onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return const Center(child: Text("No profiles found."));
                    }
                    Map<dynamic, dynamic> profiles = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    return ListView(
                      children: profiles.entries.map((entry) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          child: ListTile(
                            title: Text(entry.value["name"] ?? "No Name", style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(entry.value["phone"] ?? "No Phone"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.qr_code, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QRDisplayScreen(data: entry.key, name: entry.value["name"]),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.green),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfileEditScreen(profileId: entry.key, profileData: entry.value),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteProfile(entry.key),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
