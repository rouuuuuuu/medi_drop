import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a new product
  Future<void> addProduct({
    required String name,
    required String description,
    required double price,
    required int quantity,
    required String imageURL,
    required String category,
  }) async {
    await _db.collection('products').add({
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'imageURL': imageURL,
      'category': category,
    });
  }

  // Fetch all products
  Stream<List<Map<String, dynamic>>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}
