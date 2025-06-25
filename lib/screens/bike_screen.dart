import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BikeScreen extends StatefulWidget {
  const BikeScreen({super.key});

  @override
  State<BikeScreen> createState() => _BikeScreenState();
}

class _BikeScreenState extends State<BikeScreen> {
  String _status = "Requesting permissions...";
  bool _tracking = false;
  Position? _lastPosition;
  double _distanceMeters = 0;
  late StreamSubscription<Position> _positionSubscription;

  int _climateCoinBalance = 0;
  bool _taskCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadClimateCoins();
    _initPermissions();
  }

  Future<void> _loadClimateCoins() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _climateCoinBalance = prefs.getInt('climateCoinBalance') ?? 0;
    });
  }

  Future<void> _saveClimateCoins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('climateCoinBalance', _climateCoinBalance);
  }

  Future<void> _initPermissions() async {
    bool locationGranted = await _requestPermission(Permission.locationWhenInUse);
    if (!locationGranted) {
      setState(() => _status = "Location permission denied.");
      return;
    }
    setState(() => _status = "Permissions granted. Ready to start biking.");
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) return true;
    final result = await permission.request();
    return result.isGranted;
  }

  void _startTracking() {
    setState(() {
      _tracking = true;
      _status = "Tracking biking activity...";
      _distanceMeters = 0;
      _lastPosition = null;
      _taskCompleted = false;
    });

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) {
      if (!_tracking) return;

      if (_lastPosition != null) {
        double speedKmh = position.speed * 3.6;
        if (speedKmh > 5) {
          double distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          setState(() {
            _distanceMeters += distance;
            _status = "Distance: ${(_distanceMeters / 1000).toStringAsFixed(2)} km\nSpeed: ${speedKmh.toStringAsFixed(1)} km/h";
          });
        } else {
          setState(() {
            _status = "Speed too low to count as biking.\nSpeed: ${speedKmh.toStringAsFixed(1)} km/h";
          });
        }
      }
      _lastPosition = position;
    });
  }

  void _stopTracking() {
    _positionSubscription.cancel();
    setState(() {
      _tracking = false;
      _status = "Tracking stopped. Total distance: ${(_distanceMeters / 1000).toStringAsFixed(2)} km";
      _taskCompleted = true;
    });
  }

  void _completeTask() {
    if (!_taskCompleted) return;
    setState(() {
      _climateCoinBalance += 15; // Award 15 ClimateCoins for biking
      _taskCompleted = false;
      _status = "Task completed! You earned 15 ClimateCoins.";
    });
    _saveClimateCoins();
  }

  @override
  void dispose() {
    if (_tracking) _positionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bike Task"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.pedal_bike, size: 120, color: Colors.green[600]),
            const SizedBox(height: 20),
            Text(
              "Distance (km)",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
            const SizedBox(height: 10),
            Text(
              (_distanceMeters / 1000).toStringAsFixed(2),
              style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.black87),
            ),
            const SizedBox(height: 30),
            Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text(
              "ClimateCoins: $_climateCoinBalance",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(_tracking ? Icons.stop : Icons.play_arrow),
                label: Text(_tracking ? "Stop Biking" : "Start Biking"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tracking ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _tracking ? _stopTracking : _startTracking,
              ),
            ),
            const SizedBox(height: 12),
            if (!_tracking && _taskCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.monetization_on),
                  label: const Text("Complete Task & Claim Coins"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _completeTask,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
