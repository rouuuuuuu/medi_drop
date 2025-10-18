import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'login.dart';
import 'settings.dart';

class PrivacySettings extends StatefulWidget {
  const PrivacySettings({super.key});

  @override
  _PrivacySettingsState createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettings> {
  String lastUsername = '';
  String lastEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lastUsername = prefs.getString('lastUsername') ?? '';
      lastEmail = prefs.getString('lastEmail') ?? '';
    });
  }

  Widget _styledButton({required String label, required void Function() onPressed, Color? color}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor:  const Color(0xFF007A3D),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF007A3D),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(height: 80),

                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    lastUsername.isNotEmpty
                                        ? 'Welcome $lastUsername to'
                                        : 'Welcome Guest to',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Image.asset(
                                    'image/img2.png',
                                    width: MediaQuery.of(context).size.width * 0.8,
                                    height: 300,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 30),
                                  if (lastUsername.isNotEmpty && lastEmail.isNotEmpty)
                                    Column(
                                      children: [
                                        Text(
                                          'Do you want to continue as\n$lastEmail?',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 30),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _styledButton(
                                              label: 'Continue',
                                              onPressed: () {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => MainScreen()),
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 20),
                                            _styledButton(
                                              label: 'Change account',
                                              onPressed: () {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => const Login()),
                                                );
                                              },
                                              color: const Color(0xFF209A73),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        const Text(
                                          'You are not logged in 🕵️‍♀️',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _styledButton(
                                          label: 'Go to Login',
                                          onPressed: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(builder: (context) => const Login()),
                                            );
                                          },
                                          color: const Color(0xFF209A73),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bottom Button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsPage()),
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF007A3D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Privacy Settings'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
