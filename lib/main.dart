import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'privacy settings.dart'; // Make sure the file name matches exactly

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: "https://etpmmllywawevrmzdckk.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0cG1tbGx5d2F3ZXZybXpkY2trIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUyNzAwNDQsImV4cCI6MjA2MDg0NjA0NH0.bkGkbB7hkyhbaVqCQQYRYnqXLTYa3L6lnarp_7kZHBo",
  );

  // Now run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const PrivacySettings(), // Set PrivacySettingsScreen as the main page
    );
  }
}
