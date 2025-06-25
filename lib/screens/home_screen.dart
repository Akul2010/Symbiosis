import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // for loading history if persisted
import './clean_screen.dart';
import './bike_screen.dart';
import './walk_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int climateCoins = 0;
  List<String> activityLog = [];
  final GlobalKey _coinTargetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadClimateCoins();
    _loadActivityLog();
  }

  Future<void> _loadClimateCoins() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      climateCoins = prefs.getInt('climateCoinBalance') ?? 0;
    });
  }

  Future<void> _loadActivityLog() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      activityLog = prefs.getStringList('activityLog') ?? [];
    });
  }

  Future<void> _saveActivityLog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('activityLog', activityLog);
  }

  Future<void> _completeTask(String taskName, int coins) async {
    setState(() {
      climateCoins += coins;
      activityLog.add('$taskName +$coins CC');
    });
    await _saveActivityLog();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('climateCoinBalance', climateCoins);
  }

  Future<void> _openTaskScreen(String taskName) async {
    bool success = false;
    int earnedCoins = 0;

    switch (taskName) {
      case 'Clean up an area':
        success = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const CleanScreen()),
            ) ??
            false;
        earnedCoins = 20;
        break;
      case 'Ride a bike':
        success = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const BikeScreen()),
            ) ??
            false;
        earnedCoins = 15;
        break;
      case 'Walk instead of driving':
        success = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const WalkScreen()),
            ) ??
            false;
        earnedCoins = 10;
        break;
    }

    if (success) await _completeTask(taskName, earnedCoins);

    // Reload balance & log after returning
    await _loadClimateCoins();
    await _loadActivityLog();
  }

  Widget _taskTile(String title, String subtitle, IconData icon, int reward) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: ElevatedButton(
        onPressed: () => _openTaskScreen(title),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        child: const Text('Start'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symbiosis Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              key: _coinTargetKey,
              color: Colors.green[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('ClimateCoin Balance', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.eco, color: Colors.green, size: 30),
                        const SizedBox(width: 8),
                        Text('$climateCoins',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.green[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Eco Tasks',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _taskTile('Clean up an area', 'Pick up trash & document it',
                        Icons.cleaning_services, 20),
                    _taskTile('Ride a bike', 'Replace a short car ride',
                        Icons.directions_bike, 15),
                    _taskTile('Walk instead of driving',
                        'Use your feet instead of fuel', Icons.directions_walk, 10),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recent Activity',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (activityLog.isEmpty)
                      const Text('No activity yet.')
                    else
                      ...activityLog.reversed.take(5).map((entry) => ListTile(
                            leading: const Icon(Icons.eco, color: Colors.green),
                            title: Text(entry),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
