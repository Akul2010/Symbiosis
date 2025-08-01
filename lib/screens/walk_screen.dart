import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalkScreen extends StatefulWidget {
  const WalkScreen({super.key});

  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen> {
  String _status = "Requesting permissions...";
  bool _tracking = false;
  Position? _lastPosition;
  int _steps = 0;
  late Stream<StepCount> _stepCountStream;

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
    bool activityGranted = await _requestPermission(Permission.activityRecognition);
    if (!locationGranted || !activityGranted) {
      setState(() => _status = "Required permissions not granted.");
      return;
    }
    setState(() => _status = "Permissions granted. Ready to start walking.");
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) return true;
    final result = await permission.request();
    return result.isGranted;
  }

  void _startTracking() async {
    setState(() {
      _tracking = true;
      _status = "Tracking walking activity...";
      _steps = 0;
      _taskCompleted = false;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lastPosition = position;
        _status = "Location: (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})\nSteps: $_steps";
      });
    } catch (e) {
      setState(() => _status = "Error getting location: $e");
    }

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount).onError((error) {
      setState(() => _status = "Step Count Error: $error");
    });
  }

  void _onStepCount(StepCount event) {
    if (!_tracking) return;
    setState(() {
      _steps = event.steps;
      _status = "Steps taken: $_steps\nLocation: (${_lastPosition?.latitude.toStringAsFixed(4) ?? '-'}, ${_lastPosition?.longitude.toStringAsFixed(4) ?? '-'})";
    });
  }

  void _stopTracking() {
    setState(() {
      _tracking = false;
      _status = "Tracking stopped. Total steps: $_steps";
      _taskCompleted = true;
    });
  }

  void _completeTask() {
    if (!_taskCompleted) return;
    setState(() {
      _climateCoinBalance += 10; // Award 10 ClimateCoins for walk
      _taskCompleted = false; // Disable complete button after reward
      _status = "Task completed! You earned 10 ClimateCoins.";
    });
    _saveClimateCoins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Walk Task"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.directions_walk, size: 120, color: Colors.green[600]),
            const SizedBox(height: 20),
            Text(
              "Steps",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
            const SizedBox(height: 10),
            Text(
              '$_steps',
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
                label: Text(_tracking ? "Stop Walking" : "Start Walking"),
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
