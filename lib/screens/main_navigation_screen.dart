import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'strength/strength_screen.dart';
import 'nutrition/nutrition_screen.dart';
import 'progress/progress_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StrengthScreen(),
    const _RunningPlaceholderScreen(),
    const NutritionScreen(),
    const ProgressScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Strength',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Running',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}

class _RunningPlaceholderScreen extends StatelessWidget {
  const _RunningPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Running Activity')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                child: const Icon(Icons.directions_run, size: 48, color: Colors.blue),
              ),
              const SizedBox(height: 20),
              const Text(
                'Running & GPS Tracking',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Live GPS route drawing, distance, pace, and running history are queued for the final phase.\n\nAll Strength, Nutrition (USDA), and Progress systems are fully active.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.5, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
