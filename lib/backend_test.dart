import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const BackendTestApp());
}

class BackendTestApp extends StatelessWidget {
  const BackendTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Backend Test',
      home: BackendTestScreen(),
    );
  }
}

class BackendTestScreen extends StatefulWidget {
  const BackendTestScreen({super.key});

  @override
  State<BackendTestScreen> createState() => _BackendTestScreenState();
}

class _BackendTestScreenState extends State<BackendTestScreen> {
  String _status = 'Not tested';
  bool _loading = false;

  Future<void> _testConnection() async {
    setState(() {
      _loading = true;
      _status = 'Testing...';
    });

    try {
      final response = await http
          .get(
            Uri.parse('http://localhost:5000/api/health-check'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _status = '✅ Connected!\n${data['message']}';
          _loading = false;
        });
      } else {
        setState(() {
          _status = '❌ Error: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Failed: $e';
        _loading = false;
      });
    }
  }

  Future<void> _testRegister() async {
    setState(() {
      _loading = true;
      _status = 'Testing registration...';
    });

    try {
      final response = await http
          .post(
            Uri.parse('http://localhost:5000/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': 'Test User',
              'email': 'test${DateTime.now().millisecondsSinceEpoch}@test.com',
              'phoneNumber': '9876543210',
              'password': 'test123',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        setState(() {
          _status = '✅ Registration successful!\n${data['message']}';
          _loading = false;
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _status = '❌ Error: ${response.statusCode}\n${data['error']}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Failed: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Connection Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_outlined,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'Backend Connection Test',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              if (_loading)
                const CircularProgressIndicator()
              else
                Text(
                  _status,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _loading ? null : _testConnection,
                icon: const Icon(Icons.wifi),
                label: const Text('Test Health Check'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loading ? null : _testRegister,
                icon: const Icon(Icons.app_registration),
                label: const Text('Test Registration'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Backend: http://localhost:5000',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
