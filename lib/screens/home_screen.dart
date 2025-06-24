import 'package:flutter/material.dart';
import './clean_screen.dart';
import './bike_screen.dart';
import './walk_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int climateCoins = 0;
  List<String> activityLog = [];
  final GlobalKey _coinTargetKey = GlobalKey();

  void _completeTask(String taskName, int coins) {
    // Start position is center of screen for demo, or pass from button tap if you want exact tap pos
    final overlay = Overlay.of(context);

    // For demo, just animate from center of screen
    final screenSize = MediaQuery.of(context).size;
    final startGlobal = Offset(screenSize.width / 2, screenSize.height / 2);

    final renderBox = _coinTargetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final endGlobal = renderBox.localToGlobal(Offset(size.width / 2, size.height / 2));

    final overlayRenderBox = overlay.context.findRenderObject() as RenderBox;
    final overlayOrigin = overlayRenderBox.localToGlobal(Offset.zero);

    final start = startGlobal - overlayOrigin;
    final end = endGlobal - overlayOrigin;

    final entries = List.generate(coins, (i) {
      return OverlayEntry(
        builder: (_) => AnimatedCoin(
          start: start,
          end: end,
          delay: Duration(milliseconds: i * 50),
          vsync: this,
        ),
      );
    });

    for (var entry in entries) {
      overlay.insert(entry);
    }
    Future.delayed(Duration(milliseconds: 800 + coins * 50), () {
      for (var entry in entries) {
        entry.remove();
      }
      setState(() {
        climateCoins += coins;
        activityLog.add('$taskName +$coins CC');
      });
    });
  }

  void _openTaskScreen(String taskName) async {
    int earnedCoins = 0;
    bool success = false;

    switch (taskName) {
      case 'Clean up an area':
        success = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const CleanScreen()),
            ) ??
            false;
        earnedCoins = 10;
        break;
      case 'Ride a bike':
        success = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const BikeScreen()),
            ) ??
            false;
        earnedCoins = 5;
        break;
      case 'Walk instead of driving':
        success = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const WalkScreen()),
            ) ??
            false;
        earnedCoins = 5;
        break;
    }

    if (success) {
      _completeTask(taskName, earnedCoins);
    }
  }

  Widget _taskTile(
      String title, String subtitle, IconData icon, int reward) {
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

  Widget _buildBalanceCard() {
    return Card(
      key: _coinTargetKey,
      color: Colors.green[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    style:
                        const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard() {
    return Card(
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
                Icons.cleaning_services, 10),
            _taskTile('Ride a bike', 'Replace a short car ride',
                Icons.directions_bike, 5),
            _taskTile('Walk instead of driving',
                'Use your feet instead of fuel', Icons.directions_walk, 5),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLog() {
    return Card(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                _buildBalanceCard(),
                const SizedBox(height: 20),
                _buildTaskCard(),
                const SizedBox(height: 20),
                _buildActivityLog(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AnimatedCoin extends StatefulWidget {
  final Offset start;
  final Offset end;
  final Duration delay;
  final TickerProvider vsync;

  const AnimatedCoin({
    super.key,
    required this.start,
    required this.end,
    required this.delay,
    required this.vsync,
  });

  @override
  State<AnimatedCoin> createState() => _AnimatedCoinState();
}

class _AnimatedCoinState extends State<AnimatedCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _position;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: widget.vsync,
      duration: const Duration(milliseconds: 700),
    );

    _position = Tween<Offset>(
      begin: widget.start,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scale = Tween<double>(
      begin: 1.5,
      end: 0.4,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _position.value.dy,
      left: _position.value.dx,
      child: Transform.scale(
        scale: _scale.value,
        child: const Icon(Icons.eco, color: Colors.green, size: 32),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
