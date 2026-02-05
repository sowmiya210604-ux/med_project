import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String phone;
  final bool isPasswordReset;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.phone,
    this.isPasswordReset = false,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  int _incorrectAttempts = 0;
  final int _maxAttempts = 5;
  bool _canResend = false;
  int _resendCountdown = 30;
  bool _isLocked = false; // Lock state after 5 wrong attempts

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    _canResend = false;
    _resendCountdown = 30;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
          if (_resendCountdown <= 0) {
            _canResend = true;
          }
        });
        return _resendCountdown > 0;
      }
      return false;
    });
  }

  String _getOTP() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _handleVerifyOTP() async {
    final otp = _getOTP();

    if (otp.length != 6) {
      _showMessage('Please enter complete 6-digit OTP', isError: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    bool success;

    // Check if this is password reset flow
    if (widget.isPasswordReset) {
      success = await authProvider.verifyPasswordResetOTP(otp);
    } else {
      success = await authProvider.verifyOTP(otp);
    }

    if (success && mounted) {
      // Show success message
      _showMessage(
        widget.isPasswordReset
            ? 'OTP verified! You can now set your new password.'
            : 'Email verified successfully!',
        isError: false,
      );

      // Navigate after short delay
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // Check if this is password reset flow
      if (widget.isPasswordReset) {
        Navigator.of(context).pushReplacementNamed('/reset-password');
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/success',
          (route) => false,
          arguments: {
            'title': 'Registration Successful!',
            'message': 'Your account has been created successfully.',
            'nextRoute': '/login',
          },
        );
      }
    } else {
      setState(() {
        _incorrectAttempts++;
      });

      if (_incorrectAttempts >= _maxAttempts) {
        setState(() {
          _isLocked = true;
          _canResend = true; // Allow immediate resend when locked
        });

        if (mounted) {
          _showMessage(
            'Maximum attempts exceeded. Please click "Resend OTP" to get a new code.',
            isError: true,
          );
          // Clear OTP fields
          for (var controller in _otpControllers) {
            controller.clear();
          }
        }
      } else {
        if (mounted) {
          final errorMsg = authProvider.errorMessage ?? 'Invalid OTP';

          // Handle already verified case
          if (errorMsg.contains('already verified') ||
              errorMsg.contains('Please login')) {
            _showMessage(
              'Your account is already verified. Redirecting to login...',
              isError: false,
            );

            // Redirect to login after 2 seconds
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            });
          }
          // Handle OTP expired case
          else if (errorMsg.contains('expired')) {
            setState(() {
              _isLocked = true;
              _canResend = true;
            });
            _showMessage(
              'OTP has expired. Please click "Resend OTP" to get a new code.',
              isError: true,
            );
          }
          // Handle max attempts from backend
          else if (errorMsg.contains('Maximum verification attempts')) {
            setState(() {
              _isLocked = true;
              _canResend = true;
            });
            _showMessage(
              'Maximum attempts exceeded on server. Please click "Resend OTP" to get a new code.',
              isError: true,
            );
          }
          // Handle no OTP found
          else if (errorMsg.contains('No OTP found')) {
            setState(() {
              _canResend = true;
            });
            _showMessage(
              'No valid OTP found. Please click "Resend OTP".',
              isError: true,
            );
          }
          // Regular invalid OTP
          else {
            _showMessage(
              '$errorMsg. ${_maxAttempts - _incorrectAttempts} attempts remaining.',
              isError: true,
            );
          }
        }
      }
    }
  }

  Future<void> _handleResendOTP() async {
    if (!_canResend) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resendOTP(
      purpose: widget.isPasswordReset ? 'password_reset' : null,
    );

    if (success && mounted) {
      setState(() {
        _incorrectAttempts = 0; // Reset attempt counter on successful resend
        _isLocked = false; // Unlock verification
      });

      _showMessage('New OTP sent successfully!', isError: false);
      _startResendCountdown();

      // Clear OTP fields
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    } else if (mounted) {
      final errorMsg = authProvider.errorMessage ?? 'Failed to resend OTP';

      // Handle already verified case
      if (errorMsg.contains('already verified') ||
          errorMsg.contains('Please login')) {
        _showMessage(
          'Your account is already verified. Redirecting to login...',
          isError: false,
        );

        // Redirect to login after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        });
      } else {
        _showMessage(errorMsg, isError: true);
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Enter Verification Code',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                widget.isPasswordReset
                    ? 'We have sent a verification code to'
                    : 'We have sent a verification code to',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Password reset info box
              if (widget.isPasswordReset)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This OTP authorizes you to reset your password',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    child: TextFormField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: Theme.of(context).textTheme.headlineMedium,
                      decoration: const InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              // Locked State Warning
              if (_isLocked)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline, color: AppColors.error),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'OTP verification locked. Click "Resend OTP" to get a new code.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Attempt Counter
              if (_incorrectAttempts > 0 && !_isLocked)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Incorrect attempts: $_incorrectAttempts/$_maxAttempts',
                          style: const TextStyle(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // Verify Button
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final isButtonEnabled = !authProvider.isLoading && !_isLocked;

                  return ElevatedButton(
                    onPressed: isButtonEnabled ? _handleVerifyOTP : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLocked ? Colors.grey : null,
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isLocked ? 'Locked - Resend OTP' : 'Verify OTP'),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_canResend)
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return TextButton(
                          onPressed:
                              authProvider.isLoading ? null : _handleResendOTP,
                          child: const Text('Resend OTP'),
                        );
                      },
                    )
                  else
                    Text(
                      'Resend in $_resendCountdown s',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
