import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SchoolSupplyApp());
}

class SchoolSupplyApp extends StatelessWidget {
  const SchoolSupplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Supply Store',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const CatalogScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// ----------------- LOGIN SCREEN -----------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login - School Supply Store')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    onPressed: _login,
                    child: const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
              },
              child: const Text("Don't have an account? Register here"),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- REGISTER SCREEN -----------------
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration Failed: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    onPressed: _register,
                    child: const Text('Register', style: TextStyle(fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }
}

// ----------------- CATALOG SCREEN WITH RESTRUCTURED APPBAR -----------------
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

  final List<Map<String, dynamic>> _cart = [];
  String _userRole = 'user';
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _userRole = doc.data()?['role'] ?? 'user';
            _isLoadingRole = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingRole = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      _cart.add({
        'productName': product['productName'],
        'productPrice': product['productPrice'],
        'category': product['category'],
        'imageUrl': product['imageUrl'],
        'isSelected': true,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['productName']} added to cart!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // Logout confirmation dialog
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout Account'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();
    final stockController = TextEditingController();
    final descController = TextEditingController();
    final imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product (Admin)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name')),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price (₱)'), keyboardType: TextInputType.number),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock Quantity'), keyboardType: TextInputType.number),
              TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Image URL (Optional)')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('products').add({
                  'productName': nameController.text.trim(),
                  'productPrice': double.tryParse(priceController.text) ?? 0.0,
                  'category': categoryController.text.trim().isEmpty ? 'General' : categoryController.text.trim(),
                  'stock': int.tryParse(stockController.text) ?? 0,
                  'imageUrl': imageController.text.trim(),
                  'description': descController.text.trim().isEmpty ? 'No description provided.' : descController.text.trim(),
                });
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product added successfully!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Supplies Catalog'),
        actions: [
          // 1. Swapped Cart to the left of the Menu button (for regular users)
          if (_userRole != 'admin')
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  tooltip: 'Shopping Cart',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CartScreen(
                          cartItems: _cart,
                          onCheckout: (selectedItems, totalAmount) async {
                            try {
                              await FirebaseFirestore.instance.collection('orders').add({
                                'userId': currentUser?.uid ?? 'guest',
                                'userEmail': currentUser?.email ?? 'unknown',
                                'items': selectedItems,
                                'total': totalAmount,
                                'status': 'Pending',
                                'timestamp': FieldValue.serverTimestamp(),
                              });

                              if (!mounted) return;

                              setState(() {
                                _cart.removeWhere((item) => selectedItems.contains(item));
                              });
                            } catch (e) {
                              debugPrint('Error saving order: $e');
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
                if (_cart.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${_cart.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),

          // 2. Replaced Logout button with a Menu popup anchor
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onSelected: (value) {
              if (value == 'logout') {
                _confirmLogout(context); // 3. Trigger confirmation popup
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  currentUser?.email ?? 'Account',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Logout Account', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _isLoadingRole || _userRole != 'admin'
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddProductDialog(context),
              backgroundColor: Colors.blue,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Product', style: TextStyle(color: Colors.white)),
            ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _productsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No products in Firestore yet.\nAdd products via admin account!',
                textAlign: TextAlign.center,
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              
              final price = data['productPrice'] ?? data['price'] ?? 0;
              final name = data['productName'] ?? data['name'] ?? 'Unnamed Product';
              final category = data['category'] ?? 'General';
              final stock = data['stock'] ?? 0;
              final imageUrl = data['imageUrl'] ?? '';
              final description = data['description'] ?? 'No description available for this item.';

              final productMap = {
                'productName': name,
                'productPrice': price,
                'category': category,
                'stock': stock,
                'imageUrl': imageUrl,
                'description': description,
              };

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        product: productMap,
                        onAddToCart: _addToCart,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                          child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50, color: Colors.grey))
                              : const Icon(Icons.inventory_2, size: 50, color: Colors.blue),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₱$price',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Stock: $stock',
                              style: TextStyle(color: Colors.grey[600], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ----------------- PRODUCT DETAIL SCREEN -----------------
class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['imageUrl'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(product['productName'])),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 280,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 80, color: Colors.grey))
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.inventory_2, size: 100, color: Colors.blue),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['productName'],
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₱${product['productPrice']}',
                          style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Chip(
                              label: Text('Category: ${product['category']}'),
                              backgroundColor: Colors.blue.shade50,
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text('Stock: ${product['stock']}'),
                              backgroundColor: Colors.green.shade50,
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        const Text(
                          'Product Description',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product['description'],
                          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, -3)),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                onAddToCart(product);
                Navigator.pop(context);
              },
              child: const Text('Add to Cart', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- CART SCREEN -----------------
class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Future<void> Function(List<Map<String, dynamic>>, double) onCheckout;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onCheckout,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    double totalAmount = widget.cartItems.fold(0.0, (acc, item) {
      if (item['isSelected'] == true) {
        final price = double.tryParse(item['productPrice'].toString()) ?? 0.0;
        return acc + price;
      }
      return acc;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('My Shopping Cart')),
      body: widget.cartItems.isEmpty
          ? const Center(
              child: Text('Your cart is empty!', style: TextStyle(fontSize: 18, color: Colors.grey)),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
                      bool isSelected = item['isSelected'] ?? true;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                item['isSelected'] = value ?? false;
                              });
                            },
                          ),
                          title: Text(item['productName'] ?? ''),
                          subtitle: Text('₱${item['productPrice']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Remove item',
                            onPressed: () {
                              setState(() {
                                widget.cartItems.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: const Border(top: BorderSide(color: Colors.grey, width: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            '₱${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: totalAmount == 0
                            ? null
                            : () async {
                                final selectedItems = widget.cartItems
                                    .where((item) => item['isSelected'] == true)
                                    .toList();

                                await widget.onCheckout(selectedItems, totalAmount);

                                if (!context.mounted) return;

                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Order Placed Successfully!'),
                                    content: Text(
                                      'Your order for ${selectedItems.length} item(s) has been saved to Firestore!',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                        child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}