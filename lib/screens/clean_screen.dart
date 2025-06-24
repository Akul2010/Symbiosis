import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CleanScreen extends StatefulWidget {
  const CleanScreen({super.key});

  @override
  State<CleanScreen> createState() => _CleanScreenState();
}

class _CleanScreenState extends State<CleanScreen> {
  String _status = "Requesting permissions...";
  bool _tracking = false;
  Position? _startPosition;
  DateTime? _startTime;
  Position? _currentPosition;
  File? _image;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    bool locationGranted = await _requestPermission(Permission.locationWhenInUse);
    bool cameraGranted = await _requestPermission(Permission.camera);
    if (!locationGranted || !cameraGranted) {
      setState(() => _status = "Required permissions not granted.");
      return;
    }
    setState(() => _status = "Permissions granted. Ready to start cleanup.");
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) return true;
    final result = await permission.request();
    return result.isGranted;
  }

  void _startTracking() async {
    setState(() {
      _tracking = true;
      _status = "Tracking cleanup activity...";
      _startPosition = null;
      _startTime = DateTime.now();
      _image = null;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _startPosition = position;
        _currentPosition = position;
        _status = "Started at (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})";
      });
    } catch (e) {
      setState(() => _status = "Error getting location: $e");
    }

    Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5))
        .listen((Position position) {
      if (!_tracking) return;
      setState(() {
        _currentPosition = position;
        _status = "Cleaning in progress at (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})";
      });
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _stopTracking() {
    if (_startPosition == null || _startTime == null) {
      setState(() {
        _tracking = false;
        _status = "Cleanup stopped, but no start data recorded.";
      });
      return;
    }

    final timeElapsed = DateTime.now().difference(_startTime!);
    double distance = 0;

    if (_currentPosition != null) {
      distance = Geolocator.distanceBetween(
        _startPosition!.latitude,
        _startPosition!.longitude,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }

    // Validation: At least 10 minutes and moved at least 10 meters, and photo taken
    bool validCleanup = timeElapsed.inMinutes >= 10 && distance >= 10 && _image != null;

    setState(() {
      _tracking = false;
      _status = validCleanup
          ? "Cleanup verified!\nTime: ${timeElapsed.inMinutes} min\nDistance: ${distance.toStringAsFixed(1)} m\nPhoto Uploaded"
          : "Cleanup incomplete.\nEnsure you moved enough, spent time cleaning, and uploaded a photo.";
    });

    _startPosition = null;
    _startTime = null;
    _currentPosition = null;
    if (!validCleanup) _image = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Clean Task"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.cleaning_services_outlined, size: 120, color: Colors.green[600]),
            const SizedBox(height: 20),
            Text(
              "Cleanup Task",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
            ),
            const SizedBox(height: 12),
            Text(_status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 250, fit: BoxFit.cover),
              ),

            const SizedBox(height: 20),
            if (_tracking)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Take Photo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Upload Photo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[400],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(_tracking ? Icons.stop : Icons.play_arrow),
                label: Text(_tracking ? "Stop Cleanup" : "Start Cleanup"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tracking ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _tracking ? _stopTracking : _startTracking,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
