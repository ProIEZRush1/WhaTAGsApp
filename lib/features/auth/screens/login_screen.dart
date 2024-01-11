import 'dart:isolate';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/colors.dart';
import 'package:com.jee.tag.whatagsapp/common/utils/utils.dart';
import 'package:com.jee.tag.whatagsapp/common/widgets/custom_button.dart';
import 'package:com.jee.tag.whatagsapp/features/auth/controller/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/login-screen';

  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final phoneController = TextEditingController();
  Country? country;

  @override
  void dispose() {
    super.dispose();
    phoneController.dispose();
  }

  void pickCountry() {
    showCountryPicker(
        context: context,
        favorite: ["mx", "us"],
        onSelect: (Country country) {
          setState(() {
            this.country = country;
          });
        });
  }

  void sendPhoneNumber() {
    String phoneNumber = phoneController.text.trim();
    if (country != null && phoneNumber.isNotEmpty) {
      ref
          .read(authControllerProvider)
          .signInWithPhone(context, '+${country!.phoneCode}$phoneNumber');
    } else {
      showSnackBar(context: context, content: 'Fill out all the fields');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Enter your phone number'),
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('WhatsApp will need to verify your phone number.'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: pickCountry,
                child: const Row(
                  children: [
                    Icon(Icons.flag),
                    SizedBox(width: 8),
                    Text('Pick Country')
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Card(
                elevation: 4,
                child: Row(
                  children: [
                    if (country != null) Text('  +${country!.phoneCode}'),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: size.width * 0.7,
                      child: TextField(
                        keyboardType: TextInputType.phone,
                        controller: phoneController,
                        decoration: const InputDecoration(
                          hintText: 'phone number',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              !isKeyboardVisible ? SizedBox(height: size.height * 0.58) : SizedBox(
                height: size.height * 0.01,
              ),
              SizedBox(
                width: 90,
                child: CustomButton(
                  onPressed: sendPhoneNumber,
                  text: 'NEXT',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
