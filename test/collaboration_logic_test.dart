import 'package:flutter_test/flutter_test.dart';
import 'package:yourtales/services/manuscript_service.dart';
import 'package:yourtales/services/comment_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Collaboration Logic Tests', () {
    
    test('TC-11: Invite collaborator success', () async {
      final mockResponse = {
        'message': 'Invitation sent successfully'
      };
      
      final client = TestMocks.createMockClient(mockResponse);
      
      await http.runWithClient(() async {
        final result = await ManuscriptService.inviteCollaborator(
          1, 
          'collab@example.com', 
          'EDITOR'
        );
        
        expect(result['message'], contains('successfully'));
      }, () => client);
    });

    test('TC-12: Accept invitation success', () async {
      final mockResponse = {
        'message': 'Invitation accepted'
      };
      
      final client = TestMocks.createMockClient(mockResponse);
      
      await http.runWithClient(() async {
        final result = await ManuscriptService.respondToInvitation(123, 'ACCEPTED');
        
        expect(result['message'], contains('accepted'));
      }, () => client);
    });

    test('TC-13: Add comment success', () async {
      final mockResponse = {
        'message': 'Comment added successfully'
      };
      
      final client = TestMocks.createMockClient(mockResponse);
      
      await http.runWithClient(() async {
        final result = await CommentService.addComment(456, 'This is a test comment');
        
        expect(result['message'], contains('successfully'));
      }, () => client);
    });
  });
}
