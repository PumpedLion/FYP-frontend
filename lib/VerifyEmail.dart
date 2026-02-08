import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'SignUp.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  const VerifyEmailPage({super.key, this.email = "user@example.com"});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  int _secondsRemaining = 59;
  Timer? _timer;
  bool _isLoading = false;

  // Updated to 5 controllers for 5 boxes
  final List<TextEditingController> _controllers =
      List.generate(5, (index) => TextEditingController());
  bool _isFilled = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _checkIfFilled() {
    bool allFilled = _controllers.every((controller) => controller.text.isNotEmpty);
    setState(() {
      _isFilled = allFilled;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Container(
            // Responsive width logic
            constraints: const BoxConstraints(maxWidth: 400),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_stories, size: 28, color: Color(0xFF1D2939)),
                    const SizedBox(width: 8),
                    Text(
                      "YourTales",
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1D2939),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Email Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF2F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mail_outline, color: Color(0xFFFF8B7D), size: 30),
                ),
                const SizedBox(height: 24),

                // Title and Subtitle
                Text(
                  "Verify Your Email",
                  style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: const Color(0xFF1D2939)),
                ),
                const SizedBox(height: 12),
                Text(
                  "We've sent a 5-digit code to",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
                Text(
                  widget.email,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 32),

                // OTP Boxes Row (Responsive)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => _otpBox(context, index),
                  ),
                ),
                const SizedBox(height: 32),

                // Resend Timer Logic
                Text(
                  _secondsRemaining > 0 ? "Resend code in ${_secondsRemaining}s" : "Didn't get the code?",
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF475467)),
                ),
                if (_secondsRemaining == 0)
                  TextButton(
                    onPressed: () {
                      setState(() => _secondsRemaining = 59);
                      _startTimer();
                    },
                    child: const Text(
                      "Resend Code",
                      style: TextStyle(color: Color(0xFFFF8B7D), fontWeight: FontWeight.bold),
                    ),
                  ),

                const SizedBox(height: 32),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (_isFilled && !_isLoading)
                        ? () async {
                            final otp = _controllers.map((c) => c.text).join();
                            setState(() => _isLoading = true);
                            final result = await AuthService.verifyOTP(widget.email, otp);
                            setState(() => _isLoading = false);

                            if (mounted) {
                              if (result['message'].toString().contains('successfully')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Verification successful! Please login.')),
                                );
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignUpPage(initialIsSignIn: true)),
                                  (route) => false,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['message'] ?? 'Invalid OTP')),
                                );
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFilled ? const Color(0xFFFF8B7D) : const Color(0xFFE4E7EC),
                      foregroundColor: Colors.white,
                      elevation: _isFilled ? 2 : 0,
                      disabledBackgroundColor: const Color(0xFFE4E7EC),
                      disabledForegroundColor: Colors.grey.shade500,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Verify & Continue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),

                // Back Button
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text("Back to Sign In"),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                
                const Divider(),
                const SizedBox(height: 20),
                Text(
                  "Didn't receive the code? Check your spam folder or try resending.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _otpBox(BuildContext context, int index) {
    return Flexible(
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: TextField(
          controller: _controllers[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: "",
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF8B7D), width: 2),
            ),
          ),
          onChanged: (value) {
            if (value.length == 1 && index < 4) {
              FocusScope.of(context).nextFocus();
            } else if (value.isEmpty && index > 0) {
              FocusScope.of(context).previousFocus();
            }
            _checkIfFilled();
          },
        ),
      ),
    );
  }
}