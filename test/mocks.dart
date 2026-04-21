import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class TestMocks {
  static http.Client createMockClient(Map<String, dynamic> response, {int statusCode = 200}) {
    final client = MockHttpClient();
    
    // Register fallback for Uri if needed
    registerFallbackValue(Uri());

    when(() => client.post(
      any(),
      headers: any(named: 'headers'),
      body: any(named: 'body'),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), statusCode));

    when(() => client.get(
      any(),
      headers: any(named: 'headers'),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), statusCode));

    when(() => client.patch(
      any(),
      headers: any(named: 'headers'),
      body: any(named: 'body'),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), statusCode));

    when(() => client.delete(
      any(),
      headers: any(named: 'headers'),
    )).thenAnswer((_) async => http.Response(jsonEncode(response), statusCode));

    return client;
  }
}
