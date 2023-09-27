import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/screens/login_screen.dart';

class ApiService {
  final String _baseUrl;

  final String _authGroupEndpoint;
  String reviveClientEndpoint = "";
  String isLoggedInEndpoint = "";
  String generateQrCodeEndpoint = "";

  final String _messagesGroupEndpoint;
  String loadMessagesEndpoint = "";
  String sendMessageEndpoint = "";

  ApiService()
      :
        _baseUrl = 'https://horribly-vital-gar.ngrok-free.app',
        _authGroupEndpoint = '/auth',
        _messagesGroupEndpoint = '/messages' {
    reviveClientEndpoint = '$_authGroupEndpoint/revive';
    isLoggedInEndpoint = '$_authGroupEndpoint/logged';
    generateQrCodeEndpoint = '$_authGroupEndpoint/qr';

    loadMessagesEndpoint = '$_messagesGroupEndpoint/load';
    sendMessageEndpoint = '$_messagesGroupEndpoint/send';
  }

  Map<String, String> _defaultHeaders = {
    'ngrok-skip-browser-warning': 'true',
    'Content-Type': 'application/json',
  };

  bool checkSuccess(Map<String, dynamic> response) {
    final success = response['success'];
    return success;
  }

  Future<bool> checkIfLoggedIn(BuildContext context, WidgetRef ref,
      Map<String, dynamic> response) async {
    final loggedIn = response['loggedIn'];
    if (!loggedIn) {
      final authController = ref.read(authControllerProvider);
      await authController.authRepository.auth.signOut();

      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
            (route) => false,
      );

      return false;
    }
    return true;
  }

  Map<String, dynamic> decodeData(Map<String, dynamic> response) {
    final data = response['data'];
    return data;
  }

  Future<Map<String, dynamic>> get(BuildContext context, WidgetRef ref,
      String endpoint) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _defaultHeaders,
    );

    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);
      return decodeData(decodedBody);
    }
    else {
      throw Exception('Failed to get data');
    }
  }

  Future<Map<String, dynamic>> post(BuildContext context, WidgetRef ref, String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _defaultHeaders,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);
      return decodeData(decodedBody);
    }
    else {
      throw Exception('Failed to get data');
    }
  }

  Future<Map<String, dynamic>> put(BuildContext context, WidgetRef ref, String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _defaultHeaders,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);
      return decodeData(decodedBody);
    }
    else {
      throw Exception('Failed to get data');
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
