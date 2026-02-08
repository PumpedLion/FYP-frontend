import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ChapterService {
  static const String baseUrl = 'http://localhost:8000/api/chapters';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Create Chapter
  static Future<Map<String, dynamic>> createChapter(int manuscriptId, String title, {String? content, int order = 0}) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: await _headers(),
        body: jsonEncode({
          'manuscriptId': manuscriptId,
          'title': title,
          'content': content,
          'order': order,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Get Chapters by Manuscript
  static Future<Map<String, dynamic>> getChaptersByManuscript(int manuscriptId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/manuscript/$manuscriptId'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Get Chapter by ID
  static Future<Map<String, dynamic>> getChapterById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Update Chapter
  static Future<Map<String, dynamic>> updateChapter(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$id'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Delete Chapter
  static Future<Map<String, dynamic>> deleteChapter(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }
}
