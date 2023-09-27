import 'dart:io';

import 'package:flutter/material.dart';
import 'package:com.jee.tag.whatagsapp/common/widgets/error.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/screens/login_screen.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/screens/load_messages_screen.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/screens/otp_screen.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/screens/qr_code_screen.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/screens/user_information_screen.dart';
import 'package:com.jee.tag.whatagsapp/features/group/screens/create_group_screen.dart';
import 'package:com.jee.tag.whatagsapp/features/select_contacts/screens/select_contacts_screen.dart';
import 'package:com.jee.tag.whatagsapp/features/chat/screens/mobile_chat_screen.dart';
import 'package:com.jee.tag.whatagsapp/features/status/screens/confirm_status_screen.dart';
import 'package:com.jee.tag.whatagsapp/features/status/screens/status_screen.dart';
import 'package:com.jee.tag.whatagsapp/models/status_model.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case LoginScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      );
    case OTPScreen.routeName:
      final verificationId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (context) => OTPScreen(
          verificationId: verificationId,
        ),
      );
    case UserInformationScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const UserInformationScreen(),
      );
    case QRCodeScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const QRCodeScreen(),
      );
    case LoadMessagesScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const LoadMessagesScreen(),
      );
    case SelectContactsScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const SelectContactsScreen(),
      );
    case MobileChatScreen.routeName:
      final arguments = settings.arguments as Map<String, dynamic>;
      final name = arguments['name'];
      final uid = arguments['uid'];
      final isGroupChat = arguments['isGroupChat'] ?? false;
      final profilePic = arguments['profilePic'];
      return MaterialPageRoute(
        builder: (context) => MobileChatScreen(
          name: name,
          uid: uid,
          isGroupChat: isGroupChat,
          profilePic: profilePic,
        ),
      );
    case ConfirmStatusScreen.routeName:
      final file = settings.arguments as File;
      return MaterialPageRoute(
        builder: (context) => ConfirmStatusScreen(
          file: file,
        ),
      );
    case StatusScreen.routeName:
      final status = settings.arguments as Status;
      return MaterialPageRoute(
        builder: (context) => StatusScreen(
          status: status,
        ),
      );
    case CreateGroupScreen.routeName:
      return MaterialPageRoute(
        builder: (context) => const CreateGroupScreen(),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: ErrorScreen(error: 'This page doesn\'t exist'),
        ),
      );
  }
}
