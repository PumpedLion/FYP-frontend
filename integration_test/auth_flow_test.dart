import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yourtales/main.dart';
import 'package:http/http.dart' as http;
import '../test/mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    
    testWidgets('TC-01 & TC-03: Registration and Login Flows', (tester) async {
      final mockAuthResponse = {
        'token': 'mock_jwt_token',
        'message': 'Operation successful',
        'user': {'id': 1, 'email': 'test@example.com', 'role': 'AUTHOR'}
      };
      
      final client = TestMocks.createMockClient(mockAuthResponse);
      
      await http.runWithClient(() async {
        // Load the app
        await tester.pumpWidget(const YourTalesApp());
        await tester.pumpAndSettle();

        // TC-19: Load homepage verified by pumpWidget success
        expect(find.text('YourTales'), findsWidgets);

        // Navigate to SignUp
        final startWritingBtn = find.text('Start Writing');
        await tester.tap(startWritingBtn);
        await tester.pumpAndSettle();

        // Verify we are on SignUpPage
        expect(find.text('Create account'), findsOneWidget);

        // TC-01: User Registration
        await tester.enterText(find.byType(TextField).at(0), 'Test Author'); // Full Name
        await tester.enterText(find.byType(TextField).at(1), 'test@example.com'); // Email
        await tester.enterText(find.byType(TextField).at(2), 'password123'); // Password
        
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();

        // Expect navigation to VerifyEmailPage (or success message)
        expect(find.text('Verify'), findsWidgets);

      }, () => client);
    });

    testWidgets('TC-04: Login with wrong password', (tester) async {
      final mockErrorResponse = {
        'message': 'Invalid credentials'
      };
      
      final client = TestMocks.createMockClient(mockErrorResponse, statusCode: 401);
      
      await http.runWithClient(() async {
        await tester.pumpWidget(const YourTalesApp());
        await tester.pumpAndSettle();

        // Go to Sign In
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Enter credentials
        await tester.enterText(find.byType(TextField).at(0), 'test@example.com'); 
        await tester.enterText(find.byType(TextField).at(1), 'wrong_password'); 
        
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Check for error snackbar message
        expect(find.text('Invalid credentials'), findsOneWidget);
        
      }, () => client);
    });

  });
}
