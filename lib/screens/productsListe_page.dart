import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:razy_mesboub_2/models/products.dart';
import 'package:razy_mesboub_2/screens/edit_products_page.dart.dart';
class ItemsList extends StatefulWidget {
  const ItemsList({super.key});

  @override
  State<ItemsList> createState() => _ItemsListState();
}

class _ItemsListState extends State<ItemsList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  final Color _primaryColor = const Color(0xFF1E4D6B);
  final Color _backgroundColor = const Color(0xFFF5F2ED);
  
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('products')
          .get();

      List<Product> products = snapshot.docs.map((doc) {
        return Product(
          referenceId: doc.id,
          name: doc['name'],
          quantity: doc['quantity'],
          price: doc['price'],
          distributor: doc['distributor'],
          category: doc['category'],
          expiryDate: doc['expiryDate'],
          imageUrl: doc['imageUrl'],
        );
      }).toList();

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load products: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete "${product.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteProduct(product);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    try {
      final updatedProducts = List<Product>.from(_products);
      updatedProducts.removeWhere((p) => p.referenceId == product.referenceId);
      
      if (mounted) {
        setState(() => _products = updatedProducts);
      }

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('products')
          .doc(product.referenceId)
          .delete();

      if (product.imageUrl.isNotEmpty) {
        await FirebaseStorage.instance
            .ref('product_images/${product.referenceId}.jpg')
            .delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${product.name}" deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _products = List.from(_products)..add(product));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text('Product List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : RefreshIndicator(
                  onRefresh: _fetchProducts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                          leading: product.imageUrl.isNotEmpty
                              ? Image.network(
                                  product.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.inventory, size: 40),
                          title: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('REF: ${product.referenceId}'),
                              Text('Qty: ${product.quantity}'),
                              Text('Exp: ${product.expiryDate}'),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: const Text('View Details'),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product),
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                child: const Text('Edit'),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProductScreen(product),
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                onTap: () => Future.delayed(
                                  Duration.zero,
                                  () => _confirmDelete(context, product),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen(this.product, {super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1E4D6B);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(product.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.imageUrl.isNotEmpty)
              Center(
                child: Image.network(
                  product.imageUrl,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 20),
            _buildDetailRow('Reference ID', product.referenceId),
            _buildDetailRow('Quantity', product.quantity.toString()),
            _buildDetailRow('Price', '\$${product.price.toStringAsFixed(2)}'),
            _buildDetailRow('Distributor', product.distributor),
            _buildDetailRow('Category', product.category),
            _buildDetailRow('Expiry Date', product.expiryDate),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}