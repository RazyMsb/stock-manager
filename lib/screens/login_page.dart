import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart'; // Chemin relatif correct
import 'sigunp_page.dart';
class LoginScreen extends StatefulWidget {
  static var routeName;

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Login Error'),
            content: Text(message),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
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
                  'Welcome Back',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Image.asset(
              'assets/images/pic1.png',
              height: MediaQuery.of(context).size.height * 0.34,
            ),
            const SizedBox(height: 40),
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
                  const SizedBox(height: 20),
                  buildTextField(
                    controller: emailController,
                    hintText: 'Enter your Email',
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 12),
                  buildTextField(
                    controller: passwordController,
                    hintText: 'Enter your Password',
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
                      onPressed: isLoading ? null : loginUser,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?", 
                          style: TextStyle(color: Color(0xFF1E4D6B))),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => const  SignupPage()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF161618),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (context.mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Registration Error'),
          content: Text(e.message ?? 'Registration failed'),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}