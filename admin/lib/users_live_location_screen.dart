import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';

class UsersLiveLocationScreen extends StatefulWidget {
  @override
  _UsersLiveLocationScreenState createState() => _UsersLiveLocationScreenState();
}

class _UsersLiveLocationScreenState extends State<UsersLiveLocationScreen> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("users");
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  LatLngBounds? _bounds;
  double _currentZoom = 20.0;
  String _mapType = 'streets';
  bool _isLoading = true;
  bool _isUpdating = false;
  Key _mapKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _fetchLiveLocations();
  }

  void _fetchLiveLocations() {
    _usersRef.onValue.listen((event) {
      try {
        setState(() => _isUpdating = true);

        if (event.snapshot.value == null) {
          setState(() {
            _markers.clear();
            _isLoading = false;
            _isUpdating = false;
          });
          return;
        }

        final users = Map<String, dynamic>.from(event.snapshot.value as Map);
        final markers = <Marker>[];
        LatLngBounds? bounds;

        users.forEach((key, value) {
          try {
            if (value["current_location"] == null) return;

            final location = value["current_location"];

            final double? lat = location["latitude"] is double
                ? location["latitude"]
                : double.tryParse(location["latitude"].toString());

            final double? lng = location["longitude"] is double
                ? location["longitude"]
                : double.tryParse(location["longitude"].toString());

            if (lat != null && lng != null) {
              final point = LatLng(lat, lng);
              markers.add(
                Marker(
                  point: point,
                  width: 80.0,
                  height: 80.0,
                  child: Column(
                    children: [
                      Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                      Container(
                        padding: EdgeInsets.all(2),
                        color: Colors.white,
                        child: Text(
                          key,
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (bounds == null) {
                bounds = LatLngBounds(point, point);
              } else {
                bounds!.extend(point); // Fix: Modify bounds in place
              }
            }
          } catch (e) {
            print("Error parsing location for user $key: $e");
          }
        });

        setState(() {
          _markers = markers;
          _bounds = bounds;
          _isLoading = false;
          _isUpdating = false;
        });

        // Remove this block to prevent camera updates
        // if (bounds != null) {
        //   _mapController.move(
        //     bounds!.center,
        //     _mapController.camera.zoom, // Use current zoom or adjust as needed
        //   );
        // }
      } catch (e) {
        print("Error fetching live locations: $e");
        setState(() {
          _isLoading = false;
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch live locations: $e")),
        );
      }
    });
  }

  void _onMapTypeChanged(String? value) {
    setState(() {
      _mapType = value!;
      _mapKey = UniqueKey(); // Force FlutterMap to rebuild
    });
  }

  void _onZoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(1.0, 18.0);
      _mapController.move(_mapController.camera.center, _currentZoom); // Use camera.center
    });
  }

  void _onZoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(1.0, 18.0);
      _mapController.move(_mapController.camera.center, _currentZoom); // Use camera.center
    });
  }

  void _resetMapView() {
    if (_bounds != null) {
      _mapController.move(
        _bounds!.center,
        _mapController.camera.zoom, // Use current zoom or adjust as needed
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users Live Location")),
      body: Stack(
        children: [
          FlutterMap(
            key: _mapKey,
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _bounds?.center ?? LatLng(31.418071, 31.814335), // Default location
              initialZoom: _currentZoom,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _currentZoom = position.zoom; // Sync zoom level with state
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _mapType == 'streets'
                    ? "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                    : "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
          if (_isLoading)
            Center(child: CircularProgressIndicator()),
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _onZoomIn,
                  tooltip: 'Zoom In',
                  child: Icon(Icons.zoom_in),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _onZoomOut,
                  tooltip: 'Zoom Out',
                  child: Icon(Icons.zoom_out),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _resetMapView,
                  tooltip: 'Reset View',
                  child: Icon(Icons.center_focus_strong),
                ),
              ],
            ),
          ),
          if (_isUpdating)
            Positioned(
              bottom: 10,
              right: 10,
              child: CircularProgressIndicator(),
            ),
          Positioned(
            top: 10,
            left: 10,
            child: DropdownButton<String>(
              value: _mapType,
              items: [
                DropdownMenuItem(
                  value: 'streets',
                  child: Text('Streets'),
                ),
                DropdownMenuItem(
                  value: 'topo',
                  child: Text('Topographic'),
                ),
              ],
              onChanged: _onMapTypeChanged,
            ),
          ),
        ],
      ),
    );
  }
}
