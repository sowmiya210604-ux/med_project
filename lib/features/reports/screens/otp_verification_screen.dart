import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';

class OTPVerificationScreen extends StatelessWidget {
  final String email;
  OTPVerificationScreen(this.email, {super.key});

  final _otp = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Column(
        children: [
          Text('OTP sent to $email'),
          TextField(controller: _otp),
          ElevatedButton(
            onPressed: () async {
              await AuthService.verifyOtp(email, _otp.text);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}
