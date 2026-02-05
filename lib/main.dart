import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/middleware/auth_guard.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/reports/providers/report_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/otp_verification_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/success_screen.dart';
import 'features/main/screens/main_screen.dart';
import 'test_connection.dart';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: '.env');

  runApp(const MedTrackApp());
}

class MedTrackApp extends StatelessWidget {
  const MedTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: 'Med Track',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (_) => Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    if (authProvider.isLoading) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    return authProvider.isAuthenticated
                        ? const MainScreen()
                        : const LoginScreen();
                  },
                ),
              );

            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());

            case '/register':
              return MaterialPageRoute(builder: (_) => const RegisterScreen());

            case '/otp-verification':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => OTPVerificationScreen(
                  email: args?['email'] ?? '',
                  phone: args?['phone'] ?? '',
                  isPasswordReset: args?['isPasswordReset'] ?? false,
                ),
              );

            case '/forgot-password':
              return MaterialPageRoute(
                builder: (_) => const ForgotPasswordScreen(),
              );

            case '/reset-password':
              return MaterialPageRoute(
                builder: (_) => const ResetPasswordScreen(),
              );

            case '/success':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => SuccessScreen(
                  title: args['title'],
                  message: args['message'],
                  nextRoute: args['nextRoute'],
                ),
              );

            case '/home':
              return createProtectedRoute(const MainScreen(), settings);

            case '/test-connection':
              return MaterialPageRoute(
                builder: (_) => const ConnectionTestScreen(),
              );

            default:
              return MaterialPageRoute(
                builder: (_) => Scaffold(
                  body: Center(
                    child: Text('Route ${settings.name} not found'),
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}
