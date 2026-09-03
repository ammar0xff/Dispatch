import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "About this App",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "This app is developed to manage QR codes, users, and track their live locations.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text(
              "Developer Contact Information",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Name: Ammar",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Email: ammar@example.com",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Phone: +1234567890",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
