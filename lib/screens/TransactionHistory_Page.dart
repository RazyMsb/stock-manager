import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color primaryColor = Color(0xFF1E4D6B);
const Color backgroundColor = Color(0xFFFFFFFF);
const Color surfaceColor = Color(0xFFF5F2ED);

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  String? _selectedProductId;
  String _selectedMovementType = 'all';
  DateTimeRange? _selectedDateRange;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text('Transaction History', style: TextStyle(color: primaryColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilters(userId),
            const SizedBox(height: 24),
            Expanded(child: _buildTransactionList(userId)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(String? userId) {
    return Card(
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Filtre produit
            FutureBuilder<QuerySnapshot>(
              future: _firestore.collection('users/$userId/products').get(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator(minHeight: 2);
                }
                final docs = snap.data?.docs ?? [];
                return DropdownButtonFormField<String?>(
                  value: _selectedProductId,
                  decoration: _inputDecoration('Product', Icons.inventory),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Products')),
                    ...docs.map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.get('name')?.toString() ?? 'Unnamed'),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedProductId = v),
                );
              },
            ),
            const SizedBox(height: 12),
            // Filtre type
            DropdownButtonFormField<String>(
              value: _selectedMovementType,
              decoration: _inputDecoration('Movement Type', Icons.compare_arrows),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Types')),
                DropdownMenuItem(value: 'entry', child: Text('Entry')),
                DropdownMenuItem(value: 'exit', child: Text('Exit')),
              ],
              onChanged: (v) => setState(() => _selectedMovementType = v!),
            ),
            const SizedBox(height: 12),
            // Filtre date
            InkWell(
              onTap: _pickDateRange,
              child: InputDecorator(
                decoration: _inputDecoration('Date Range', Icons.calendar_month),
                child: Text(
                  _selectedDateRange == null
                      ? 'All Dates'
                      : '${_formatDate(_selectedDateRange!.start)} – ${_formatDate(_selectedDateRange!.end)}',
                  style: TextStyle(
                    color: _selectedDateRange == null ? Colors.grey[600] : primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  Widget _buildTransactionList(String? userId) {
    if (userId == null) {
      return const Center(child: Text('User not logged in'));
    }

    // On retire les filtres date côté serveur et on ne trie pas par date ici
    Query q = _firestore.collection('users/$userId/transactions');

    if (_selectedProductId != null) {
      q = q.where('productId', isEqualTo: _selectedProductId);
    }
    if (_selectedMovementType != 'all') {
      q = q.where('type', isEqualTo: _selectedMovementType);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final docs = snap.data?.docs ?? [];

        // Filtrage local sur la date
        final filtered = _selectedDateRange == null
            ? docs
            : docs.where((d) {
                final dt = (d.get('date') as Timestamp).toDate();
                return !dt.isBefore(_selectedDateRange!.start) &&
                       !dt.isAfter(_selectedDateRange!.end);
              }).toList();

        // Tri local par date descendante
        filtered.sort((a, b) {
          final da = (a.get('date') as Timestamp).toDate();
          final db = (b.get('date') as Timestamp).toDate();
          return db.compareTo(da);
        });

        if (filtered.isEmpty) {
          return const Center(child: Text('No transactions found'));
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final doc = filtered[i];
            return _TransactionCard(
              userId: userId,
              productId: doc.get('productId'),
              quantity: (doc.get('quantity') as num).toInt(),
              type: doc.get('type'),
              date: (doc.get('date') as Timestamp).toDate(),
              notes: doc.get('notes') ?? '',
              onDelete: () => _deleteTransaction(doc.id),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTransaction(String id) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _firestore.collection('users/$userId/transactions').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
}

class _TransactionCard extends StatelessWidget {
  final String userId, productId, type, notes;
  final int quantity;
  final DateTime date;
  final VoidCallback onDelete;

  const _TransactionCard({
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.type,
    required this.date,
    required this.notes,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.doc('users/$userId/products/$productId').get(),
      builder: (ctx, snap) {
        final name = snap.data?.get('name')?.toString() ?? productId;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: type == 'entry' ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                type == 'entry' ? Icons.arrow_downward : Icons.arrow_upward,
                color: primaryColor,
              ),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Qty: $quantity\nNotes: $notes'),
            trailing: IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
          ),
        );
      },
    );
  }
}
