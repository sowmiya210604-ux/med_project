import 'package:flutter/material.dart';
import '../core/config/api_config.dart';
import '../core/services/http_service.dart';

class ConnectionTestWidget extends StatelessWidget {
  const ConnectionTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final res =
            await HttpService.post('${ApiConfig.baseUrl}:3001/health', {});
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res.toString())));
      },
      child: const Text('Test Backend'),
    );
  }
}
