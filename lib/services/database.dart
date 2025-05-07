import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razy_mesboub_2/models/products.dart';

class FirestoreService {
  Future<List<Product>> getProducts() async {
    final user = FirebaseAuth.instance.currentUser;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('products')
        .get();

    return snapshot.docs.map((doc) => Product(
      referenceId: doc.id,
      name: doc['name'],
      quantity: doc['quantity'],
      price: doc['price'],
      distributor: doc['distributor'],
      category: doc['category'],
      expiryDate: doc['expiryDate'],
      imageUrl: doc['imageUrl'],
    )).toList();
  }
}