import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'SignUp.dart';

import 'package:flutter_localizations/flutter_localizations.dart'; // 1. Add this import
import 'package:flutter_quill/flutter_quill.dart'; // 2. Add this import

void main() {
  runApp(const YourTalesApp());
}

class YourTalesApp extends StatelessWidget {
  const YourTalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YourTales',
      debugShowCheckedModeBanner: false,

       // --- ADD THESE TWO PROPERTIES BELOW ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate, // This fixes the Quill error
      ],
      supportedLocales: FlutterQuillLocalizations.supportedLocales, // This sets the languages
      // ---------------------------------------

      
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const LandingPage(),
    );
  }
}

// ==========================================
// 1. LANDING PAGE
// ==========================================
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _authorsKey = GlobalKey();
  final GlobalKey _readersKey = GlobalKey();

  void _scrollToSection(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: NavBar(
          onFeaturesTap: () => _scrollToSection(_featuresKey),
          onAuthorsTap: () => _scrollToSection(_authorsKey),
          onReadersTap: () => _scrollToSection(_readersKey),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const HeroSection(),
            FeaturesSection(key: _featuresKey),
            TestimonialSection(key: _authorsKey),
            CTASection(key: _readersKey),
            const FooterSection(),
          ],
        ),
      ),
    );
  }
}

// --- NAVBAR ---
class NavBar extends StatelessWidget {
  final VoidCallback onFeaturesTap;
  final VoidCallback onAuthorsTap;
  final VoidCallback onReadersTap;

