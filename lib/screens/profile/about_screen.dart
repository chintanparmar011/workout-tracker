import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About OmniFit')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // App Logo / Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'OmniFit',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // What it provides Card
          const Text(
            'What OmniFit Provides',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _FeatureBullet(
                    icon: Icons.restaurant_menu,
                    title: 'Smart Nutrition & Macro Tracking',
                    subtitle:
                        'Search foods, log your meals, and monitor calories and macros against personalized targets.',
                  ),
                  SizedBox(height: 14),
                  _FeatureBullet(
                    icon: Icons.fitness_center,
                    title: 'Guided Strength Workouts',
                    subtitle:
                        'Access tailored workout plans, track sets & reps in real-time, and build lasting strength.',
                  ),
                  SizedBox(height: 14),
                  _FeatureBullet(
                    icon: Icons.show_chart,
                    title: 'Progress & Weight Journey',
                    subtitle:
                        'Visualize your body weight curve over time and track overall workout completion stats.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // How to use Card
          const Text(
            'How to Use',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _StepBullet(
                    step: '1',
                    text:
                        'Set up your fitness goals and available workout days in your profile.',
                  ),
                  SizedBox(height: 10),
                  _StepBullet(
                    step: '2',
                    text:
                        'Log your meals daily under the Nutrition tab to stay on top of your macros.',
                  ),
                  SizedBox(height: 10),
                  _StepBullet(
                    step: '3',
                    text:
                        'Start workouts from the Strength tab, log your sets, and watch your progress grow!',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Developer Contact Card
          const Text(
            'Connect with Developer',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.deepOrange.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Have feedback, questions, or found a bug? Reach out directly!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                        const ClipboardData(text: 'ischintan223@gmail.com'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Developer email copied to clipboard: ischintan223@gmail.com',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.deepOrange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.email_outlined,
                            color: Colors.deepOrange,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'ischintan223@gmail.com',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.copy, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to copy email address',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureBullet({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepOrange, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepBullet extends StatelessWidget {
  final String step;
  final String text;

  const _StepBullet({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.deepOrange,
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[800], fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
