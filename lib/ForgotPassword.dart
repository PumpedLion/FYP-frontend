import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int _currentStep = 1; // 1: Email, 2: OTP, 3: New Password
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError("Please enter your email");
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.forgotPassword(email);
    setState(() => _isLoading = false);

    if (mounted) {
      if (result['message'].toString().contains('sent')) {
        _showSuccess(result['message']);
        setState(() => _currentStep = 2);
      } else {
        _showError(result['message']);
      }
    }
  }

  Future<void> _handleVerifyOTP() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showError("Please enter the OTP");
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.verifyResetOTP(email, otp);
    setState(() => _isLoading = false);

    if (mounted) {
      if (result['message'].toString().contains('successfully')) {
        _showSuccess(result['message']);
        setState(() => _currentStep = 3);
      } else {
        _showError(result['message']);
      }
    }
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _passwordController.text.trim();

    if (newPassword.isEmpty || newPassword.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.resetPassword(email, otp, newPassword);
    setState(() => _isLoading = false);

    if (mounted) {
      if (result['message'].toString().contains('successful')) {
        _showSuccess(result['message']);
        Navigator.pop(context); // Go back to login
      } else {
        _showError(result['message']);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_reset, size: 48, color: Color(0xFFFF8B7D)),
                const SizedBox(height: 24),
                Text(
                  _currentStep == 1 ? "Forgot Password" : _currentStep == 2 ? "Verify OTP" : "Reset Password",
                  style: GoogleFonts.dmSerifDisplay(fontSize: 32, color: const Color(0xFF1D2939)),
                ),
                const SizedBox(height: 12),
                Text(
                  _currentStep == 1 
                    ? "Enter your email to receive a password reset OTP." 
                    : _currentStep == 2 
                      ? "Check your email for the 5-digit code." 
                      : "Create a new strong password for your account.",
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 16),
                ),
                const SizedBox(height: 35),
                
                if (_currentStep == 1)
                  _buildTextField("Email Address", "you@example.com", controller: _emailController)
                else if (_currentStep == 2)
                  _buildTextField("Enter OTP", "12345", controller: _otpController)
                else
                  _buildTextField("New Password", "••••••••", isPassword: true, controller: _passwordController),

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : (_currentStep == 1 ? _handleForgotPassword : _currentStep == 2 ? _handleVerifyOTP : _handleResetPassword),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8B7D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_currentStep == 3 ? "Reset Password" : "Continue", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {bool isPassword = false, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: _currentStep == 2 ? TextInputType.number : TextInputType.text,
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
    );
  }
}
