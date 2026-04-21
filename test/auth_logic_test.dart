import 'package:flutter_test/flutter_test.dart';
import 'package:yourtales/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  
  group('AuthService Logic Tests', () {
    
    test('TC-02: Duplicate Registration returns error message', () async {
      final mockResponse = {
        'message': 'User already exists'
      };
      
      final client = TestMocks.createMockClient(mockResponse, statusCode: 400);
      
      await http.runWithClient(() async {
        final result = await AuthService.register(
          'Test User', 
          'duplicate@example.com', 
          'password123', 
          'AUTHOR'
        );
        
        expect(result['message'], contains('already exists'));
      }, () => client);
    });

    test('AuthService.login success sets token and user', () async {
      final mockResponse = {
        'token': 'mock_token',
        'user': {'id': 1, 'email': 'test@example.com', 'role': 'AUTHOR'}
      };
      
      final client = TestMocks.createMockClient(mockResponse);
      
      await http.runWithClient(() async {
        // We can't easily test SharedPreferences here without mocking it too,
        // but we can test the return value.
        final result = await AuthService.login('test@example.com', 'password');
        
        expect(result['token'], equals('mock_token'));
        expect(result['user']['email'], equals('test@example.com'));
      }, () => client);
    });
  });
}
