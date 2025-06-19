import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int climateCoins = 0;
  List<String> activityLog = [];
  final GlobalKey _coinTargetKey = GlobalKey();

  void _completeTask(String taskName, int coins, Offset startPosition) {
    _playCoinBurstAnimation(startPosition, coins);
    setState(() {
      climateCoins += coins;
      activityLog.add('$taskName +$coins CC');
    });
  }

  void _playCoinBurstAnimation(Offset start, int count) {
    final overlay = Overlay.of(context);
    final renderBox = _coinTargetKey.currentContext?.findRenderObject() as RenderBox?;
    if (overlay == null || renderBox == null) return;

    final size = renderBox.size;
    final end = renderBox.localToGlobal(Offset(size.width / 2, size.height / 2));

    final entries = List.generate(count, (i) {
      return OverlayEntry(
        builder: (_) => AnimatedCoin(
          start: start,
          end: end,
          delay: Duration(milliseconds: i * 50),
          vsync: this,
        ),
      );
    });

    for (var e in entries) overlay.insert(e);
    Future.delayed(Duration(milliseconds: 800 + count * 50), () {
      for (var e in entries) e.remove();
    });
  }

  void _simulateTask(String task, int reward, BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final start = box.localToGlobal(Offset(size.width / 2, size.height / 2));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$task?'),
        content: Text('Reward: $reward ClimateCoin'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeTask(task, reward, start);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
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
            _taskTile('Recycle plastic', 'Recycle used plastic materials',
                Icons.recycling, 3),
          ],
        ),
      ),
    );
  }

  Widget _taskTile(
      String title, String subtitle, IconData icon, int reward) {
    return Builder(
      builder: (context) => ListTile(
        leading: Icon(icon, color: Colors.green[700]),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: () => _simulateTask(title, reward, context),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Complete'),
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
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Positioned(
            top: _position.value.dy,
            left: _position.value.dx,
            child: Transform.scale(
              scale: _scale.value,
              child: const Icon(Icons.eco, color: Colors.green, size: 32),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
