import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';

class RegistrationScreen extends StatelessWidget {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, obscureText: true),
            ElevatedButton(
              onPressed: () async {
                await AuthService.register(
                  _name.text,
                  _email.text,
                  _password.text,
                );
                Navigator.pushNamed(context, '/verify-otp',
                    arguments: _email.text);
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
