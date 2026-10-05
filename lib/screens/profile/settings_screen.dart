import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'edit_profile_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Account & Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.person_outline,
                    color: primaryColor,
                  ),
                  title: const Text('Edit Profile'),
                  subtitle: const Text(
                    'Update name, height, age, and available workout days',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: primaryColor,
                  ),
                  title: const Text('Dark Mode (Cyber Volt)'),
                  subtitle: Text(
                    isDark
                        ? 'Matte Obsidian & Electric Lime active'
                        : 'Clean high-contrast Light Theme',
                  ),
                  value: isDark,
                  activeThumbColor: const Color(0xFFB4F000),
                  onChanged: (val) {
                    themeProvider.toggleTheme(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: primaryColor,
                  ),
                  title: const Text('About OmniFit'),
                  subtitle: const Text(
                    'App features, usage guide, and developer contact',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
