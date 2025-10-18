import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase/supabase.dart';  // Add Supabase package

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client; // Supabase instance

  File? _imageFile;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload Profile Picture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a profile picture!')));
      return;
    }

    setState(() => _isLoading = true);

    // Upload image to Supabase storage
    final imageName = '${DateTime.now().millisecondsSinceEpoch}.png';  // Unique name for image
    final file = _imageFile!;
    final bucketName = 'profilepictures';

    final response = await supabase.storage.from(bucketName).upload(imageName, file);

    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: ${response.error!.message}')));
      setState(() => _isLoading = false);
      return;
    }

    // Get public URL of the uploaded image
    final imageUrl = supabase.storage.from(bucketName).getPublicUrl(imageName);

    // Ensure imageUrl is valid
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get image URL')));
      setState(() => _isLoading = false);
      return;
    }

    String? error = await _authService.signUp(
      nameController.text.trim(),
      emailController.text.trim(),
      passwordController.text.trim(),
      imageUrl as File?, // Pass the image URL to backend
    );

    if (error == null) {
      final username = await _authService.getCurrentUsername();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome, $username!')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sign Up',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF007A3D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),
              GestureDetector(
                onTap: _showImageSourceOptions,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                  child: _imageFile == null
                      ? const Icon(Icons.add_a_photo, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo),
                    label: const Text("Gallery"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera),
                    label: const Text("Camera"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: nameController, decoration: _inputDecoration('Name')),
              const SizedBox(height: 20),
              TextField(controller: emailController, decoration: _inputDecoration('Email')),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _inputDecoration('Password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: _inputDecoration('Confirm Password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildButton('Sign Up', _signUp),
              if (_isLoading) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
  );

  Widget _buildButton(String text, VoidCallback onPressed) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007A3D)),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    ),
  );
}

extension on String {
  get error => null;
}
