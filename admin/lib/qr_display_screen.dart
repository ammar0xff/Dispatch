import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class QRDisplayScreen extends StatelessWidget {
  final String data;
  final String name;

  QRDisplayScreen({required this.data, required this.name});

  Future<void> _saveQrCode(BuildContext context) async {
    try {
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
        final directory = await getDownloadsDirectory(); // Get the Downloads directory
        final file = await File('${directory!.path}/${name}_qr_code.png').create();
        await file.writeAsBytes(picData!.buffer.asUint8List());

        final newFile = await file.copy('${directory.path}/saved_${name}_qr_code.png');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR Code saved to: ${newFile.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save QR Code: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("QR Code for $name")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 300.0,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _saveQrCode(context),
              child: const Text("Save QR Code"),
            ),
          ],
        ),
      ),
    );
  }
}
