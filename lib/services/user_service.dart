import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class UserService {
  static const String baseUrl = 'https://fyp-backend-qzhc.onrender.com/api/users';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Follow a user
  static Future<Map<String, dynamic>> followUser(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$userId/follow'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Unfollow a user
  static Future<Map<String, dynamic>> unfollowUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$userId/unfollow'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Get followers of a user
  static Future<Map<String, dynamic>> getFollowers(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$userId/followers'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Get following of a user
  static Future<Map<String, dynamic>> getFollowing(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$userId/following'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Check if current user is following target user
  static Future<bool> isFollowing(int targetUserId) async {
    try {
      final currentUser = await AuthService.getUser();
      if (currentUser == null) return false;
      
      final response = await getFollowing(currentUser['id']);
      if (response['following'] != null) {
        final List following = response['following'];
        return following.any((u) => u['id'] == targetUserId);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
