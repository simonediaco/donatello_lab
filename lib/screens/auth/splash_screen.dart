import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/auth_service.dart';
import '../../theme/cosmic_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _loadingController;
  late AnimationController _backgroundController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _loadingOpacity;
  late Animation<double> _backgroundOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _loadingOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    _backgroundOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    // Start background animation immediately
    _backgroundController.forward();

    // Small delay then logo animation
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    // Start loading animation after logo
    await Future.delayed(const Duration(milliseconds: 800));
    _loadingController.forward();

    // Wait for animations to complete
    await Future.delayed(const Duration(milliseconds: 1500));

    // Check auth and navigate
    await _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.getCurrentUser();

      if (mounted) {
        if (user != null) {
          ref.read(currentUserProvider.notifier).state = user;
          context.go('/home');
        } else {
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loadingController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CosmicTheme.gradientCosmicStart.withOpacity(_backgroundOpacity.value),
                  CosmicTheme.gradientCosmicMid.withOpacity(_backgroundOpacity.value),
                  CosmicTheme.gradientCosmicEnd.withOpacity(_backgroundOpacity.value),
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Floating geometric shapes in background
                  _buildFloatingShapes(),

                  // Main content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo container with modern design
                        AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _logoScale.value,
                              child: Opacity(
                                opacity: _logoOpacity.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: CosmicTheme.cosmicShadow,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Image.asset(
                                      'assets/images/logos/logo-donatello.png',
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // App name with elegant typography
                        AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _logoOpacity.value,
                              child: Column(
                                children: [
                                  Text(
                                    'Donatello',
                                    style: GoogleFonts.inter(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: CosmicTheme.textPrimaryOnDark,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lab',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: CosmicTheme.primaryAccentOnDark,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 48),

                        // Loading indicator
                        AnimatedBuilder(
                          animation: _loadingController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _loadingOpacity.value,
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        CosmicTheme.primaryAccentOnDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Preparing your experience...',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: CosmicTheme.textSecondaryOnDark,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingShapes() {
    return Stack(
      children: [
        // Top right circle
        Positioned(
          top: -50,
          right: -30,
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Opacity(
                opacity: _backgroundOpacity.value * 0.1,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom left rounded rectangle
        Positioned(
          bottom: -40,
          left: -20,
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Opacity(
                opacity: _backgroundOpacity.value * 0.08,
                child: Container(
                  width: 80,
                  height: 140,
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccentOnDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            },
          ),
        ),

        // Center right small circle
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          right: -15,
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Opacity(
                opacity: _backgroundOpacity.value * 0.06,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: CosmicTheme.gradientCosmicMid,
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