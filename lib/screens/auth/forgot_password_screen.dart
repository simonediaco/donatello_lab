import 'package:Donatello/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/buttons.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../theme/cosmic_theme.dart';
import '../../models/auth_exception.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _forgotPasswordFormKey = GlobalKey<FormState>();
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
      _showError(AppLocalizations.of(context)!.pleaseEnterEmail);
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showError(AppLocalizations.of(context)!.pleaseEnterValidEmail);
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

  void _handleError(dynamic error) {
    String message;

    if (error is AuthException) {
      message = error.message;
    } else {
      message = AppLocalizations.of(context)!.errorSendingResetEmail;

      if (error.toString().contains('DioException')) {
        if (error.toString().contains('status code of 404')) {
          message = AppLocalizations.of(context)!.emailNotFound;
        } else if (error.toString().contains('status code of 500')) {
          message = AppLocalizations.of(context)!.serverError;
        } else if (error.toString().contains('timeout') || error.toString().contains('connection')) {
          message = AppLocalizations.of(context)!.connectionProblem;
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
                              AppLocalizations.of(context)!.resetPassword,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: CosmicTheme.textPrimaryOnDark,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: MediaQuery.of(context).size.height * 0.1),

                        // Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: _emailSent 
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                )
                              : CosmicTheme.buttonGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: (_emailSent ? const Color(0xFF10B981) : CosmicTheme.primaryAccent).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                          _emailSent ? AppLocalizations.of(context)!.checkYourEmail : AppLocalizations.of(context)!.forgotPasswordTitle,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: CosmicTheme.textPrimaryOnDark,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          _emailSent 
                            ? '${AppLocalizations.of(context)!.emailSentTo} ${_emailController.text.trim()}'
                            : AppLocalizations.of(context)!.forgotPasswordSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: CosmicTheme.textSecondaryOnDark,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        if (!_emailSent) ...[
                          // Form container
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
                                  key: _forgotPasswordFormKey,
                                  child: Column(
                                    children: [
                                      // Email field
                                      FloatingLabelTextField(
                                        label: AppLocalizations.of(context)!.emailAddress,
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: CosmicTheme.textSecondary,
                                          size: 20,
                                        ),
                                      ),

                                      const SizedBox(height: 32),

                                      // Send reset button
                                      PrimaryButton(
                                        text: AppLocalizations.of(context)!.sendResetLink,
                                        onPressed: _sendResetEmail,
                                        isLoading: _isLoading,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          // Success state
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
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.mail_outline,
                                      size: 64,
                                      color: const Color(0xFF10B981),
                                    ),

                                    const SizedBox(height: 24),

                                    Text(
                                      AppLocalizations.of(context)!.emailSentSuccessfully,
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    Text(
                                      AppLocalizations.of(context)!.checkInboxInstructions,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: CosmicTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),

                                    const SizedBox(height: 32),

                                    PrimaryButton(
                                      text: AppLocalizations.of(context)!.backToLogin,
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
                                        AppLocalizations.of(context)!.sendToDifferentEmail,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: CosmicTheme.primaryAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

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
        // Top right cosmic shape
        Positioned(
          top: 80,
          right: -20,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value * 0.06,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom left cosmic shape
        Positioned(
          bottom: 100,
          left: -30,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value * 0.04,
                child: Container(
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccent.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
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