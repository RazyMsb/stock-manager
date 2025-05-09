import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StockMovementPage extends StatefulWidget {
  const StockMovementPage({Key? key}) : super(key: key);

  @override
  State<StockMovementPage> createState() => _StockMovementPageState();
}

class _StockMovementPageState extends State<StockMovementPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedProductId;
  String _movementType = 'entry';
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const Center(child: Text('User not logged in'));

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Movement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProductDropdown(userId),
              const SizedBox(height: 16),
              _buildQuantityField(),
              const SizedBox(height: 16),
              _buildMovementTypeDropdown(),
              const SizedBox(height: 16),
              _buildDatePicker(context),
              _buildNotesField(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _submitForm(userId),
                child: const Text('Submit Movement'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductDropdown(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users/$userId/products')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final items = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Select Product'),
          items: items.map((doc) {
            return DropdownMenuItem(value: doc.id, child: Text(doc['name']));
          }).toList(),
          onChanged: (val) => setState(() => _selectedProductId = val),
          validator: (val) => val == null ? 'Please select a product' : null,
        );
      },
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: const InputDecoration(labelText: 'Quantity'),
      keyboardType: TextInputType.number,
      validator: (val) =>
          (val == null || int.tryParse(val) == null || int.parse(val) <= 0)
              ? 'Enter valid quantity'
              : null,
    );
  }

  Widget _buildMovementTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _movementType,
      decoration: const InputDecoration(labelText: 'Movement Type'),
      items: const [
        DropdownMenuItem(value: 'entry', child: Text('Entry')),
        DropdownMenuItem(value: 'exit', child: Text('Exit')),
      ],
      onChanged: (val) => setState(() => _movementType = val!),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            "Date: ${_selectedDate.toLocal().toString().split(' ')[0]}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: const Text('Pick Date'),
        )
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(labelText: 'Notes'),
    );
  }

  Future<void> _submitForm(String userId) async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = int.parse(_quantityController.text);
    final notes = _notesController.text.trim();
    final productRef = FirebaseFirestore.instance
        .collection('users/$userId/products')
        .doc(_selectedProductId);

    final transactionRef = FirebaseFirestore.instance
        .collection('users/$userId/transactions')
        .doc();

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snapshot = await tx.get(productRef);
        final currentQty = snapshot['quantity'] ?? 0;

        int updatedQty = _movementType == 'entry'
            ? currentQty + quantity
            : currentQty - quantity;

        if (updatedQty < 0) {
          throw Exception('Not enough stock for exit');
        }

        tx.update(productRef, {'quantity': updatedQty});
        tx.set(transactionRef, {
          'productId': _selectedProductId,
          'quantity': quantity,
          'type': _movementType,
          'date': Timestamp.fromDate(_selectedDate),
          'notes': notes,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock movement added')),
      );
      _formKey.currentState!.reset();
      _quantityController.clear();
      _notesController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
