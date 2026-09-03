import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UsersManagementScreen extends StatefulWidget {
  @override
  _UsersManagementScreenState createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _addUser() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    try {
      String userId = _usersRef.push().key!;
      Map<String, dynamic> user = {
        "password": _passwordController.text,
        "current_location": {
          "latitude": 0.0, // Default latitude
          "longitude": 0.0, // Default longitude
        },
        "tasks": {},
      };

      await _usersRef.child(userId).set(user);
      _usernameController.clear();
      _passwordController.clear();
    } catch (e) {
      print("Failed to add user: $e");
    }
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users Management'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _addUser,
                  child: Text("Add User"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _usersRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return Center(child: Text("No users found."));
                    }
                    Map<dynamic, dynamic> users = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    return ListView(
                      children: users.entries.map((entry) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          child: ListTile(
                            title: Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Password: ${entry.value['password']}"),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _usersRef.child(entry.key).remove();
                              },
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
