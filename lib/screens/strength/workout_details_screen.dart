import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/workout_record_model.dart';

class WorkoutDetailsScreen extends StatelessWidget {
  final WorkoutRecordModel record;

  const WorkoutDetailsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(record.workoutPlanName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(record.date),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${record.durationMinutes} mins',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.repeat, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${record.totalActualReps} / ${record.totalTargetReps} reps',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.percent, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${record.overallCompletionPercent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: record.overallCompletionPercent >= 80 ? Colors.green : Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Logged Exercises',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...record.exerciseRecords.map(
              (ex) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ex.exerciseName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Target: ${ex.targetSets}x${ex.targetReps}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      if (ex.actualSets.isEmpty)
                        Text('No sets logged', style: TextStyle(color: Colors.grey[500]))
                      else
                        ...ex.actualSets.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final set = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.grey[200],
                                  child: Text(
                                    '${idx + 1}',
                                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${set.reps} reps',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                if (set.weight > 0)
                                  Text(
                                    ' @ ${set.weight} kg',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
