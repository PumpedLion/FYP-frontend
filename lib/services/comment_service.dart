import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class CommentService {
  static const String baseUrl = 'http://localhost:8000/api/comments';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get Comments by Chapter
  static Future<Map<String, dynamic>> getCommentsByChapter(int chapterId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comment/chapter/$chapterId'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Add Comment
  static Future<Map<String, dynamic>> addComment(int chapterId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comment'),
        headers: await _headers(),
        body: jsonEncode({
          'chapterId': chapterId,
          'content': content,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Delete Comment
  static Future<Map<String, dynamic>> deleteComment(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/comment/$id'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }
}
