import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color primaryColor = Color(0xFF1E4D6B);
const Color backgroundColor = Color(0xFFFFFFFF);
const Color surfaceColor = Color(0xFFF5F2ED);

class StockMovementPage extends StatefulWidget {
  const StockMovementPage({Key? key}) : super(key: key);

  @override
  State<StockMovementPage> createState() => _StockMovementPageState();
}

class _StockMovementPageState extends State<StockMovementPage> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedProductId;
  String _movementType = 'entry';
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text('Stock Movement', style: TextStyle(color: primaryColor)),
        backgroundColor: backgroundColor,
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: userId == null
            ? const Center(child: Text('User not logged in'))
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProductDropdown(userId),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _qtyCtrl,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || int.tryParse(v) == null || int.parse(v) <= 0)
                          ? 'Enter valid qty'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _movementType,
                      decoration: InputDecoration(
                        labelText: 'Movement Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'entry', child: Text('Entry')),
                        DropdownMenuItem(value: 'exit', child: Text('Exit')),
                      ],
                      onChanged: (v) => setState(() => _movementType = v!),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Date: ${_selectedDate.toLocal().toString().split(' ')[0]}',
                          ),
                        ),
                        TextButton(
                          onPressed: _pickDate,
                          child: const Text('Pick Date'),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        onPressed: () => _submit(userId),
                        child: const Text('Submit Movement'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProductDropdown(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users/$userId/products').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const LinearProgressIndicator();
        final docs = snap.data!.docs;
        return DropdownButtonFormField<String>(
          value: _selectedProductId,
          decoration: InputDecoration(
            labelText: 'Product',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: docs
              .map((d) => DropdownMenuItem(value: d.id, child: Text(d['name'])))
              .toList(),
          onChanged: (v) => setState(() => _selectedProductId = v),
          validator: (v) => v == null ? 'Please select product' : null,
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (p != null) setState(() => _selectedDate = p);
  }

  Future<void> _submit(String userId) async {
    if (!_formKey.currentState!.validate()) return;
    final qty = int.parse(_qtyCtrl.text);
    final notes = _notesCtrl.text.trim();
    final prodRef = FirebaseFirestore.instance.collection('users/$userId/products').doc(_selectedProductId);
    final transRef = FirebaseFirestore.instance.collection('users/$userId/transactions').doc();

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(prodRef);
        final cur = (snap['quantity'] as num?)?.toInt() ?? 0;
        final updated = _movementType == 'entry' ? cur + qty : cur - qty;
        if (updated < 0) throw Exception('Insufficient stock');
        tx.update(prodRef, {'quantity': updated});
        tx.set(transRef, {
          'productId': _selectedProductId,
          'quantity': qty,
          'type': _movementType,
          'date': Timestamp.fromDate(_selectedDate),
          'notes': notes,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Movement recorded')));
      _formKey.currentState!.reset();
      _qtyCtrl.clear();
      _notesCtrl.clear();
      setState(() => _selectedProductId = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
