import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'main_screen.dart'; // Import the MainScreen

class LockCheckScreen extends StatefulWidget {
  @override
  _LockCheckScreenState createState() => _LockCheckScreenState();
}

class _LockCheckScreenState extends State<LockCheckScreen> {
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  void _checkLockStatus() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    DatabaseEvent event = await ref.once();
    if (event.snapshot.value != null && event.snapshot.value is Map) {
      Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _isLocked = data['locked'] ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return Scaffold(
        body: Center(
          child: Text(
            'Locked by the developer due to uncompleted payments\nCall: 01558695202',
            style: TextStyle(fontSize: 20, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return MainScreen();
    }
  }
}