  const NavBar({
    super.key,
    required this.onFeaturesTap,
    required this.onAuthorsTap,
    required this.onReadersTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 850;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories, color: Color(0xFF1D2939), size: 28),
              const SizedBox(width: 8),
              Text("YourTales",
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1D2939))),
            ],
          ),
          if (!isMobile)
            Row(
              children: [
                _navLink("Features", onFeaturesTap),
                _navLink("For Authors", onAuthorsTap),
                _navLink("For Readers", onReadersTap),
                _navLink("Docs", () {}),
              ],
            ),
          Row(
            children: [
              if (!isMobile)
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage(initialIsSignIn: true))),
                  child: const Text("Sign In", style: TextStyle(color: Color(0xFF1D2939))),
                ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage(initialIsSignIn: false))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8B7D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(isMobile ? "Write" : "Start Writing"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navLink(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: InkWell(
        onTap: onTap,
        child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

// --- HERO SECTION ---
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 900;
    return Container(
      width: double.infinity,
      color: const Color(0xFFF9FBF9),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 100, vertical: 80),
      child: isMobile ? Column(children: _content(context, true)) : Row(children: _content(context, false)),
    );
  }

  List<Widget> _content(BuildContext context, bool isMobile) {
    return [
      Expanded(
        flex: isMobile ? 0 : 1,
        child: Column(
          crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            _badge("Trusted by 12,000+ authors"),
            const SizedBox(height: 20),
            RichText(
              textAlign: isMobile ? TextAlign.center : TextAlign.left,
              text: TextSpan(
                style: GoogleFonts.dmSerifDisplay(fontSize: isMobile ? 42 : 64, color: const Color(0xFF1D2939), height: 1.1),
                children: const [
                  TextSpan(text: "Write together, \n"),
                  TextSpan(text: "Publish ", style: TextStyle(color: Color(0xFFFF8B7D))),
                  TextSpan(text: "everywhere."),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Text("The collaborative e-book platform where stories come alive.",
                textAlign: isMobile ? TextAlign.center : TextAlign.left,
                style: const TextStyle(fontSize: 18, color: Colors.blueGrey)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthPage(initialIsSignIn: false))),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8B7D), padding: const EdgeInsets.all(22)),
              child: const Text("Start Free Trial →", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      if (!isMobile) const SizedBox(width: 50),
      Expanded(flex: isMobile ? 0 : 1, child: Image.asset('assets/Hero Section.png', fit: BoxFit.contain)),
    ];
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

// --- FEATURES SECTION ---
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 20),
      child: Column(
        children: [
          const Text("EVERYTHING YOU NEED", style: TextStyle(letterSpacing: 2, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 10),
          Text("Built for creators who think big", style: GoogleFonts.dmSerifDisplay(fontSize: 38, color: const Color(0xFF1D2939))),
          const SizedBox(height: 60),
          Wrap(
            spacing: 30, runSpacing: 30, alignment: WrapAlignment.center,
            children: const [
              FeatureCard(title: "Real-Time Collaboration", color: Color(0xFFE8F5E9), icon: Icons.people_outline),
              FeatureCard(title: "One-Click Publishing", color: Color(0xFFFFF3E0), icon: Icons.rocket_launch_outlined),
              FeatureCard(title: "Deep Analytics", color: Color(0xFFFFEBEE), icon: Icons.bar_chart_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final String title; final Color color; final IconData icon;
  const FeatureCard({super.key, required this.title, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320, padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: Colors.black87),
          const SizedBox(height: 25),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 12),
          const Text("Integrated tools designed specifically for modern authors.", style: TextStyle(color: Colors.blueGrey, height: 1.5)),
        ],
      ),
    );
  }
}

// --- TESTIMONIAL ---
class TestimonialSection extends StatelessWidget {
  const TestimonialSection({super.key});
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 850;
    return Container(
      color: const Color(0xFF0D1B2A),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        children: [
          Expanded(flex: isMobile ? 0 : 1, child: SizedBox(height: 500, child: Image.asset('assets/Man.png', fit: BoxFit.cover))),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote, color: Color(0xFFFF8B7D), size: 60),
                  Text("YourTales transformed how my writing team collaborates.", style: GoogleFonts.dmSerifDisplay(color: Colors.white, fontSize: 28)),
                  const SizedBox(height: 30),
                  const Text("Sarah Chen", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// --- CTA SECTION ---
class CTASection extends StatelessWidget {
  const CTASection({super.key});
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 900;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 20),
      child: Wrap(
        alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 60, runSpacing: 40,
        children: [
          Image.asset('assets/Author.png', width: isMobile ? 300 : 500),
          SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text("Start your publishing journey today", style: GoogleFonts.dmSerifDisplay(fontSize: 36)),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthPage(initialIsSignIn: false))),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A), padding: const EdgeInsets.all(22)),
                  child: const Text("Start Free Trial", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- FOOTER ---
class FooterSection extends StatelessWidget {
  const FooterSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1B2A), padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          const Divider(color: Colors.white12),
          const SizedBox(height: 40),
          const Text("© 2024 YourTales. All rights reserved.", style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}

// ==========================================
// 2. AUTH PAGE (LOGIN / SIGN UP TOGGLE)
// ==========================================
class AuthPage extends StatefulWidget {
  final bool initialIsSignIn;
  const AuthPage({super.key, this.initialIsSignIn = true});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late bool isSignIn;
  String userRole = 'Author';

  @override
  void initState() {
    super.initState();
    isSignIn = widget.initialIsSignIn;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 100 : 20, vertical: 60),
          child: Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            children: [
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: Column(
                  crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.auto_stories, size: 40),
                      const SizedBox(width: 10),
                      Text("YourTales", style: GoogleFonts.dmSerifDisplay(fontSize: 28, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 50),
                    RichText(
                      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.dmSerifDisplay(fontSize: isDesktop ? 55 : 38, color: const Color(0xFF1D2939), height: 1.1),
                        children: const [TextSpan(text: "Your stories,\n"), TextSpan(text: "beautifully told", style: TextStyle(color: Color(0xFFFF8B7D)))],
                      ),
                    ),
                  ],
                ),
              ),
              if (isDesktop) const SizedBox(width: 50),
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    constraints: const BoxConstraints(maxWidth: 500),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            children: [
                              _tab("Sign In", isSignIn, () => setState(() => isSignIn = true)),
                              _tab("Sign Up", !isSignIn, () => setState(() => isSignIn = false)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(isSignIn ? "Welcome back" : "Create account", style: GoogleFonts.dmSerifDisplay(fontSize: 30)),
                        const SizedBox(height: 25),
                        if (!isSignIn) _field("Full Name", "John Doe"),
                        _field("Email Address", "you@example.com"),
                        _field("Password", "••••••••", isPass: true),
                        if (!isSignIn) ...[
                          const Text("I am a...", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _roleDropdown(),
                          const SizedBox(height: 20),
                        ],
                        SizedBox(
                          width: double.infinity, height: 55,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8B7D), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: Text(isSignIn ? "Sign In" : "Create Account"),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(children: [
                          _social(FontAwesomeIcons.google, "Google"),
                          const SizedBox(width: 15),
                          _social(FontAwesomeIcons.github, "GitHub"),
                        ]),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String t, bool a, VoidCallback o) 
  => Expanded(child: GestureDetector(onTap: o, child: Container(padding: const EdgeInsets.all(12), 
  decoration: BoxDecoration(color: a ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)), 
  child: Center(child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: a ? Colors.black : Colors.grey))))));

  Widget _field(String l, String h, {bool isPass = false}) 
  => Padding(padding: const EdgeInsets.only(bottom: 20), 
  child: Column(crossAxisAlignment: CrossAxisAlignment.start, 
  children: [Text(l, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), 
  TextField(obscureText: isPass, decoration: InputDecoration(hintText: h, 
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), 
  borderSide: BorderSide(color: Colors.grey.shade300))))]));

  Widget _roleDropdown() 
  => Container(padding: const EdgeInsets.symmetric(horizontal: 15), 
  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), 
  border: Border.all(color: Colors.grey.shade300)), 
  child: DropdownButtonHideUnderline(
    child: DropdownButton<String>(
      value: userRole, isExpanded: true, items: ['Author', 'Reader'].map((v) 
      => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) 
      => setState(() => userRole = v!))));

  Widget _social(IconData i, String l) 
  => Expanded(child: OutlinedButton.icon(onPressed: () {}, 
  icon: FaIcon(i, size: 18), label: Text(l), 
  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15), 
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))));
}