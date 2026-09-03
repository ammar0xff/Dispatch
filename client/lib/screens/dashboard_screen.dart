import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final String user;

  const DashboardScreen({Key? key, required this.user}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  List<Map<String, dynamic>> undoneTasks = [];
  List<Map<String, dynamic>> doneTasks = [];
  LatLng? currentLocation;
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await _fetchTasks();
      await _fetchCurrentLocation();
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');

      if (username != null) {
        final tasksRef = FirebaseDatabase.instance.ref("users/$username/tasks");
        final event = await tasksRef.once();

        if (event.snapshot.value != null) {
          final rawTasks = Map<String, dynamic>.from(event.snapshot.value as Map);
          setState(() {
            undoneTasks = rawTasks.values.where((task) => task['done'] == false).map((task) => Map<String, dynamic>.from(task)).toList();
            doneTasks = rawTasks.values.where((task) => task['done'] == true).map((task) => Map<String, dynamic>.from(task)).toList();
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');

      if (username != null) {
        final locationRef = FirebaseDatabase.instance.ref("users/$username/current_location");
        final event = await locationRef.once();

        if (event.snapshot.value != null) {
          final location = Map<String, dynamic>.from(event.snapshot.value as Map);
          setState(() {
            currentLocation = LatLng(location['latitude'], location['longitude']);
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to fetch location: $e');
    }
  }

  void _onRefresh() async {
    await _fetchData();
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (currentLocation != null) _buildMap(),
          const SizedBox(height: 16),
          _buildTaskSection('Undone Tasks', undoneTasks, Icons.check_box_outline_blank),
          const SizedBox(height: 16),
          _buildTaskSection('Done Tasks', doneTasks, Icons.check_box),
          const SizedBox(height: 16),
          _buildSummarySection(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: currentLocation!,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: currentLocation!,
                child: Icon(Icons.location_pin, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSection(String title, List<Map<String, dynamic>> tasks, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...tasks.map((task) => Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
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
            trailing: Icon(icon, color: Colors.blue),
          ),
        )),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSummaryItem('Total Tasks', undoneTasks.length + doneTasks.length),
            _buildSummaryItem('Undone Tasks', undoneTasks.length),
            _buildSummaryItem('Done Tasks', doneTasks.length),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}