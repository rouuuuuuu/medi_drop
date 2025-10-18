import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'login.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  User? _user;
  File? _imageFile;
  bool _isLoading = false;
  String _userName = "Loading...";
  String? _photoURL;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_user != null) {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'] ?? "No Name";
          _photoURL = userDoc['photoURL'];
        });
      }
    }
  }
  Future<void> _updateName() async {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Name"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String newName = nameController.text.trim();

              print("Entered Name: '$newName'");

              if (newName.isEmpty) {
                print("Name is empty or just whitespace!");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid name')),
                );
                Navigator.pop(context);
                return; // Exit early if name is empty
              }

              // Check if user is authenticated
              _user = FirebaseAuth.instance.currentUser; // Ensure it's updated

              if (_user == null) {
                print("User is null!");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You need to log in first')),
                );
                Navigator.pop(context);
                return; // Exit if _user is null
              }

              try {
                // Firestore update
                await _firestore.collection('users').doc(_user!.uid).update({
                  'name': newName,
                });

                // Firebase Auth update
                await _user!.updateDisplayName(newName);

                setState(() {
                  _userName = newName;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name updated!')),
                );
                Navigator.pop(context); // Close the dialog
              } catch (e) {
                print("Error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }





  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
      await _uploadImage();
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null || _user == null) return;
    setState(() => _isLoading = true);
    try {
      final ref = _storage.ref().child('profile_pictures/${_user!.uid}.jpg');
      await ref.putFile(_imageFile!);
      String imageUrl = await ref.getDownloadURL();
      await _firestore.collection('users').doc(_user!.uid).update({
        'photoURL': imageUrl,
      });
      await _user!.updatePhotoURL(imageUrl);
      setState(() => _photoURL = imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_user != null && _user!.email != null) {
      try {
        await _auth.sendPasswordResetEmail(email: _user!.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _logOut(BuildContext context) async {
    final shouldLogOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Log Out"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text("Yes"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldLogOut == true) {
      await _auth.signOut();
      // ignore: use_build_context_synchronously
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Login()),
            (route) => false,
      );
    }
  }



  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final _passwordController = TextEditingController(); // Controller for the password text field
      final _formKey = GlobalKey<FormState>(); // Key for the form

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Enter Your Password to Confirm Deletion"),
            content: Form(
              key: _formKey,
              child: TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  hintText: "Enter your password",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Password is required";
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text("Confirm"),
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    // If the password is valid, let's authenticate
                    try {
                      // Reauthenticate user with the entered password
                      final creds = EmailAuthProvider.credential(
                        email: user.email!,
                        password: _passwordController.text,
                      );

                      await user.reauthenticateWithCredential(creds);

                      // Now proceed with account deletion
                      await user.delete();

                      // Ignore: use_build_context_synchronously
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => Login()),
                            (route) => false,
                      );
                    } catch (e) {
                      // Show error message if something goes wrong
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to delete account: $e")),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Account'),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.purple[50], // Soft purple background
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 12,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.deepPurple[100],
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_photoURL != null && _photoURL!.isNotEmpty)
                              ? NetworkImage(_photoURL!)
                              : const AssetImage('assets/default_profile.png') as ImageProvider,
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.deepPurple),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (_) => Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo),
                                    title: const Text("Choose from gallery"),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImageFromGallery();
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text("Take a photo"),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _takePhoto();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _userName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: _updateName,
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Name"),
                    ),
                    const Divider(height: 40, thickness: 1.5),
                    ElevatedButton.icon(
                      onPressed: _resetPassword,
                      icon: const Icon(Icons.lock_reset, color: Colors.white), // White icon
                      label: const Text(
                        "Reset Password",
                        style: TextStyle(color: Colors.white), // White text
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple, // Soft purple background
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16, color: Colors.black), // White text
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () => _logOut(context),
                      label: const Text(
                        "Log Out",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Red background for logout
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16, color: Colors.black),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _deleteAccount(context),
                      icon: const Icon(Icons.delete, color: Colors.white), // White icon
                      label: const Text(
                        "Delete Account",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Black background for delete
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16, color: Colors.black),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading) const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
