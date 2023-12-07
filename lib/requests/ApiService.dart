import 'dart:io';
import 'package:com.jee.tag.whatagsapp/features/chat/widgets/messages/message_utils.dart';
import 'package:com.jee.tag.whatagsapp/utils/DeviceUtils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/screens/login_screen.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  final Dio _dio;
  final String _baseUrl;

  final String _authGroupEndpoint;
  String reviveClientEndpoint = "";
  String isLoggedInEndpoint = "";
  String logOutEndpoint = "";
  String generateQrCodeEndpoint = "";

  final String _messagesGroupEndpoint;
  String sendMessageEndpoint = "";
  String sendMediaMessageEndpoint = "";
  String markAllAsReadEndpoint = "";
  String downloadMessageEndpoint = "";

  ApiService()
      : _dio = Dio(),
        _baseUrl = 'https://horribly-vital-gar.ngrok-free.app',
        // _baseUrl = 'http://localhost:300',
        // _baseUrl = 'http://192.168.1.75:3000',
        //_baseUrl = 'https://whatsapp.tag.org',
        _authGroupEndpoint = '/auth',
        _messagesGroupEndpoint = '/messages' {
    reviveClientEndpoint = '$_authGroupEndpoint/revive';
    isLoggedInEndpoint = '$_authGroupEndpoint/logged';
    logOutEndpoint = '$_authGroupEndpoint/logout';
    generateQrCodeEndpoint = '$_authGroupEndpoint/qr';

    sendMessageEndpoint = '$_messagesGroupEndpoint/send';
    sendMediaMessageEndpoint = '$_messagesGroupEndpoint/sendMedia';
    markAllAsReadEndpoint = '$_messagesGroupEndpoint/markAllAsRead';
    downloadMessageEndpoint = '$_messagesGroupEndpoint/download';

    // Add default headers here if needed
    _dio.options.headers['ngrok-skip-browser-warning'] = 'true';
    _dio.options.headers['Content-Type'] = 'application/json';
  }

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
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          LoginScreen.routeName,
          (route) => false,
        );
      }

      return false;
    }
    return true;
  }

  Map<String, dynamic> decodeData(Map<String, dynamic> response) {
    final data = response['data'];
    return data;
  }

  Future<Map<String, dynamic>> get(
      BuildContext context, WidgetRef ref, String endpoint) async {
    // debugPrint('$_baseUrl$endpoint');
    try {
      debugPrint('$_baseUrl$endpoint');
      final response = await _dio.get('$_baseUrl$endpoint');
      if (response.statusCode == 200) {
        return decodeData(response.data);
      } else {
        throw Exception('Failed to get data');
      }
    } catch (e) {
      throw Exception('Failed to get data: $e URL: $_baseUrl$endpoint');
    }
  }

  Future<Map<String, dynamic>> logout(
      WidgetRef ref, BuildContext context) async {
    try {
      final deviceToken = await DeviceUtils.getDeviceId();
      final firebaseUid =
          ref.read(authControllerProvider).authRepository.auth.currentUser!.uid;

      final response = await _dio.get(
          '$_baseUrl$logOutEndpoint?deviceToken=$deviceToken&firebaseUid=$firebaseUid&uuid=${const Uuid().v4()}');
      if (response.statusCode == 200) {
        final authController = ref.read(authControllerProvider);
        await authController.authRepository.auth.signOut();
        Hive.deleteFromDisk();
        MessageUtils.deleteAllDownload();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            LoginScreen.routeName,
            (route) => false,
          );
        }
        return decodeData(response.data);
      } else {
        throw Exception('Failed to get data');
      }
    } catch (e) {
      throw Exception('Failed to get data: $e URL: $_baseUrl$logOutEndpoint');
    }
  }

  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('$_baseUrl$endpoint', data: data);
      if (response.statusCode == 200) {
        return decodeData(response.data);
      } else {
        throw Exception('Failed to post data');
      }
    } catch (e) {
      throw Exception('Failed to post data: $e');
    }
  }

  Future<Map<String, dynamic>> postMultipart(
      String endpoint, Map<String, dynamic> data) async {
    try {
      FormData formData = FormData.fromMap(data);
      final response = await _dio.post('$_baseUrl$endpoint', data: formData);
      if (response.statusCode == 200) {
        return decodeData(response.data);
      } else {
        throw Exception('Failed to post data');
      }
    } catch (e) {
      throw Exception('Failed to post data: $e');
    }
  }

  Future<Map<String, dynamic>> put(BuildContext context, WidgetRef ref,
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('$_baseUrl$endpoint', data: data);
      if (response.statusCode == 200) {
        return decodeData(response.data);
      } else {
        throw Exception('Failed to put data');
      }
    } catch (e) {
      throw Exception('Failed to put data: $e');
    }
  }

  Future<void> delete(String endpoint) async {
    try {
      final response = await _dio.delete('$_baseUrl$endpoint');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete data');
      }
    } catch (e) {
      throw Exception('Failed to delete data: $e');
    }
  }
}
