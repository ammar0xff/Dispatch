import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UsersManagementScreen extends StatefulWidget {
  @override
  _UsersManagementScreenState createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("users");
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _editingUserId;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _addOrUpdateUser() {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username and Password cannot be empty')),
      );
      return;
    }

    final user = {
      "password": password,
      "current_location": {
        "latitude": "",
        "longitude": "",
        "timestamp": ""
      }
    };

    if (_editingUserId == null) {
      _usersRef.child(username).set(user);
    } else {
      _usersRef.child(_editingUserId!).update(user);
    }

    _usernameController.clear();
    _passwordController.clear();
    setState(() {
      _editingUserId = null;
    });
  }

  void _editUser(String userId, Map user) {
    _usernameController.text = userId;
    _passwordController.text = user["password"];
    setState(() {
      _editingUserId = userId;
    });
  }

  void _deleteUser(String userId) {
    _usersRef.child(userId).remove();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users Management")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addOrUpdateUser,
                  child: Text(_editingUserId == null ? "Add User" : "Update User"),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _usersRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No users found."));
                }
                Map<dynamic, dynamic> users = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                return ListView(
                  children: users.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text("Password: ${entry.value["password"]}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.green),
                            onPressed: () => _editUser(entry.key, entry.value),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(entry.key),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
