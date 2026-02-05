import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _phoneError;
  bool _hasShownErrorDialog = false;

  @override
  void initState() {
    super.initState();
    // Listen to auth provider changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowError();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkAndShowError() {
    final authProvider = context.read<AuthProvider>();
    final errorMessage = authProvider.errorMessage;
    
    if (errorMessage != null && !_hasShownErrorDialog && !authProvider.isLoading) {
      final cleanedPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      
      _hasShownErrorDialog = true;
      
      // Check if account is blocked
      if (authProvider.isPhoneBlocked(cleanedPhone)) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _buildBlockedDialog(ctx, cleanedPhone),
        ).then((_) => _hasShownErrorDialog = false);
      } else if (errorMessage.toLowerCase().contains('incorrect password')) {
        final remaining = authProvider.getRemainingAttempts(cleanedPhone);
        showDialog(
          context: context,
          builder: (ctx) => _buildIncorrectPasswordDialog(ctx, errorMessage, remaining, cleanedPhone),
        ).then((_) => _hasShownErrorDialog = false);
      } else if (errorMessage.toLowerCase().contains('mobile number not registered') ||
          errorMessage.toLowerCase().contains('not registered')) {
        showDialog(
          context: context,
          builder: (ctx) => _buildUnregisteredNumberDialog(ctx),
        ).then((_) => _hasShownErrorDialog = false);
      } else if (errorMessage.toLowerCase().contains('not verified')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Verify',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pushNamed('/otp-verification', arguments: {
                  'email': '',
                  'phone': cleanedPhone,
                  'isPasswordReset': false,
                });
              },
            ),
          ),
        );
        _hasShownErrorDialog = false;
      } else {
        showDialog(
          context: context,
          builder: (ctx) => _buildGenericErrorDialog(ctx, errorMessage),
        ).then((_) => _hasShownErrorDialog = false);
      }
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    }

    // Remove any whitespace or special characters
    final cleaned = value.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }

    return null;
  }

  bool get _isPhoneValid {
    final cleaned = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return cleaned.length == 10;
  }

  void _onPhoneChanged(String value) {
    setState(() {
      _phoneError = _validatePhoneNumber(value);
    });
  }

  Future<void> _handleLogin() async {
    print('🔍 Login button pressed');
    
    if (!_formKey.currentState!.validate()) {
      print('🔍 Form validation failed');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final cleanedPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    // Check if phone is blocked before attempting login
    if (authProvider.isPhoneBlocked(cleanedPhone)) {
      print('🔍 Phone is blocked, showing dialog');
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _buildBlockedDialog(ctx, cleanedPhone),
        );
      }
      return;
    }

    print('🔍 Calling authProvider.login');
    final success = await authProvider.login(
      _phoneController.text,
      _passwordController.text,
    );

    print('🔍 Login result: $success');
    print('🔍 Widget mounted: $mounted');

    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      // Trigger error check in next frame
      _hasShownErrorDialog = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkAndShowError();
      });
    }
  }

  Widget _buildIncorrectPasswordDialog(BuildContext context, String message, int remaining, String phone) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 28),
          SizedBox(width: 12),
          Text('Incorrect Password'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The password you entered is incorrect.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: remaining <= 2
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: remaining <= 2 ? AppColors.error : AppColors.warning,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: remaining <= 2 ? AppColors.error : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$remaining attempt${remaining == 1 ? '' : 's'} remaining',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: remaining <= 2
                          ? AppColors.error
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (remaining <= 2) ...[
            const SizedBox(height: 8),
            const Text(
              'Your account will be locked after all attempts are used.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Try Again'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/forgot-password');
          },
          child: const Text('Reset Password'),
        ),
      ],
    );
  }

  Widget _buildBlockedDialog(BuildContext context, String phone) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: AppColors.error, size: 28),
          SizedBox(width: 12),
          Text('Account Locked'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            const Text(
              'Your account has been temporarily locked due to too many failed login attempts.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To unlock your account:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Click "Reset Password" below',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '2. Enter your registered email',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '3. Verify the OTP sent to your email',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '4. Set a new password',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    '5. Login with your new password',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'The OTP will authorize you to change your password.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/forgot-password');
          },
          icon: const Icon(Icons.lock_reset),
          label: const Text('Reset Password'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildUnregisteredNumberDialog(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.person_off_outlined, color: AppColors.error, size: 28),
          SizedBox(width: 12),
          Text('Not Registered'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mobile number not registered.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'This mobile number is not associated with any account. Please check the number or create a new account.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Try Again'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/register');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text('Register'),
        ),
      ],
    );
  }

  Widget _buildGenericErrorDialog(BuildContext context, String message) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 28),
          SizedBox(width: 12),
          Text('Login Failed'),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo and Title
                const AppLogo(size: 100),
                const SizedBox(height: 24),
                // Development Test Credentials Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, 
                               color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Test Credentials',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Phone: ', 
                               style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('1234567890',
                               style: TextStyle(
                                 fontFamily: 'monospace',
                                 color: AppColors.primary,
                               )),
                        ],
                      ),
                      Row(
                        children: [
                          Text('Password: ', 
                               style: TextStyle(fontWeight: FontWeight.w500)),
                          Text('password123',
                               style: TextStyle(
                                 fontFamily: 'monospace',
                                 color: AppColors.primary,
                               )),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Mobile Number Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  onChanged: _onPhoneChanged,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: 'Enter 10-digit mobile number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    counterText: '', // Hide character counter
                    errorText: _phoneError,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: _validatePhoneNumber,
                ),
                const SizedBox(height: 16),
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (value) {
                    setState(() {}); // Trigger rebuild to update button state
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/forgot-password');
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),
                // Login Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final cleanedPhone =
                        _phoneController.text.replaceAll(RegExp(r'\D'), '');
                    final isBlocked = cleanedPhone.length == 10 &&
                        authProvider.isPhoneBlocked(cleanedPhone);
                    final isButtonEnabled = !authProvider.isLoading &&
                        !isBlocked &&
                        _isPhoneValid &&
                        _passwordController.text.length >= 6;

                    return Column(
                      children: [
                        if (isBlocked) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock_outline,
                                    color: AppColors.error),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Account locked. Please reset your password.',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        ElevatedButton(
                          onPressed: isBlocked
                              ? null
                              : (isButtonEnabled ? _handleLogin : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBlocked
                                ? Colors.grey
                                : (isButtonEnabled ? null : Colors.grey),
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(isBlocked ? 'Account Locked' : 'Login'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/register');
                      },
                      child: const Text('Register'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Test Connection Button (Debug)
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/test-connection');
                  },
                  icon: const Icon(Icons.wifi_find, size: 18),
                  label: const Text('Test Backend Connection'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
