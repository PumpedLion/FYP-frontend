import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SuggestedEditService {
  static const String baseUrl = 'http://localhost:8000/api/suggested-edits';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Editor submits a suggested edit for a chapter.
  static Future<Map<String, dynamic>> createSuggestedEdit(
    int chapterId,
    String suggestedContent,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: await _headers(),
        body: jsonEncode({
          'chapterId': chapterId,
          'suggestedContent': suggestedContent,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  /// Fetch all suggested edits for a chapter.
  static Future<Map<String, dynamic>> getSuggestedEdits(int chapterId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chapter/$chapterId'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  /// Author accepts a suggestion — chapter content is replaced.
  static Future<Map<String, dynamic>> acceptSuggestedEdit(int id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$id/accept'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  /// Author declines a suggestion — chapter content stays unchanged.
  static Future<Map<String, dynamic>> declineSuggestedEdit(int id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$id/decline'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }
}
