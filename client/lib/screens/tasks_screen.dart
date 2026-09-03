import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');

      if (username != null) {
        final tasksRef = FirebaseDatabase.instance.ref("users/$username/tasks");
        final event = await tasksRef.once();

        if (event.snapshot.value != null) {
          final rawTasks = Map<String, dynamic>.from(event.snapshot.value as Map);
          setState(() {
            tasks = rawTasks.entries.map((entry) {
              final task = Map<String, dynamic>.from(entry.value);
              task['id'] = entry.key;
              return task;
            }).toList();
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch tasks: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onRefresh() async {
    await _fetchTasks();
    _refreshController.refreshCompleted();
  }

  Future<void> _toggleTaskCompletion(String taskId, bool isDone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');

      if (username != null) {
        final taskRef = FirebaseDatabase.instance.ref("users/$username/tasks/$taskId");
        await taskRef.update({'done': !isDone});
        await _fetchTasks();
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to toggle task: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)));
    }

    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks found', style: TextStyle(fontSize: 16)));
    }

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: tasks.map((task) => _buildTaskCard(task)).toList(),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(task['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task['data'], style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text('Number: ${task['number']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Checkbox(
          value: task['done'],
          onChanged: (bool? value) {
            _toggleTaskCompletion(task['id'], task['done']);
          },
        ),
      ),
    );
  }
}