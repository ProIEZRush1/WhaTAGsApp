import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl;

  final String _authGroupEndpoint;
  String isLoggedInEndpoint = "";
  String generateQrCodeEndpoint = "";

  final String _messagesGroupEndpoint;
  String listMessagesEndpoint = "";

  ApiService() :
        _baseUrl = 'https://whatsapp-clone-rrr.herokuapp.com',
        _authGroupEndpoint = '/auth',
        _messagesGroupEndpoint = '/messages'
  {
    isLoggedInEndpoint = '$_authGroupEndpoint/isLoggedIn';
    generateQrCodeEndpoint = '$_authGroupEndpoint/qrCode';

    listMessagesEndpoint = '$_messagesGroupEndpoint/list';
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(Uri.parse('$_baseUrl$endpoint'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update data');
    }
  }

  Future<void> delete(String endpoint) async {
    final response = await http.delete(Uri.parse('$_baseUrl$endpoint'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete data');
    }
  }
}
