
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Donatello/l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../widgets/buttons.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../theme/cosmic_theme.dart';
import '../../models/auth_exception.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final _registerFormKey = GlobalKey<FormState>();
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
    if (!_registerFormKey.currentState!.validate()) {
      return;
    }

    if (_birthdateController.text.trim().isEmpty) {
      _showError(AppLocalizations.of(context)!.enterBirthDateError);
      return;
    }

    if (!_isValidDate(_birthdateController.text.trim())) {
      _showError(AppLocalizations.of(context)!.validDateError);
      return;
    }

    if (!_agreedToTerms) {
      _showError(AppLocalizations.of(context)!.mustAgreeToTermsAndConditions);
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
        _showError(AppLocalizations.of(context)!.registrationFailed);
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
          backgroundColor: const Color(0xFFEF4444),
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
      message = AppLocalizations.of(context)!.errorDuringRegistration;

      if (error.toString().contains('DioException')) {
        if (error.toString().contains('status code of 400')) {
          message = AppLocalizations.of(context)!.invalidData;
        } else if (error.toString().contains('status code of 409')) {
          message = AppLocalizations.of(context)!.emailAlreadyRegistered;
        } else if (error.toString().contains('status code of 500')) {
          message = AppLocalizations.of(context)!.serverError;
        } else if (error.toString().contains('timeout') || error.toString().contains('connection')) {
          message = AppLocalizations.of(context)!.connectionProblem;
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
              primary: CosmicTheme.primaryAccent,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: CosmicTheme.cosmicGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Floating cosmic shapes
              _buildFloatingShapes(),

              SingleChildScrollView(
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
                        const SizedBox(height: 20),

                        // Back button and header
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: CosmicTheme.textPrimaryOnDark,
                                size: 24,
                              ),
                              onPressed: () => context.pop(),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.createAccount,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: CosmicTheme.textPrimaryOnDark,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Welcome text
                        Text(
                          AppLocalizations.of(context)!.joinDonatelloLab,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: CosmicTheme.textPrimaryOnDark,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          AppLocalizations.of(context)!.createAccountSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: CosmicTheme.textSecondaryOnDark,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Registration form
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(32),
                              child: Form(
                                key: _registerFormKey,
                                child: Column(
                                  children: [
                                    // First name field
                                    FloatingLabelTextField(
                                      label: AppLocalizations.of(context)!.firstName,
                                      controller: _firstNameController,
                                      keyboardType: TextInputType.name,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return AppLocalizations.of(context)!.pleaseEnterFirstName;
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Last name field
                                    FloatingLabelTextField(
                                      label: AppLocalizations.of(context)!.lastName,
                                      controller: _lastNameController,
                                      keyboardType: TextInputType.name,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return AppLocalizations.of(context)!.pleaseEnterLastName;
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Email field
                                    FloatingLabelTextField(
                                      label: AppLocalizations.of(context)!.emailAddress,
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return AppLocalizations.of(context)!.pleaseEnterEmail;
                                        }
                                        if (!_isValidEmail(value.trim())) {
                                          return AppLocalizations.of(context)!.pleaseEnterValidEmail;
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Birth date field
                                    FloatingLabelTextField(
                                      label: AppLocalizations.of(context)!.birthDate,
                                      controller: _birthdateController,
                                      readOnly: true,
                                      onTap: _selectDate,
                                      prefixIcon: Icon(
                                        Icons.calendar_today_outlined,
                                        color: CosmicTheme.textSecondary,
                                        size: 20,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return AppLocalizations.of(context)!.pleaseEnterBirthDate;
                                        }
                                        if (!_isValidDate(value.trim())) {
                                          return AppLocalizations.of(context)!.pleaseEnterValidDate;
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Password field
                                    FloatingLabelTextField(
                                      label: AppLocalizations.of(context)!.passwordMinChars,
                                      controller: _passwordController,
                                      isPassword: !_isPasswordVisible,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return AppLocalizations.of(context)!.pleaseEnterPassword;
                                        }
                                        if (value.length < 6) {
                                          return AppLocalizations.of(context)!.passwordMinLength;
                                        }
                                        return null;
                                      },
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible 
                                            ? Icons.visibility_off_outlined 
                                            : Icons.visibility_outlined,
                                          color: CosmicTheme.textSecondary,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Confirm password field
                                    FloatingLabelTextField(
                                      label: AppLocalizations.of(context)!.confirmPassword,
                                      controller: _confirmPasswordController,
                                      isPassword: !_isConfirmPasswordVisible,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return AppLocalizations.of(context)!.pleaseConfirmPassword;
                                        }
                                        if (value != _passwordController.text) {
                                          return AppLocalizations.of(context)!.passwordsDoNotMatch;
                                        }
                                        return null;
                                      },
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isConfirmPasswordVisible 
                                            ? Icons.visibility_off_outlined 
                                            : Icons.visibility_outlined,
                                          color: CosmicTheme.textSecondary,
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
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
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
                                                activeColor: CosmicTheme.primaryAccent,
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
                                                        AppLocalizations.of(context)!.iAgreeToTerms,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                          color: CosmicTheme.textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Wrap(
                                                        children: [
                                                          Text(
                                                            AppLocalizations.of(context)!.readTermsOf,
                                                            style: GoogleFonts.inter(
                                                              fontSize: 12,
                                                              color: CosmicTheme.textSecondary,
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            onTap: () async {
                                                              const url = 'https://donatellolab.com/terms-of-service';
                                                              final uri = Uri.parse(url);
                                                              if (await canLaunchUrl(uri)) {
                                                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                              } else {
                                                                // Fallback per Android
                                                                try {
                                                                  await launchUrl(uri);
                                                                } catch (e) {
                                                                  print('Errore apertura link: $e');
                                                                }
                                                              }
                                                            },
                                                            child: Text(
                                                              AppLocalizations.of(context)!.termsOfUse,
                                                              style: GoogleFonts.inter(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w500,
                                                                color: CosmicTheme.primaryAccent,
                                                                decoration: TextDecoration.underline,
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            AppLocalizations.of(context)!.and,
                                                            style: GoogleFonts.inter(
                                                              fontSize: 12,
                                                              color: CosmicTheme.textSecondary,
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            onTap: () async {
                                                              const url = 'https://donatellolab.com/privacy-policy';
                                                              final uri = Uri.parse(url);
                                                              if (await canLaunchUrl(uri)) {
                                                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                              } else {
                                                                // Fallback per Android
                                                                try {
                                                                  await launchUrl(uri);
                                                                } catch (e) {
                                                                  print('Errore apertura link: $e');
                                                                }
                                                              }
                                                            },
                                                            child: Text(
                                                              AppLocalizations.of(context)!.privacyPolicy,
                                                              style: GoogleFonts.inter(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w500,
                                                                color: CosmicTheme.primaryAccent,
                                                                decoration: TextDecoration.underline,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        AppLocalizations.of(context)!.ageConfirmation,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 12,
                                                          color: CosmicTheme.textSecondary,
                                                          height: 1.4,
                                                        ),
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
                                    PrimaryButton(
                                      text: AppLocalizations.of(context)!.createAccount,
                                      onPressed: _register,
                                      isLoading: _isLoading,
                                    ),

                                    const SizedBox(height: 24),

                                    // Sign in link
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!.alreadyHaveAccount,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: CosmicTheme.textSecondary,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => context.pop(),
                                          child: Text(
                                            AppLocalizations.of(context)!.signIn,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: CosmicTheme.primaryAccent,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingShapes() {
    return Stack(
      children: [
        // Top left cosmic shape
        Positioned(
          top: 60,
          left: -25,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value * 0.05,
                child: Container(
                  width: 70,
                  height: 100,
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccent.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom right violet shape
        Positioned(
          bottom: 120,
          right: -15,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value * 0.06,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
