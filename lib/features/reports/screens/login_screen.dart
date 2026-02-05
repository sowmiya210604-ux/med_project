import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  final _email = TextEditingController();
  final _password = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Column(
        children: [
          TextField(controller: _email),
          TextField(controller: _password, obscureText: true),
          ElevatedButton(
            onPressed: () async {
              await AuthService.login(_email.text, _password.text);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
