import 'package:flutter/material.dart';

import 'privacy settings.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double luminosity = 50;
  double sound = 50;
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const PrivacySettings()),
    );
    },

    ),
          title: const Text(
            'Settings',
            style: TextStyle(color: Colors.white),
          ),

          backgroundColor: const Color(0xFF007A3D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Luminosity Setting
            Text(
              'Luminosity: ${luminosity.toInt()}%',
              style: const TextStyle(fontSize: 18),
            ),
            Slider(
              value: luminosity,
              min: 0,
              max: 100,
              divisions: 100,
              label: luminosity.round().toString(),
              onChanged: (double value) {
                setState(() {
                  luminosity = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Sound Setting
            Text(
              'Sound: ${sound.toInt()}%',
              style: const TextStyle(fontSize: 18),
            ),
            Slider(
              value: sound,
              min: 0,
              max: 100,
              divisions: 100,
              label: sound.round().toString(),
              onChanged: (double value) {
                setState(() {
                  sound = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Notifications Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Enable Notifications',
                  style: TextStyle(fontSize: 18),
                ),
                Switch(
                  value: notificationsEnabled,
                  activeColor: const Color(0xFF007A3D),
                  onChanged: (bool value) {
                    setState(() {
                      notificationsEnabled = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Save Settings Button
            ElevatedButton(
              onPressed: () {
                // Add save logic or feedback here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A3D),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
             child: const Text(
            "Save Settings",
            style: TextStyle(
              color: Color.fromARGB(255, 244, 247, 246),
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
             ),
            ),
          ],
        ),
      ),
    );
  }
}
