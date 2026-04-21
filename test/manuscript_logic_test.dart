import 'package:flutter_test/flutter_test.dart';
import 'package:yourtales/services/manuscript_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('ManuscriptService Logic Tests', () {
    
    test('TC-10: Create manuscript with empty data returns error', () async {
      final mockResponse = {
        'message': 'Title and content are required'
      };
      
      final client = TestMocks.createMockClient(mockResponse, statusCode: 400);
      
      await http.runWithClient(() async {
        final result = await ManuscriptService.createManuscript({});
        
        expect(result['message'], contains('required'));
      }, () => client);
    });

    test('TC-14: Unauthorized access returns denied message', () async {
      final mockResponse = {
        'message': 'Access denied'
      };
      
      final client = TestMocks.createMockClient(mockResponse, statusCode: 403);
      
      await http.runWithClient(() async {
        // Mocking a scenario where the user tries to delete a manuscript they don't own
        final result = await ManuscriptService.deleteManuscript(999);
        
        expect(result['message'], contains('denied'));
      }, () => client);
    });
  });
}
