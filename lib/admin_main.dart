import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAUCDCm359APKlONvZpx1QSNewVoMGsp-o",
      authDomain: "schoolsupplystore.firebaseapp.com",
      projectId: "schoolsupplystore",
      storageBucket: "schoolsupplystore.firebasestorage.app",
      messagingSenderId: "109894877592",
      appId: "1:109894877592:web:a21cae0165da5594f6027d",
    ),
  );
  runApp(const AdminDashboardApp());
}

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Supply Web Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AdminAuthGate(),
    );
  }
}

// ----------------- ADMIN AUTH GATE -----------------
class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

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

        if (!snapshot.hasData) {
          return const AdminLoginScreen();
        }

        // Check if the logged-in user has an 'admin' role in Firestore
        final user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              final role = userData['role'] ?? 'user';

              if (role == 'admin') {
                return const AdminHomeScreen();
              }
            }

            // If not an admin, block access and sign out
            FirebaseAuth.instance.signOut();
            return const AdminLoginScreen(
              errorMessage: 'Access Denied: This account does not have admin privileges.',
            );
          },
        );
      },
    );
  }
}

// ----------------- ADMIN LOGIN SCREEN -----------------
class AdminLoginScreen extends StatefulWidget {
  final String? errorMessage;
  const AdminLoginScreen({super.key, this.errorMessage});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.errorMessage;
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      setState(() => _error = 'Login Failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Web Admin Portal',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade50,
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Admin Email', border: OutlineInputBorder()),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _login,
                      child: const Text('Login to Dashboard', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- ADMIN HOME SCREEN (NAVIGATION RAIL) -----------------
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _adminPages = const [
    ProductsManagementView(),
    OrdersManagementView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            elevation: 2,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2),
                selectedIcon: Icon(Icons.inventory_2, color: Colors.blue),
                label: Text('Products'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long),
                selectedIcon: Icon(Icons.receipt_long, color: Colors.blue),
                label: Text('Orders'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    tooltip: 'Logout Admin',
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _adminPages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

// ----------------- PRODUCTS MANAGEMENT VIEW (WEB) -----------------
class ProductsManagementView extends StatefulWidget {
  const ProductsManagementView({super.key});

  @override
  State<ProductsManagementView> createState() => _ProductsManagementViewState();
}

class _ProductsManagementViewState extends State<ProductsManagementView> {
  final CollectionReference _productsRef = FirebaseFirestore.instance.collection('products');

  final List<String> _categories = [
    'Writing Instruments',
    'Paper & Notebooks',
    'Art Supplies',
    'Desk Accessories',
    'Calculators & Electronics'
  ];

  void _showProductDialog({DocumentSnapshot? doc}) {
    final nameController = TextEditingController(text: doc != null ? doc['productName'] : '');
    final priceController = TextEditingController(text: doc != null ? doc['productPrice'].toString() : '');
    final stockController = TextEditingController(text: doc != null ? doc['stock'].toString() : '');
    final imageController = TextEditingController(text: doc != null ? doc['imageUrl'] : '');
    final descController = TextEditingController(text: doc != null ? doc['description'] : '');
    
    String selectedCategory = doc != null && _categories.contains(doc['category']) 
        ? doc['category'] 
        : _categories.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(doc == null ? 'Add New Product' : 'Edit Product'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price (₱)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: stockController,
                    decoration: const InputDecoration(labelText: 'Stock Quantity', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageController,
                    decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                final stock = int.tryParse(stockController.text.trim()) ?? 0;
                final imageUrl = imageController.text.trim();
                final description = descController.text.trim();

                if (name.isEmpty) return;

                final productData = {
                  'productName': name,
                  'category': selectedCategory,
                  'productPrice': price,
                  'stock': stock,
                  'imageUrl': imageUrl,
                  'description': description,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (doc == null) {
                  productData['createdAt'] = FieldValue.serverTimestamp();
                  await _productsRef.add(productData);
                } else {
                  await _productsRef.doc(doc.id).update(productData);
                }

                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: Text(doc == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Product Inventory Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                onPressed: () => _showProductDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _productsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No products found in inventory.'));
                }

                final docs = snapshot.data!.docs;

                return Card(
                  elevation: 2,
                  child: ListView(
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Product Name')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Stock')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DataRow(cells: [
                            DataCell(Text(data['productName'] ?? '')),
                            DataCell(Text(data['category'] ?? 'General')),
                            DataCell(Text('₱${data['productPrice'] ?? 0}')),
                            DataCell(Text('${data['stock'] ?? 0}')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showProductDialog(doc: doc),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteProduct(doc.id),
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- ORDERS MANAGEMENT VIEW (WEB) -----------------
class OrdersManagementView extends StatelessWidget {
  const OrdersManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersRef = FirebaseFirestore.instance.collection('orders');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Order Fulfillment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ordersRef.orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No customer orders found.'));
                }

                final orderDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: orderDocs.length,
                  itemBuilder: (context, index) {
                    final doc = orderDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'Pending';
                    final items = data['items'] as List<dynamic>? ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        title: Text(
                          'Order #${doc.id.substring(0, 8).toUpperCase()} • ${data['userEmail'] ?? 'Customer'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Total: ₱${data['total'] ?? 0.0} • Status: $status'),
                        trailing: DropdownButton<String>(
                          value: status,
                          items: ['Pending', 'Processing', 'Completed', 'Cancelled']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (newStatus) async {
                            if (newStatus != null) {
                              await ordersRef.doc(doc.id).update({'status': newStatus});
                            }
                          },
                        ),
                        children: items.map<Widget>((item) {
                          return ListTile(
                            dense: true,
                            title: Text(item['productName'] ?? 'Item'),
                            subtitle: Text('Category: ${item['category'] ?? 'General'}'),
                            trailing: Text('₱${item['productPrice']} x ${item['quantity'] ?? 1}'),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}