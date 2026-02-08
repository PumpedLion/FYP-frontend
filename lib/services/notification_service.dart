import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class NotificationService {
  static const String baseUrl = 'http://localhost:8000/api/notifications';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get Notifications
  static Future<Map<String, dynamic>> getNotifications({String? type, bool? isRead}) async {
    try {
      String url = baseUrl;
      List<String> params = [];
      if (type != null) params.add('type=$type');
      if (isRead != null) params.add('isRead=$isRead');
      
      if (params.isNotEmpty) {
        url += '?' + params.join('&');
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

  // Mark a notification as read
  static Future<Map<String, dynamic>> markAsRead(int id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$id/read'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Mark all notifications as read
  static Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/mark-all-read'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  // Delete a notification
  static Future<Map<String, dynamic>> deleteNotification(int id) async {
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
