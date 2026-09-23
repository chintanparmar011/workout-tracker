import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityTile extends StatelessWidget {
  final String title;
  final DateTime date;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;

  const ActivityTile({
    super.key,
    required this.title,
    required this.date,
    required this.subtitle,
    required this.onTap,
    this.icon = Icons.fitness_center,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.deepOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.deepOrange),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${DateFormat('MMM d, yyyy').format(date)} • $subtitle'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
