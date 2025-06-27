
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Donatello/l10n/app_localizations.dart';
import '../../theme/cosmic_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;

  late List<OnboardingPage> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _finishOnboarding() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    _pages = [
      OnboardingPage(
        icon: Icons.auto_awesome,
        title: AppLocalizations.of(context)!.welcomeToDonatelloLabOnboarding,
        description: AppLocalizations.of(context)!.discoverGiftPower,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
      ),
      OnboardingPage(
        icon: Icons.people_outline,
        title: AppLocalizations.of(context)!.createRecipientProfile,
        description: AppLocalizations.of(context)!.addLovedOnesProfiles,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
      ),
      OnboardingPage(
        icon: Icons.psychology,
        title: AppLocalizations.of(context)!.artificialIntelligence,
        description: AppLocalizations.of(context)!.aiAnalyzesInterests,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
        ),
      ),
      OnboardingPage(
        icon: Icons.favorite_outline,
        title: AppLocalizations.of(context)!.startCreatingMagic,
        description: AppLocalizations.of(context)!.readyToTransform,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFF10B981)],
        ),
      ),
    ];
    
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
              
              // Main content
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Skip button
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentPage > 0)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: CosmicTheme.textPrimaryOnDark,
                                ),
                                onPressed: _previousPage,
                              ),
                            )
                          else
                            const SizedBox(width: 48),
                          TextButton(
                            onPressed: _finishOnboarding,
                            child: Text(
                              AppLocalizations.of(context)!.skip,
                              style: GoogleFonts.inter(
                                color: CosmicTheme.textSecondaryOnDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Page content
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: _pages.length,
                        itemBuilder: (context, index) {
                          return _buildPage(_pages[index]);
                        },
                      ),
                    ),

                    // Page indicators and navigation
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          // Page indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _pages.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: index == _currentPage ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: index == _currentPage
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),

                          // Next/Finish button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: _pages[_currentPage].gradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _pages[_currentPage].gradient.colors.first.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _nextPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _currentPage == _pages.length - 1 ? AppLocalizations.of(context)!.startExclamation : AppLocalizations.of(context)!.continue_,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      _currentPage == _pages.length - 1 
                                        ? Icons.rocket_launch 
                                        : Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: page.gradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: page.gradient.colors.first.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: CosmicTheme.textPrimaryOnDark,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            page.description,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: CosmicTheme.textSecondaryOnDark,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingShapes() {
    return Stack(
      children: [
        // Top right shape
        Positioned(
          top: 100,
          right: -30,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value * 0.1,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _pages[_currentPage].gradient.colors.first,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ),
        
        // Bottom left shape
        Positioned(
          bottom: 150,
          left: -40,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value * 0.08,
                child: Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    color: _pages[_currentPage].gradient.colors.last.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(25),
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

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
