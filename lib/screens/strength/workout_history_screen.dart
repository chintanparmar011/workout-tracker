import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/activity_tile.dart';
import 'workout_details_screen.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<WorkoutProvider>().loadHistory(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: workoutProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : workoutProvider.workoutHistory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No workouts recorded yet.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: workoutProvider.workoutHistory.length,
              padding: const EdgeInsets.all(16),
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final record = workoutProvider.workoutHistory[index];
                return ActivityTile(
                  title: 'Workout session', // Should ideally fetch plan name
                  date: record.date,
                  subtitle:
                      '${record.durationMinutes} mins • ${record.exerciseRecords.length} exercises',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutDetailsScreen(record: record),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
