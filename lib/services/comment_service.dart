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

  // ─── COMMENTS ────────────────────────────────────────────────────────────

  // Get Comments by Chapter
  static Future<Map<String, dynamic>> getCommentsByChapter(int chapterId, {String? type}) async {
    try {
      String url = '$baseUrl/comment/chapter/$chapterId';
      if (type != null) {
        url += '?type=$type';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Add Comment
  static Future<Map<String, dynamic>> addComment(int chapterId, String content, {String type = 'EDITORIAL'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comment'),
        headers: await _headers(),
        body: jsonEncode({
          'chapterId': chapterId,
          'content': content,
          'type': type,
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

  // ─── REVIEWS ─────────────────────────────────────────────────────────────

  // Get Reviews by Chapter
  static Future<Map<String, dynamic>> getReviewsByChapter(int chapterId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/review/chapter/$chapterId'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Add Review
  static Future<Map<String, dynamic>> addReview(
      int chapterId, String content, double rating) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/review'),
        headers: await _headers(),
        body: jsonEncode({
          'chapterId': chapterId,
          'content': content,
          'rating': rating,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Delete Review
  static Future<Map<String, dynamic>> deleteReview(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/review/$id'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }
}
