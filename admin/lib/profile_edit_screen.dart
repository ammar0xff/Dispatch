import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ProfileEditScreen extends StatefulWidget {
  final String profileId;
  final Map<dynamic, dynamic> profileData;

  ProfileEditScreen({required this.profileId, required this.profileData});

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  late TextEditingController _categoryController;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileData["name"]);
    _locationController = TextEditingController(text: widget.profileData["location"]);
    _phoneController = TextEditingController(text: widget.profileData["phone"]);
    _categoryController = TextEditingController(text: widget.profileData["category"]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void saveProfile() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      setState(() {
        errorMessage = "Name and Phone fields cannot be empty.";
      });
      return;
    }
    try {
      Map<String, dynamic> updatedProfile = {
        "name": _nameController.text,
        "location": _locationController.text,
        "phone": _phoneController.text,
        "category": _categoryController.text,
      };

      await FirebaseDatabase.instance.ref("profiles").child(widget.profileId).update(updatedProfile);
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        errorMessage = "Failed to save profile: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: "Location")),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone"), keyboardType: TextInputType.phone),
            TextField(controller: _categoryController, decoration: const InputDecoration(labelText: "Category")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: saveProfile, child: const Text("Save")),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
