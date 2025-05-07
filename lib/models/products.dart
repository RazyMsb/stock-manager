import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String referenceId;
  final String name;
  final String category;
  final int quantity;
  final double price;
  final String distributor;
  final String expiryDate;
  final String imageUrl;

  Product({
    required this.referenceId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.price,
    required this.distributor,
    required this.expiryDate,
    required this.imageUrl,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Product(
      referenceId: data['referenceId'],
      name: data['name'],
      category: data['category'],
      quantity: data['quantity'],
      price: data['price'],
      distributor: data['distributor'],
      expiryDate: data['expiryDate'],
      imageUrl: data['imageUrl'],
    );
  }

  get description => null;
}
