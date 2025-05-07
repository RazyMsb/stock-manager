import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
class AddProductForm extends StatefulWidget {
  const AddProductForm({super.key});

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _referenceIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _distributorController = TextEditingController();
  final _categoryController = TextEditingController();
  final _expiredateController = TextEditingController();

  final _primaryColor = const Color(0xFF1E4D6B);
  final _backgroundColor = const Color(0xFFF5F2ED);

  File? _pickedImage;
  final _imagePicker = ImagePicker();
  bool _isLoading = false;

  final _firestore = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _referenceIdController.text = _generateReferenceId();
  }

  String _generateReferenceId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rnd = Random().nextInt(9999);
    return 'REF-$ts-$rnd';
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _selectExpiryDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      _expiredateController.text =
          "${pickedDate.day.toString().padLeft(2, '0')}/"
          "${pickedDate.month.toString().padLeft(2, '0')}/"
          "${pickedDate.year}";
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // 🔼 Upload the image if picked
      if (_pickedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('product_images')
            .child('${_referenceIdController.text}.jpg');

        await storageRef.putFile(_pickedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      // 🔽 Save data to Firestore
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('products')
          .doc(_referenceIdController.text)
          .set({
            'referenceId': _referenceIdController.text,
            'name': _nameController.text,
            'quantity': int.parse(_quantityController.text),
            'price': double.parse(_priceController.text),
            'distributor': _distributorController.text,
            'category': _categoryController.text,
            'expiryDate': _expiredateController.text,
            'imageUrl': imageUrl ?? '', // Save image URL or empty
          });

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text('Add Product'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: _primaryColor),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child:
                              _pickedImage == null
                                  ? const Icon(
                                    Icons.camera_alt,
                                    size: 80,
                                    color: Colors.grey,
                                  )
                                  : ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      _pickedImage!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildReadOnlyField(
                        _referenceIdController,
                        'Reference ID',
                      ),
                      _buildTextField(
                        _nameController,
                        'Name',
                        validator: _validateName,
                      ),
                      _buildTextField(
                        _quantityController,
                        'Quantity',
                        keyboardType: TextInputType.number,
                        validator: _validateQuantity,
                      ),
                      _buildTextField(
                        _priceController,
                        'Price',
                        keyboardType: TextInputType.number,
                        validator: _validatePrice,
                      ),
                      _buildTextField(_distributorController, 'Distributor'),
                      _buildTextField(_categoryController, 'Category'),
                      _buildDateField(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Add Product',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value.length < 2) return 'At least 2 characters';
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final quantity = int.tryParse(value);
    if (quantity == null || quantity <= 0) return 'Invalid quantity';
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final price = double.tryParse(value);
    if (price == null || price <= 0) return 'Invalid price';
    return null;
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _expiredateController,
        readOnly: true,
        onTap: _selectExpiryDate,
        decoration: const InputDecoration(
          labelText: 'Expiry Date',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
          filled: true,
          fillColor: Colors.white,
        ),
        validator:
            (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildReadOnlyField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
      ),
    );
  }
}
