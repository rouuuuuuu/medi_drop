import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart'; // contains `final supabase = Supabase.instance.client;`

class AuthService {
  // Sign-up with optional image upload
  Future<String?> signUp(String name, String email, String password, File? imageFile) async {
    try {
      // Step 1: Sign up the user with email and password
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) return 'User sign-up failed';

      String? imageUrl;

      // Step 2: Upload image to Supabase Storage if image is provided
      if (imageFile != null) {
        final fileExt = path.extension(imageFile.path);
        final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}$fileExt';
        final filePath = 'profile_pictures/$fileName';

        // Read the file as bytes and determine mime type
        final bytes = await imageFile.readAsBytes();
        final mimeType = lookupMimeType(imageFile.path);

        // Upload the file to Supabase Storage
        final storageResponse = await supabase.storage
            .from('profile_pictures') // Your Supabase bucket name
            .uploadBinary(filePath, bytes, fileOptions: FileOptions(
          contentType: mimeType ?? 'image/jpeg', // Set the content type
          upsert: true, // Optional: Allow overwriting existing files
        ));

        if (storageResponse.isEmpty) return 'Image upload failed';

        // Get the public URL of the uploaded image
        imageUrl = supabase.storage
            .from('profile_pictures')
            .getPublicUrl(filePath);
      }

      // Step 3: Insert user info into Supabase DB, including the image URL (if available)
      await supabase.from('users').insert({
        'id': user.id,
        'name': name,
        'email': email,
        'photo_url': imageUrl ?? '', // Save image URL (if any)
        'created_at': DateTime.now().toIso8601String(),
      });

      return null; // Success
    } catch (e) {
      print("Supabase Sign-Up Error: $e");
      return e.toString(); // Return error message
    }
  }

  // Sign-in method (unchanged)
  Future<String?> signIn(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) return "Invalid email or password";

      return "Signed in as ${user.email}";
    } catch (e) {
      print("Supabase Sign-In Error: $e");
      return e.toString(); // Return error message
    }
  }

  // Get the current user's name (optional)
  Future<String?> getCurrentUsername() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final response = await supabase
        .from('users')
        .select('name')
        .eq('id', user.id)
        .single();

    return response['name'];
  }
}
