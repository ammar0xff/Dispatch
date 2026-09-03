import 'package:firebase_database/firebase_database.dart';

class UserManager {
  static Future<void> addUser(String username, String password) async {
    DatabaseReference usersRef = FirebaseDatabase.instance.ref("users");
    await usersRef.child(username).set({"password": password});
  }
}
