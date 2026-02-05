import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Auth guard that wraps protected screens
/// Redirects to login if user is not authenticated
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Redirect to login if not authenticated
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show protected content
        return child;
      },
    );
  }
}

/// Helper function to create protected routes
Route<dynamic>? createProtectedRoute(
  Widget screen,
  RouteSettings settings,
) {
  return MaterialPageRoute(
    builder: (_) => AuthGuard(child: screen),
    settings: settings,
  );
}
