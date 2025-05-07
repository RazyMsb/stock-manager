import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razy_mesboub_2/models/products.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen(this.product, {super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _primaryColor = const Color(0xFF1E4D6B);
  final _backgroundColor = const Color(0xFFF5F2ED);
  
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _distributorController;
  late TextEditingController _categoryController;
  late TextEditingController _expiryDateController;
  
  File? _newImage;
  final _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product.name);
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(2));
    _distributorController = TextEditingController(text: widget.product.distributor);
    _categoryController = TextEditingController(text: widget.product.category);
    _expiryDateController = TextEditingController(text: widget.product.expiryDate);
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> updates = {
        'name': _nameController.text,
        'quantity': int.parse(_quantityController.text),
        'price': double.parse(_priceController.text),
        'distributor': _distributorController.text,
        'category': _categoryController.text,
        'expiryDate': _expiryDateController.text,
      };

      if (_newImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('product_images/${widget.product.referenceId}.jpg');
        
        await storageRef.putFile(_newImage!);
        updates['imageUrl'] = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('products')
          .doc(widget.product.referenceId)
          .update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _newImage = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        title: const Text('Edit Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateProduct,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildImageSection(),
                    const SizedBox(height: 20),
                    _buildEditableFields(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: _primaryColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            if (_newImage != null)
              _buildImagePreview(_newImage!)
            else if (widget.product.imageUrl.isNotEmpty)
              _buildNetworkImage()
            else
              _buildPlaceholder(),
            const Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.edit, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(File image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(image, fit: BoxFit.cover, width: double.infinity),
    );
  }

  Widget _buildNetworkImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        widget.product.imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
          Text(
            'Add Product Image',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableFields() {
    return Column(
      children: [
        _buildTextField(_nameController, 'Product Name', _validateName),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildTextField(_quantityController, 'Quantity', _validateQuantity)),
            const SizedBox(width: 15),
            Expanded(child: _buildTextField(_priceController, 'Price', _validatePrice)),
          ],
        ),
        const SizedBox(height: 15),
        _buildTextField(_distributorController, 'Distributor', _validateDistributor),
        const SizedBox(height: 15),
        _buildTextField(_categoryController, 'Category', _validateCategory),
        const SizedBox(height: 15),
        _buildDateField(),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String? Function(String?) validator) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _expiryDateController,
      readOnly: true,
      onTap: _selectExpiryDate,
      decoration: InputDecoration(
        labelText: 'Expiry Date',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor),
        ),
        suffixIcon: const Icon(Icons.calendar_today),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => value!.isEmpty ? 'Required field' : null,
    );
  }

  Future<void> _selectExpiryDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _expiryDateController.text = 
          "${pickedDate.day.toString().padLeft(2, '0')}/"
          "${pickedDate.month.toString().padLeft(2, '0')}/"
          "${pickedDate.year}";
      });
    }
  }

  String? _validateName(String? value) => value!.isEmpty ? 'Name required' : null;
  String? _validateQuantity(String? value) => 
    int.tryParse(value!) == null || int.parse(value) <= 0 ? 'Invalid quantity' : null;
  String? _validatePrice(String? value) => 
    double.tryParse(value!) == null || double.parse(value) <= 0 ? 'Invalid price' : null;
  String? _validateDistributor(String? value) => value!.isEmpty ? 'Distributor required' : null;
  String? _validateCategory(String? value) => value!.isEmpty ? 'Category required' : null;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _distributorController.dispose();
    _categoryController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }
}