import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'name': _nameController.text,
            'phone': _phoneController.text,
            'email': _emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? "Registration failed");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 70),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Create Account',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Image.asset(
              'assets/images/pic2.png',
              height: MediaQuery.of(context).size.height * 0.34,
            ),
            const SizedBox(height: 5),

            // Add space above the silver widget
            const SizedBox(
              height: 20,
            ), // You can adjust this size to move the container lower

            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F2ED),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Full Name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _phoneController,
                    hintText: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Email Address',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    icon: Icons.lock,
                    isPassword: true,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4D6B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isLoading ? null : _register,
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Sign Up',
                                style: TextStyle(fontSize: 18),
                              ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Already have an account? Login',
                      style: TextStyle(color: Color(0xFF1E4D6B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1E4D6B)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFDADADA), width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1E4D6B)),
        ),
      ),
    );
  }
}
