import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore package
import 'firebase_options.dart';
import 'login.dart'; // Import the LoginPage class

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Firebase initialization
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Nunito',
        primaryColor: const Color(0xFF1873EA),
      ),
      home: RegisterPage(),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers for input fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  // Firebase Auth and Firestore instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to handle user registration
  Future<void> _register() async {
    try {
      // Check if passwords match
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match!')),
        );
        return;
      }

      // Try to create a new user with email and password
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save user data to Firestore in the 'users' collection
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'user', // Add a default role (you can change this as per your requirement)
      });

      // Test Firestore connection by writing a test document
      await _firestore.collection('test').doc(userCredential.user?.uid).set({
        'status': 'Firestore is connected',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // If successful, show success message and user details
      print("Registration successful! User: ${userCredential.user?.email}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful!')),
      );
    } catch (e) {
      // If there's an error, show it to the user
      print("Error: $e"); // Log the error to debug
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  // Navigate to LoginPage
  void _navigateToLoginPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Push LoginPage to the stack
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width and height using MediaQuery
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Stack(
          children: [
            // Image positioned at the top center
            Positioned(
              left: 15,
              top: screenHeight * 0.01,
              child: SizedBox(
                width: 400,
                height: 400,
                child: Image.asset('lib/assets/better.jpg', fit: BoxFit.cover),
              ),
            ),
            // Name TextField section
            Positioned(
              left: screenWidth * 0.08,
              top: screenHeight * 0.35,
              child: _buildTextField('Enter your name', _nameController),
            ),
            // Email TextField section
            Positioned(
              left: screenWidth * 0.08,
              top: screenHeight * 0.45,
              child: _buildTextField('Enter your email address', _emailController),
            ),
            // Password TextField section
            Positioned(
              left: screenWidth * 0.08,
              top: screenHeight * 0.55,
              child: _buildTextField('Create your password', _passwordController,
                  obscureText: true),
            ),
            // Confirm Password TextField section
            Positioned(
              left: screenWidth * 0.08,
              top: screenHeight * 0.65,
              child: _buildTextField(
                  'Confirm your password', _confirmPasswordController,
                  obscureText: true),
            ),
            // Register Button
            Positioned(
              left: screenWidth * 0.08,
              top: screenHeight * 0.75,
              child: ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1873EA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size(screenWidth * 0.83, 40),
                ),
                child: Text(
                  'Register',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            // Already have an account text with navigation
            Positioned(
              left: screenWidth * 0.31,
              top: screenHeight * 0.82,
              child: GestureDetector(
                onTap: _navigateToLoginPage, // On tapping the login text, navigate to LoginPage
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(
                          color: const Color(0xFF1873EA),
                          fontSize: 10,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable function for creating text fields with external shadows
  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false}) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.83,
      height: 67,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 27,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.83,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), // Adjusted for smoother corners
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: Offset(0, 4),
                    blurRadius: 8, // Increased blur for a smoother shadow effect
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: TextStyle(
                    color: const Color(0xFF8C8A8A),
                    fontSize: 12, // Slightly larger font for better readability
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
