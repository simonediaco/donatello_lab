import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../theme/app_theme.dart';
import '../../models/auth_exception.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

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
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showError('Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        ref.read(currentUserProvider.notifier).state = user;
        context.go('/home');
      } else {
        _showError('Login failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _handleLoginError(e);
      }
    } finally {
      if (mounted) {
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

  void _handleLoginError(dynamic error) {
    String message;

    if (error is AuthException) {
      message = error.message;
    } else {
      message = 'Connection error. Please try again.';

      if (error.toString().contains('DioException')) {
        if (error.toString().contains('status code of 400') || 
            error.toString().contains('status code of 401') ||
            error.toString().contains('401') || 
            error.toString().contains('Unauthorized')) {
          message = 'Incorrect email or password';
        } else if (error.toString().contains('status code of 404') || error.toString().contains('404')) {
          message = 'Service unavailable';
        } else if (error.toString().contains('status code of 500') || error.toString().contains('500')) {
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Hero section with app branding
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App logo
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: AppTheme.mediumShadow,
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Welcome text
                          Text(
                            'Welcome back',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            'Sign in to continue to Donatello Lab',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Login form
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          decoration: AppTheme.elevatedCardDecoration,
                          padding: const EdgeInsets.all(32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email field
                                CustomTextField(
                                  hint: 'Email address',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                
                                const SizedBox(height: 20),

                                // Password field
                                CustomTextField(
                                  hint: 'Password',
                                  controller: _passwordController,
                                  isPassword: !_isPasswordVisible,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible 
                                        ? Icons.visibility_off_outlined 
                                        : Icons.visibility_outlined,
                                      color: AppTheme.textTertiaryColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Forgot password link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => context.push('/forgot-password'),
                                    child: Text(
                                      'Forgot password?',
                                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Login button
                                CustomButton(
                                  text: 'Sign In',
                                  onPressed: _login,
                                  isLoading: _isLoading,
                                ),

                                const SizedBox(height: 24),

                                // Divider
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: AppTheme.textTertiaryColor.withOpacity(0.3),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'or',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: AppTheme.textTertiaryColor.withOpacity(0.3),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Create account button
                                OutlinedButton(
                                  onPressed: () => context.push('/register'),
                                  child: const Text('Create Account'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom spacer
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}