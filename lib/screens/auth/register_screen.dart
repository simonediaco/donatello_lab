import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../theme/app_theme.dart';
import '../../models/auth_exception.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdateController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_firstNameController.text.trim().isEmpty) {
      _showError('Please enter your first name');
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      _showError('Please enter your last name');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showError('Please enter a valid email address');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError('Please enter a password');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters long');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    if (_birthdateController.text.trim().isEmpty) {
      _showError('Please enter your birth date');
      return;
    }

    if (!_isValidDate(_birthdateController.text.trim())) {
      _showError('Please enter a valid date (dd/mm/yyyy)');
      return;
    }

    if (!_agreedToTerms) {
      _showError('You must agree to the terms and conditions');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.register({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'password_confirm': _confirmPasswordController.text,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'birth_date': _formatDateForApi(_birthdateController.text.trim()),
      });

      if (user != null && mounted) {
        ref.read(currentUserProvider.notifier).state = user;
        context.go('/onboarding');
      } else {
        _showError('Registration failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        _handleRegisterError(e);
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

  bool _isValidDate(String date) {
    try {
      final parts = date.split('/');
      if (parts.length != 3) return false;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      if (day < 1 || day > 31) return false;
      if (month < 1 || month > 12) return false;
      if (year < 1900 || year > DateTime.now().year) return false;
      
      final birthDate = DateTime(year, month, day);
      final today = DateTime.now();
      final age = today.year - birthDate.year;
      if (age < 13) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  String _formatDateForApi(String date) {
    final parts = date.split('/');
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
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

  void _handleRegisterError(dynamic error) {
    String message;

    if (error is AuthException) {
      message = error.message;
    } else {
      message = 'Error during registration. Please try again.';

      if (error.toString().contains('DioException')) {
        if (error.toString().contains('status code of 400')) {
          message = 'Invalid data. Please check the entered fields';
        } else if (error.toString().contains('status code of 409')) {
          message = 'Email already registered. Try with another email';
        } else if (error.toString().contains('status code of 500')) {
          message = 'Server error. Please try again later';
        } else if (error.toString().contains('timeout') || error.toString().contains('connection')) {
          message = 'Connection problem. Check your network';
        }
      }
    }

    _showError(message);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthdateController.text = 
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
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
          'Create Account',
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
                      // Header
                      Text(
                        'Join Donatello Lab',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your account to start finding perfect gifts',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 40),

                      // Form container
                      Container(
                        decoration: AppTheme.elevatedCardDecoration,
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            // Name fields
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    hint: 'First name',
                                    controller: _firstNameController,
                                    keyboardType: TextInputType.name,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: CustomTextField(
                                    hint: 'Last name',
                                    controller: _lastNameController,
                                    keyboardType: TextInputType.name,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),

                            // Email field
                            CustomTextField(
                              hint: 'Email address',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            
                            const SizedBox(height: 20),

                            // Birth date field
                            GestureDetector(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      color: AppTheme.textTertiaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _birthdateController.text.isEmpty 
                                          ? 'Birth date (dd/mm/yyyy)'
                                          : _birthdateController.text,
                                        style: TextStyle(
                                          color: _birthdateController.text.isEmpty 
                                            ? AppTheme.textTertiaryColor 
                                            : AppTheme.textPrimaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),

                            // Password field
                            CustomTextField(
                              hint: 'Password (min. 6 characters)',
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
                            
                            const SizedBox(height: 20),

                            // Confirm password field
                            CustomTextField(
                              hint: 'Confirm password',
                              controller: _confirmPasswordController,
                              isPassword: !_isConfirmPasswordVisible,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible 
                                    ? Icons.visibility_off_outlined 
                                    : Icons.visibility_outlined,
                                  color: AppTheme.textTertiaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            
                            const SizedBox(height: 24),

                            // Terms and conditions
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: _agreedToTerms,
                                        onChanged: (value) {
                                          setState(() => _agreedToTerms = value ?? false);
                                        },
                                        activeColor: AppTheme.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 12, left: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'I agree to the terms and conditions',
                                                style: Theme.of(context).textTheme.labelLarge,
                                              ),
                                              const SizedBox(height: 4),
                                              GestureDetector(
                                                onTap: () {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Terms of use will be available soon'),
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  'Read terms of use and privacy policy',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: AppTheme.primaryColor,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'I confirm that I am at least 13 years old and agree that my data will be processed according to the privacy policy to receive personalized gift ideas.',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),

                            // Register button
                            CustomButton(
                              text: 'Create Account',
                              onPressed: _register,
                              isLoading: _isLoading,
                            ),
                            
                            const SizedBox(height: 24),

                            // Sign in link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                GestureDetector(
                                  onTap: () => context.pop(),
                                  child: Text(
                                    'Sign In',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
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