import 'package:flutter/material.dart';

class LockCheckScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("App Locked")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("This application is currently locked by the developer."),
            SizedBox(height: 20),
            Text("Please contact support for more information."),
          ],
        ),
      ),
    );
  }
}
