import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CleanScreen extends StatefulWidget {
  const CleanScreen({super.key});

  @override
  State<CleanScreen> createState() => _CleanScreenState();
}

class _CleanScreenState extends State<CleanScreen> {
  File? _image;
  bool _cleanupVerified = false;
  int _climateCoinBalance = 0;
  bool _taskCompleted = false;
  String _status = "Please upload a photo of your cleanup";

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadClimateCoins();
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

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _status = "Photo uploaded. Waiting for verification...";
        _cleanupVerified = false;
        _taskCompleted = false;
      });
      // Simulate verification delay
      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        _cleanupVerified = true;
        _status = "Cleanup verified! You can now complete the task.";
        _taskCompleted = true;
      });
    } else {
      setState(() {
        _status = "No photo selected.";
        _cleanupVerified = false;
      });
    }
  }

  void _completeTask() {
    if (!_taskCompleted || !_cleanupVerified) return;
    setState(() {
      _climateCoinBalance += 20; // Award 20 ClimateCoins for cleanup
      _taskCompleted = false;
      _status = "Task completed! You earned 20 ClimateCoins.";
    });
    _saveClimateCoins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cleanup Task"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.cleaning_services, size: 120, color: Colors.green[600]),
            const SizedBox(height: 20),
            _image != null
                ? Image.file(_image!, height: 250, fit: BoxFit.cover)
                : Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text("No photo uploaded", style: TextStyle(color: Colors.black45)),
                    ),
                  ),
            const SizedBox(height: 20),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text(
              "ClimateCoins: $_climateCoinBalance",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Upload Cleanup Photo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _pickImage,
              ),
            ),
            const SizedBox(height: 12),
            if (_cleanupVerified && _taskCompleted)
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
