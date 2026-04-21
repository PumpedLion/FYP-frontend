import 'package:flutter_test/flutter_test.dart';
import 'package:yourtales/services/payment_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Payment System Logic Tests', () {
    
    test('TC-17: Invalid credentials in payment verification', () async {
      final mockResponse = {
        'message': 'Invalid verification data'
      };
      
      final client = TestMocks.createMockClient(mockResponse, statusCode: 400);
      
      await http.runWithClient(() async {
        final result = await PaymentService.verifyKhaltiPayment('invalid_pidx', 1);
        
        expect(result['message'], contains('Invalid'));
      }, () => client);
    });
  });
}
