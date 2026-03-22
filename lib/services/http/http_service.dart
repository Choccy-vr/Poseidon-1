import 'package:http/http.dart' as http;
import 'dart:convert';

class HttpService {
  static Future<String> get(String url) async {
    final response = await http.get(Uri.parse(url));
    return response.body;
  }

  static Future<Map<String, dynamic>> getJson(String url) async {
    final response = await http.get(Uri.parse(url));
    return jsonDecode(response.body);
  }

  static Future<String> post(String url, Map<String, dynamic> body) async {
    final response = await http.post(Uri.parse(url), body: jsonEncode(body));
    return response.body;
  }

  static Future<Map<String, dynamic>> postJson(
    String url,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(Uri.parse(url), body: jsonEncode(body));
    return jsonDecode(response.body);
  }

  static Future<String> put(String url, Map<String, dynamic> body) async {
    final response = await http.put(Uri.parse(url), body: jsonEncode(body));
    return response.body;
  }

  static Future<Map<String, dynamic>> putJson(
    String url,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(Uri.parse(url), body: jsonEncode(body));
    return jsonDecode(response.body);
  }

  static Future<String> delete(String url) async {
    final response = await http.delete(Uri.parse(url));
    return response.body;
  }

  static Future<Map<String, dynamic>> deleteJson(String url) async {
    final response = await http.delete(Uri.parse(url));
    return jsonDecode(response.body);
  }
}
