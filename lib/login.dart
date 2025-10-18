import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'privacy settings.dart';
import 'sign up.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _isObscure = true;
  String? _lastEmail;

  @override
  void initState() {
    super.initState();
    _loadLastUser();
  }

  Future<void> _loadLastUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastEmail = prefs.getString('lastEmail') ?? '';
      emailController.text = _lastEmail ?? '';
    });
  }

  Future<void> signIn() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackBar('Please enter email and password');
      return;
    }

    setState(() => isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());

      await _saveLastUser(emailController.text.trim());
      await storeUserData(userCredential.user);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format.';
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar('Unexpected error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF007A3D), // Medidrop Green
      ),
    );
  }

  Future<void> _saveLastUser(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastEmail', email);
  }

  Future<void> storeUserData(User? user) async {
    if (user == null) return;
    try {
      final userDoc =
      FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDoc.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? "No Name",
        'photoURL': user.photoURL ?? "",
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _showSnackBar('Error storing user data: $e');
    }
  }

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
        backgroundColor: const Color(0xFF007A3D),
      ),
      backgroundColor: const Color(0xFFF5F5F5), // Light Gray
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('image/img.png',
                  width: MediaQuery.of(context).size.width * 0.6),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                decoration: _inputDecoration('Email'),
                style: const TextStyle(fontFamily: 'Lato'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: _isObscure,
                decoration: _inputDecoration('Password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                ),
                style: const TextStyle(fontFamily: 'Lato'),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A3D), // Medidrop Green
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Merriweather',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Sign In',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(fontFamily: 'Lato'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUp()),
                      );
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF007AFF), // Accent Blue
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lato',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Lato'),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF007A3D), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF007A3D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF007A3D), width: 2),
      ),
    );
  }
}
