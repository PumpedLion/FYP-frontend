import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ManuscriptService {
  static const String baseUrl = 'http://localhost:8000/api/manuscripts';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get My Manuscripts
  static Future<Map<String, dynamic>> getMyManuscripts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-manuscripts'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Create Manuscript
  static Future<Map<String, dynamic>> createManuscript(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Get Manuscript by ID
  static Future<Map<String, dynamic>> getManuscriptById(int id) async {
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

  // Update Manuscript
  static Future<Map<String, dynamic>> updateManuscript(int id, Map<String, dynamic> data) async {
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

  // Delete Manuscript
  static Future<Map<String, dynamic>> deleteManuscript(int id) async {
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

  // Invite Collaborator
  static Future<Map<String, dynamic>> inviteCollaborator(int manuscriptId, String email, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/invite'),
        headers: await _headers(),
        body: jsonEncode({
          'manuscriptId': manuscriptId,
          'email': email,
          'role': role,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Respond to Invitation
  static Future<Map<String, dynamic>> respondToInvitation(int collaborationId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/respond'),
        headers: await _headers(),
        body: jsonEncode({
          'collaborationId': collaborationId,
          'status': status,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  // Get All Manuscripts (Store)
  static Future<Map<String, dynamic>> getAllManuscripts() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'message': 'Failed to fetch manuscripts', 'error': response.body};
      }
    } catch (e) {
      return {'message': 'Error: $e'};
    }
  }

  // Get Dashboard Stats
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'message': 'Failed to fetch stats', 'error': response.body};
      }
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }
}
