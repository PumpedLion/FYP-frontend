import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yourtales/main.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Interface Integration Tests', () {
    
    testWidgets('TC-19 & TC-20: Homepage Load and Navigation', (tester) async {
      await tester.pumpWidget(const YourTalesApp());
      await tester.pumpAndSettle();

      // TC-19: Load homepage
      expect(find.text('YourTales'), findsWidgets);
      expect(find.text('Write together, \nPublish everywhere.'), findsOneWidget);

      // TC-20: Navigation
      // Find "For Authors" in Navbar and tap
      final authorsLink = find.text('For Authors');
      if (authorsLink.evaluate().isNotEmpty) {
        await tester.tap(authorsLink);
        await tester.pumpAndSettle();
        // Since it's a scroll-to-section, we verify movement if possible, 
        // or just that the tap didn't crash.
      }

      // Navigate to Sign In
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('TC-21: Responsive Design - Mobile View', (tester) async {
      // Set surface size to mobile dimensions
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const YourTalesApp());
      await tester.pumpAndSettle();

      // In mobile view, the "Start Writing" text might change to "Write" 
      // based on lib/main.dart:194: child: Text(isMobile ? "Write" : "Start Writing"),
      expect(find.text('Write'), findsOneWidget);
      expect(find.text('Start Writing'), findsNothing);

      // Clean up
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('TC-22: Button Actions - Start Free Trial', (tester) async {
      await tester.pumpWidget(const YourTalesApp());
      await tester.pumpAndSettle();

      final ctaBtn = find.text('Start Free Trial →');
      await tester.tap(ctaBtn);
      await tester.pumpAndSettle();

      // Should Navigate to Sign Up page
      expect(find.text('Create account'), findsOneWidget);
    });

  });
}
