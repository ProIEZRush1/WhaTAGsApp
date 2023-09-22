import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl;

  final String _authGroupEndpoint;
  String isLoggedInEndpoint = "";
  String generateQrCodeEndpoint = "";

  final String _messagesGroupEndpoint;
  String listMessagesEndpoint = "";
  String listChatMessagesEndpoint = "";

  ApiService() :
        _baseUrl = 'https://horribly-vital-gar.ngrok-free.app',
        _authGroupEndpoint = '/auth',
        _messagesGroupEndpoint = '/messages'
  {
    isLoggedInEndpoint = '$_authGroupEndpoint/logged';
    generateQrCodeEndpoint = '$_authGroupEndpoint/qr';

    listMessagesEndpoint = '$_messagesGroupEndpoint/list';
    listChatMessagesEndpoint = '$_messagesGroupEndpoint/chat/list';
  }

  Map<String, String> _defaultHeaders = {
    'ngrok-skip-browser-warning': 'true',
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _defaultHeaders,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(response.body);
      throw Exception('Failed to get data');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _defaultHeaders,
      body: json.encode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to post data');
    }
  }

  Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _defaultHeaders,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update data');
    }
  }

  Future<void> delete(String endpoint) async {
    final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _defaultHeaders,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete data');
    }
  }
}
