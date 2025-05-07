import 'package:flutter/material.dart';
import 'package:razy_mesboub_2/models/products.dart';

class ProductDetailScreen extends StatelessWidget {
  static const routeName = '/product-detail';
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final product = ModalRoute.of(context)!.settings.arguments as Product;
    final primaryColor = const Color(0xFF1E4D6B);
    final backgroundColor = const Color(0xFFF5F2ED);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context, 
              '/edit-product',
              arguments: product,
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
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
            _buildDetailCard('Reference ID', product.referenceId),
            _buildDetailCard('Quantity', product.quantity.toString()),
            _buildDetailCard('Price', '\$${product.price.toStringAsFixed(2)}'),
            _buildDetailCard('Distributor', product.distributor),
            _buildDetailCard('Category', product.category),
            _buildDetailCard('Expiry Date', product.expiryDate),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: TextStyle(color: Colors.grey[600])),
        subtitle: Text(value, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}