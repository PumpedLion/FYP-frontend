import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';

class PaymentService {
  static const String _baseUrl = 'https://fyp-backend-qzhc.onrender.com/api/payments';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Check if the current user has purchased a manuscript
  static Future<bool> checkPurchase(int manuscriptId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/check/$manuscriptId'),
        headers: await _headers(),
      );
      final data = jsonDecode(response.body);
      return data['purchased'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Initiate a Khalti payment for a manuscript
  /// Returns { payment_url, pidx } on success, or { message } on error
  static Future<Map<String, dynamic>> initKhaltiPayment(int manuscriptId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/khalti/init'),
        headers: await _headers(),
        body: jsonEncode({'manuscriptId': manuscriptId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  /// Verify the Khalti payment after WebView redirect
  static Future<Map<String, dynamic>> verifyKhaltiPayment(String pidx, int manuscriptId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/khalti/verify'),
        headers: await _headers(),
        body: jsonEncode({'pidx': pidx, 'manuscriptId': manuscriptId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  /// Initiate an eSewa payment
  /// Returns { payment_url, formData } on success
  static Future<Map<String, dynamic>> initEsewaPayment(int manuscriptId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/esewa/init'),
        headers: await _headers(),
        body: jsonEncode({'manuscriptId': manuscriptId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  /// Verify the eSewa payment with the base64 data returned by eSewa
  static Future<Map<String, dynamic>> verifyEsewaPayment(String data, int manuscriptId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/esewa/verify'),
        headers: await _headers(),
        body: jsonEncode({'data': data, 'manuscriptId': manuscriptId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  /// Verify eSewa payment server-side using the stored transaction UUID
  static Future<Map<String, dynamic>> verifyEsewaByManuscript(int manuscriptId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/esewa/verify-by-manuscript'),
        headers: await _headers(),
        body: jsonEncode({'manuscriptId': manuscriptId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  /// Verify eSewa payment using the refId returned by the eSewa mobile SDK
  static Future<Map<String, dynamic>> verifyEsewaByRefId({
    required int manuscriptId,
    required String refId,
    required String amount,
    required String productId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/esewa/verify-by-ref'),
        headers: await _headers(),
        body: jsonEncode({
          'manuscriptId': manuscriptId,
          'refId': refId,
          'amount': amount,
          'productId': productId,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Network error: $e'};
    }
  }

  /// Fetch purchase history for the current user
  static Future<List<dynamic>> getPurchaseHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/history'),
        headers: await _headers(),
      );
      final data = jsonDecode(response.body);
      return data['purchases'] ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Open the browser to download the PDF invoice for a purchased manuscript
  static Future<void> downloadInvoice(int manuscriptId) async {
    final token = await AuthService.getToken();
    if (token == null) return;
    final url = 'https://fyp-backend-qzhc.onrender.com/api/payments/invoice/$manuscriptId?token=$token';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
