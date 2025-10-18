import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart.dart';
import 'account.dart';
import 'map_page.dart';
import 'privacy settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediDrop Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF209A73),
        textTheme: const TextTheme(bodyLarge: TextStyle(fontFamily: 'Roboto')),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> cart = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Updates the cart and refreshes the cart item count
  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      cart.add(product);
    });
  }

  // Handle category display
  void _showCategories() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryItem("Medicines", Icons.medical_services),
            _buildCategoryItem("Baby Products", Icons.baby_changing_station),
            _buildCategoryItem("Cosmetics", Icons.brush),
            _buildCategoryItem("Personal Care", Icons.health_and_safety),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Color(0xFF209A73))),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = title;
        });
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF209A73)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
        onAddToCart: _addToCart,
        searchQuery: _searchController.text.trim(),
        selectedCategory: _selectedCategory,
        cart: cart,  // Pass cart here to ensure the state updates
      ),
      const AccountScreen(),
      const MapPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF007A3D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacySettings()),
            );
          },
        ),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.category, color: Colors.white),
              onPressed: _showCategories,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CartPage(cart: cart), // Pass the cart here
                      ),
                    );

                  },
                ),
                if (cart.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        cart.length.toString(),
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF209A73),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final Function(Map<String, dynamic>) onAddToCart;
  final String searchQuery;
  final String selectedCategory;
  final List<Map<String, dynamic>> cart;  // Accept cart here

  const HomePage({
    super.key,
    required this.onAddToCart,
    required this.searchQuery,
    required this.selectedCategory,
    required this.cart, // Make sure the cart is passed down here
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products available'));
        }

        var products = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((product) =>
        (searchQuery.isEmpty ||
            (product['name']?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)) &&
            (selectedCategory == 'All' || product['category'] == selectedCategory))
            .toList();

        if (products.isEmpty) {
          return const Center(child: Text('No matching results'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.6,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            var product = products[index];

            return Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      product['imageUrl'] ?? '',
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, size: 100),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${product['price']} TND',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: () {
                      onAddToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${product['name']} added to cart')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF209A73),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    ),
                    child: const Text("Add to cart", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
