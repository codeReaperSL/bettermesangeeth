import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import the login page
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BetterMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1873EA),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Nunito',
      ),
      home: const RegisterPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Password validation state
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  bool _hasMinLength = false;
  bool _hasMaxLength = true;
  bool _passwordsMatch = true;

  // Track if a field has been touched
  bool _passwordTouched = false;
  bool _confirmPasswordTouched = false;

  // Validate password and update state
  void _validatePassword(String password) {
    setState(() {
      _passwordTouched = true;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigit = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]=+;]'));
      _hasMinLength = password.length >= 6;
      _hasMaxLength = password.length <= 12;

      // Update password match status if confirm password is not empty
      if (_confirmPasswordController.text.isNotEmpty) {
        _passwordsMatch = _confirmPasswordController.text == password;
      }
    });
  }

  void _validateConfirmPassword(String confirmPassword) {
    setState(() {
      _confirmPasswordTouched = true;
      _passwordsMatch = confirmPassword == _passwordController.text;
    });
  }

  // Get confirm password error message
  String? _getConfirmPasswordErrorText() {
    if (!_confirmPasswordTouched) return null;
    return _passwordsMatch ? null : "Passwords don't match";
  }

  bool get _isPasswordValid =>
      _hasUppercase &&
          _hasLowercase &&
          _hasDigit &&
          _hasSpecialChar &&
          _hasMinLength &&
          _hasMaxLength;

  Future<void> _register() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check password requirements
    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your password does not meet all requirements'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_passwordsMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwords do not match!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'user',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login page after successful registration
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      String errorMessage = 'Registration failed';

      if (e is FirebaseAuthException) {
        errorMessage = e.message ?? 'An error occurred during registration';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      _validatePassword(_passwordController.text);
    });
    _confirmPasswordController.addListener(() {
      _validateConfirmPassword(_confirmPasswordController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 30),
                  // Larger logo image
                  Image.asset(
                    'lib/assets/better.jpg',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 30),
                  // Form fields with better spacing
                  _buildTextField('Enter your name', _nameController),
                  SizedBox(height: 20),
                  _buildTextField('Enter your email address', _emailController),
                  SizedBox(height: 20),
                  _buildPasswordField('Create your password', _passwordController, null),
                  SizedBox(height: 20),
                  _buildPasswordField('Confirm your password', _confirmPasswordController, _getConfirmPasswordErrorText()),
                  SizedBox(height: 15),
                  _buildPasswordRequirements(),
                  SizedBox(height: 25),
                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1873EA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  // Login link - Updated to navigate directly to LoginPage
                  GestureDetector(
                    onTap: () {
                      // Direct navigation to LoginPage instead of using named route
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage())
                      );
                    },
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(
                              color: const Color(0xFF1873EA),
                              fontSize: 12,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must contain:',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          _buildRequirementRow('At least one uppercase letter', _hasUppercase),
          _buildRequirementRow('At least one lowercase letter', _hasLowercase),
          _buildRequirementRow('At least one number', _hasDigit),
          _buildRequirementRow('At least one special character', _hasSpecialChar),
          _buildRequirementRow('6-12 characters', _hasMinLength && _hasMaxLength),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.cancel,
            color: met ? Colors.green : Colors.red,
            size: 14,
          ),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: met ? Colors.green : Colors.red,
              fontSize: 11,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 5),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(
                color: const Color(0xFF8C8A8A),
                fontSize: 12,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w400,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 20),
              border: InputBorder.none,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              if (label.contains('email') && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, String? errorText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 5),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: errorText != null
                ? Border.all(color: Colors.red, width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(
                color: const Color(0xFF8C8A8A),
                fontSize: 12,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w400,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 20),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              if (label == 'Create your password') {
                _validatePassword(value);
              } else {
                _validateConfirmPassword(value);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red,
                fontSize: 10,
                fontFamily: 'Nunito',
              ),
            ),
          ),
      ],
    );
  }
}
