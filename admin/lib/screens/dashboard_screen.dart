import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isLoading = false;
  Map<dynamic, dynamic>? _usersData;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _listenForTaskCompletion();
    _fetchData();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _listenForTaskCompletion() {
    _usersRef.onChildChanged.listen((event) {
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        Map<dynamic, dynamic> userData = event.snapshot.value as Map<dynamic, dynamic>;
        String userId = event.snapshot.key!;
        Map<dynamic, dynamic> tasks = userData['tasks'] ?? {};
        tasks.forEach((taskId, taskData) {
          if (taskData['done'] == true) {
            _showNotification(taskData['name'], userId);
          }
        });
      }
    });
  }

  void _showNotification(String taskName, String userId) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'task_channel',
      'Task Notifications',
      channelDescription: 'Channel for task notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0, // id
      'Task Completed', // title
      'Task "$taskName" assigned to $userId is completed.', // body
      platformChannelSpecifics, // notificationDetails
      payload: 'task_completed', // payload
    );
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    DatabaseEvent event = await _usersRef.once();
    setState(() {
      _usersData = event.snapshot.value as Map<dynamic, dynamic>?;
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _usersData == null
                        ? Center(child: Text("No users found."))
                        : ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Undone Tasks',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              ..._buildTaskWidgets(false),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Done Tasks',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              ..._buildTaskWidgets(true),
                            ],
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Monitoring Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildMonitoringInformation(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTaskWidgets(bool done) {
    List<Widget> taskWidgets = [];
    _usersData?.forEach((userId, userData) {
      Map<dynamic, dynamic> tasks = userData['tasks'] ?? {};
      tasks.forEach((taskId, taskData) {
        if (taskData['done'] == done) {
          taskWidgets.add(
            Card(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                title: Text(taskData['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("User: $userId\nNumber: ${taskData['number']}\nData: ${taskData['data']}"),
                trailing: done ? Icon(Icons.check_circle, color: Colors.green) : null,
              ),
            ),
          );
        }
      });
    });
    return taskWidgets;
  }

  Widget _buildMonitoringInformation() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_usersData == null) {
      return Center(child: Text("No data found."));
    }
    int totalTasks = 0;
    int undoneTasks = 0;
    _usersData?.forEach((userId, userData) {
      Map<dynamic, dynamic> tasks = userData['tasks'] ?? {};
      totalTasks += tasks.length;
      tasks.forEach((taskId, taskData) {
        if (taskData['done'] != true) {
          undoneTasks++;
        }
      });
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Total Users: ${_usersData?.length ?? 0}"),
        Text("Total Tasks: $totalTasks"),
        Text("Undone Tasks: $undoneTasks"),
      ],
    );
  }
}
