import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  String? _selectedProductId;
  String _selectedMovementType = 'all';
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProductDropdown(userId),
            const SizedBox(height: 16),
            _buildMovementTypeDropdown(),
            const SizedBox(height: 16),
            _buildDateRangePicker(),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFilteredTransactionsStream(userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final transactions = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return TransactionCard(
                        userId: userId!,
                        productId: transaction['productId'],
                        quantity: transaction['quantity'],
                        type: transaction['type'],
                        date: (transaction['date'] as Timestamp).toDate(),
                        notes: transaction['notes'] ?? 'No notes',
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDropdown(String? userId) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users/$userId/products')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final products = snapshot.data!.docs;
        return DropdownButtonFormField<String>(
          value: _selectedProductId,
          decoration: const InputDecoration(labelText: 'Select Product'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Products'),
            ),
            ...products.map((doc) {
              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text(doc['name']),
              );
            }).toList(),
          ],
          onChanged: (val) {
            setState(() => _selectedProductId = val);
          },
        );
      },
    );
  }

  Widget _buildMovementTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedMovementType,
      decoration: const InputDecoration(labelText: 'Movement Type'),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Types')),
        DropdownMenuItem(value: 'entry', child: Text('Entry')),
        DropdownMenuItem(value: 'exit', child: Text('Exit')),
      ],
      onChanged: (val) {
        setState(() => _selectedMovementType = val!);
      },
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Text(_selectedDateRange == null
            ? 'Select Date Range'
            : 'From: ${_selectedDateRange!.start.toLocal().toString().split(' ')[0]} To: ${_selectedDateRange!.end.toLocal().toString().split(' ')[0]}'),
        const Spacer(),
        TextButton(
          onPressed: _pickDateRange,
          child: const Text('Select Date'),
        ),
      ],
    );
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Stream<QuerySnapshot> _getFilteredTransactionsStream(String? userId) {
    CollectionReference transactionsRef = FirebaseFirestore.instance
        .collection('users/$userId/transactions');

    Query query = transactionsRef;

    if (_selectedProductId != null) {
      query = query.where('productId', isEqualTo: _selectedProductId);
    }

    if (_selectedMovementType != 'all') {
      query = query.where('type', isEqualTo: _selectedMovementType);
    }

    if (_selectedDateRange != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_selectedDateRange!.start),
          isLessThanOrEqualTo: Timestamp.fromDate(_selectedDateRange!.end));
    }

    return query.orderBy('timestamp', descending: true).snapshots();
  }
}

class TransactionCard extends StatelessWidget {
  final String userId;
  final String productId;
  final int quantity;
  final String type;
  final DateTime date;
  final String notes;

  const TransactionCard({
    Key? key,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.type,
    required this.date,
    required this.notes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users/$userId/products')
          .doc(productId)
          .get(),
      builder: (context, snapshot) {
        final productName =
            snapshot.hasData ? snapshot.data!['name'] ?? productId : productId;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text('$productName - ${type.toUpperCase()}'),
            subtitle: Text('Quantity: $quantity\nNotes: $notes'),
            trailing: Text('${date.toLocal().toString().split(' ')[0]}'),
          ),
        );
      },
    );
  }
}
