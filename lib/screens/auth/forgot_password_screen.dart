
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../theme/app_theme.dart';
import '../../models/auth_exception.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showError('Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.requestPasswordReset(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _handleError(e);
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _handleError(dynamic error) {
    String message;

    if (error is AuthException) {
      message = error.message;
    } else {
      message = 'Error sending reset email. Please try again.';
      
      if (error.toString().contains('DioException')) {
        if (error.toString().contains('status code of 404')) {
          message = 'Email address not found';
        } else if (error.toString().contains('status code of 500')) {
          message = 'Server error. Please try again later';
        } else if (error.toString().contains('timeout') || error.toString().contains('connection')) {
          message = 'Connection problem. Check your network';
        }
      }
    }

    _showError(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.softShadow,
            ),
            child: Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimaryColor,
              size: 20,
            ),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Reset Password',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      
                      // Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: _emailSent 
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.successColor, AppTheme.successColor.withOpacity(0.8)],
                              )
                            : AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppTheme.mediumShadow,
                        ),
                        child: Icon(
                          _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      // Title and description
                      Text(
                        _emailSent ? 'Check your email' : 'Forgot Password?',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        _emailSent 
                          ? 'We\'ve sent a password reset link to ${_emailController.text.trim()}'
                          : 'Don\'t worry! Enter your email address and we\'ll send you a link to reset your password.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.start,
                      ),

                      const SizedBox(height: 40),

                      if (!_emailSent) ...[
                        // Form container
                        Container(
                          decoration: AppTheme.elevatedCardDecoration,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              // Email field
                              CustomTextField(
                                hint: 'Email address',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.textTertiaryColor,
                                  size: 20,
                                ),
                              ),
                              
                              const SizedBox(height: 32),

                              // Send reset button
                              CustomButton(
                                text: 'Send Reset Link',
                                onPressed: _sendResetEmail,
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Success state
                        Container(
                          decoration: AppTheme.elevatedCardDecoration,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.mail_outline,
                                size: 64,
                                color: AppTheme.successColor,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              Text(
                                'Email sent successfully!',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.successColor,
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              Text(
                                'Check your inbox and follow the instructions to reset your password.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 32),
                              
                              CustomButton(
                                text: 'Back to Login',
                                onPressed: () => context.pop(),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _emailSent = false;
                                    _emailController.clear();
                                  });
                                },
                                child: Text(
                                  'Send to different email',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
