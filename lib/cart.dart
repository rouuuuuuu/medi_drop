import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For encoding and decoding data

// Payment Page
class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expirationDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Function to validate the card details
  bool _validatePaymentDetails() {
    return _formKey.currentState?.validate() ?? false;
  }

  // Function to show the date picker and set expiration date
  Future<void> _selectExpirationDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != DateTime.now()) {
      setState(() {
        // Format the date as MM/YY and set it to the controller
        _expirationDateController.text = '${picked.month.toString().padLeft(2, '0')}/${picked.year.toString().substring(2)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF007A3D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Back arrow
          onPressed: () {
            Navigator.pop(context); // Pop the current screen to go back
          },
        ),
        title: const Text(
          'Payment',
          style: TextStyle(color: Colors.white), // White text for the title
        ),
        ),


      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: 'Enter your card number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your card number';
                  }
                  if (value.length != 16) {
                    return 'Card number must be 16 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _expirationDateController,
                      decoration: const InputDecoration(
                        labelText: 'Expiration Date',
                        hintText: 'MM/YY',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter expiration date';
                        }
                        if (value.length != 5 || !value.contains('/')) {
                          return 'Enter a valid expiration date (MM/YY)';
                        }
                        return null;
                      },
                      onTap: () {
                        FocusScope.of(context).requestFocus(FocusNode()); // Dismiss the keyboard
                        _selectExpirationDate(context); // Open the date picker
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: 'Enter CVV',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter CVV';
                        }
                        if (value.length != 3) {
                          return 'CVV must be 3 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name on Card',
                  hintText: 'Enter the name on your card',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the name on the card';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_validatePaymentDetails()) {
                    // Proceed with payment processing (this could be an API call, etc.)
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Payment Successful"),
                        content: const Text("Your payment has been processed."),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pop(context); // Go back to cart or previous page
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007A3D),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Cart Page with Checkout Button
class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;

  const CartPage({Key? key, required this.cart}) : super(key: key); // Receiving the cart parameter

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late List<Map<String, dynamic>> cart;

  @override
  void initState() {
    super.initState();
    cart = widget.cart.isEmpty ? [] : widget.cart; // Use passed cart if available
    if (cart.isEmpty) {
      _loadCart(); // Load from SharedPreferences if cart is empty
    }
  }

  // Load cart items from SharedPreferences
  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = prefs.getString('cart');
    if (cartData != null) {
      final List<dynamic> cartList = json.decode(cartData);
      setState(() {
        cart = cartList.map((item) => Map<String, dynamic>.from(item)).toList();
      });
    }
  }

  // Save cart items to SharedPreferences
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = json.encode(cart);
    await prefs.setString('cart', cartData);
  }

  // Remove item from cart
  void _removeItem(int index) {
    setState(() {
      cart.removeAt(index);
      _saveCart(); // Save the updated cart after removal
    });
  }

  double get _totalPrice {
    return cart.fold(
      0.0,
          (sum, item) => sum + (item['price'] as num?)!.toDouble() ?? 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF007A3D),
        title: const Text(
          'Cart',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: cart.isEmpty
          ? const Center(
        child: Text(
          '🛒 Your cart is empty...',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: cart.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = cart[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['image url'] ?? '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported),
                ),
              ),
              title: Text(item['name'] ?? 'Unnamed Item'),
              subtitle: Text("${item['price']} TND"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeItem(index),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: cart.isNotEmpty
          ? Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total: ${_totalPrice.toStringAsFixed(2)} TND",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A3D),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                // Navigate to PaymentPage for processing
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentPage(),
                  ),
                );
              },
              child: const Text(
                'Checkout',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      )
          : null,
    );
  }
}
