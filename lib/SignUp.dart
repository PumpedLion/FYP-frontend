import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Importing  pages
import 'VerifyEmail.dart';
import 'AdminDashBoard.dart'; 
import 'Store.dart';
import 'services/auth_service.dart';
import 'ForgotPassword.dart';

class SignUpPage extends StatefulWidget {
  final bool initialIsSignIn; 

  const SignUpPage({super.key, this.initialIsSignIn = false});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late bool isSignIn;
  String userRole = 'Author';
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    isSignIn = widget.initialIsSignIn;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!isSignIn && fullName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result;
    if (isSignIn) {
      result = await AuthService.login(email, password);
    } else {
      result = await AuthService.register(fullName, email, password, userRole.toUpperCase());
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['token'] != null || (result['message'] != null && result['message'].toString().contains('successfully'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Success')),
        );
        
        if (isSignIn) {
          final user = result['user'];
          final role = user?['role'];
          final screenWidth = MediaQuery.of(context).size.width;
          final bool isMobile = screenWidth < 1100;

          if (role == 'READER' || isMobile) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StorePage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyEmailPage(email: email),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'An error occurred')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: size.height - 80),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 80 : 20,
            vertical: 20,
          ),
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            children: [
              // LEFT SIDE: Branding Section
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: Column(
                  crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_stories, size: 40, color: Color(0xFF1D2939)),
                        const SizedBox(width: 12),
                        Text("YourTales",
                            style: GoogleFonts.dmSerifDisplay(
                                fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1D2939))),
                      ],
                    ),
                    const SizedBox(height: 40),
                    RichText(
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: isDesktop ? 60 : 40,
                          height: 1.1,
                          color: const Color(0xFF1D2939),
                        ),
                        children: const [
                          TextSpan(text: "Your stories,\n"),
                          TextSpan(text: "beautifully told", style: TextStyle(color: Color(0xFFFF8B7D))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "The global platform for modern storytelling.",
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                      style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),

              if (isDesktop) const SizedBox(width: 60),

              // RIGHT SIDE: Auth Card (Login/Signup Form)
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: Center(
                  child: Container(
                    margin: EdgeInsets.only(top: isDesktop ? 0 : 40),
                    padding: const EdgeInsets.all(40),
                    constraints: const BoxConstraints(maxWidth: 500),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TAB SWITCHER (Switch between Sign In and Sign Up)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              _buildTab("Sign In", isSignIn, () => setState(() => isSignIn = true)),
                              _buildTab("Sign Up", !isSignIn, () => setState(() => isSignIn = false)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 35),
                        Text(
                          isSignIn ? "Welcome back" : "Create account",
                          style: GoogleFonts.dmSerifDisplay(fontSize: 32, color: const Color(0xFF1D2939)),
                        ),
                        const SizedBox(height: 25),

                        // FORM FIELDS
                        if (!isSignIn) _buildTextField("Full Name", "John Doe", controller: _nameController),
                        _buildTextField("Email Address", "you@example.com", controller: _emailController),
                        _buildTextField("Password", "••••••••", isPassword: true, controller: _passwordController),

                        if (!isSignIn) ...[
                          const Text("I am a...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          _buildRoleDropdown(),
                          const SizedBox(height: 25),
                        ],

                        if (isSignIn)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordPage())),
                                child: const Text("Forgot password?", style: TextStyle(color: Color(0xFFFF8B7D)))),
                          ),

                        const SizedBox(height: 10),

                        // --- MAIN ACTION BUTTON ---
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8B7D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    isSignIn ? "Sign In" : "Create Account",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 30),
                        const Center(child: Text("Or continue with", style: TextStyle(color: Colors.grey, fontSize: 12))),
                        const SizedBox(height: 20),

                        // SOCIAL BUTTONS
                        Row(
                          children: [
                            _socialButton("Google", FontAwesomeIcons.google),
                            const SizedBox(width: 15),
                            _socialButton("GitHub", FontAwesomeIcons.github),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: active ? Colors.black : Colors.grey))),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {bool isPassword = false, required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8B7D))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: userRole,
          isExpanded: true,
          items: ['Author', 'Reader', 'Editor'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (val) => setState(() => userRole = val!),
        ),
      ),
    );
  }

  Widget _socialButton(String label, IconData icon) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: FaIcon(icon, size: 18, color: Colors.black),
        label: Text(label, style: const TextStyle(color: Colors.black)),
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }
}