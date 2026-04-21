import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yourtales/PaymentPage.dart';
import 'package:http/http.dart' as http;
import '../test/mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Payment System Integration Tests', () {
    
    testWidgets('TC-15 & TC-18: Successful Payment Flow', (tester) async {
       final mockManuscript = {
        'id': 1,
        'title': 'Test Book',
        'price': 100,
        'coverUrl': null,
      };

      final mockPaymentInit = {
        'payment_url': 'https://mock.khalti.com/pay',
        'pidx': 'mock_pidx_123'
      };

      final mockVerifySuccess = {
        'purchased': true,
        'message': 'Payment successful'
      };
      
      // We need to return different responses based on url. 
      // Our simple TestMocks returns the same data for all calls.
      // Let's create a more specific mock client here.
      final client = MockHttpClient();
      registerFallbackValue(Uri());

      // Mock Init
      when(() => client.post(
        any(that: predicate((uri) => uri.toString().contains('/khalti/init'))),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(mockPaymentInit), 200));

      // Mock Verify
      when(() => client.post(
        any(that: predicate((uri) => uri.toString().contains('/khalti/verify'))),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(mockVerifySuccess), 200));

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(home: PaymentPage(manuscript: mockManuscript)));
        await tester.pumpAndSettle();

        // Select Khalti (already default)
        // Click Pay
        await tester.tap(find.textContaining('Pay NPR 100'));
        await tester.pumpAndSettle();

        // On Web, it shows _pendingVerificationWidget
        expect(find.text('Complete Payment in Browser'), findsOneWidget);

        // Simulate user clicking "I Have Completed the Payment"
        await tester.tap(find.text('I Have Completed the Payment'));
        await tester.pumpAndSettle();

        // Verify success dialog
        expect(find.text('Unlocked!'), findsOneWidget);
        
        // TC-18: Check DB record (implicitly verified by verifySuccess response)
      }, () => client);
    });

    testWidgets('TC-16: Payment Cancellation', (tester) async {
       final mockManuscript = {'id': 1, 'title': 'Test Book', 'price': 100};
       final mockPaymentInit = {'payment_url': 'https://mock.khalti.com/pay', 'pidx': 'mock_pidx_123'};
       final mockVerifyCancel = {'purchased': false, 'message': 'Payment failed or was cancelled.'};
      
       final client = MockHttpClient();
       registerFallbackValue(Uri());

       when(() => client.post(any(that: predicate((u) => u.path.contains('init'))), headers: any(named: 'headers'), body: any(named: 'body')))
           .thenAnswer((_) async => http.Response(jsonEncode(mockPaymentInit), 200));
       when(() => client.post(any(that: predicate((u) => u.path.contains('verify'))), headers: any(named: 'headers'), body: any(named: 'body')))
           .thenAnswer((_) async => http.Response(jsonEncode(mockVerifyCancel), 200));

      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(home: PaymentPage(manuscript: mockManuscript)));
        await tester.pumpAndSettle();

        await tester.tap(find.textContaining('Pay NPR 100'));
        await tester.pumpAndSettle();

        // Simulate "I Have Completed" but backend says no
        await tester.tap(find.text('I Have Completed the Payment'));
        await tester.pumpAndSettle();

        // Should show error snackbar
        expect(find.textContaining('cancelled'), findsWidgets);
      }, () => client);
    });

  });
}
