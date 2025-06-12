import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/cosmic_theme.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../services/api_service.dart';
import '../../models/recipient.dart';
import '../../services/search_history_service.dart';

class GiftIntroScreen extends ConsumerStatefulWidget {
  const GiftIntroScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GiftIntroScreen> createState() => _GiftIntroScreenState();
}

class _GiftIntroScreenState extends ConsumerState<GiftIntroScreen>
    with TickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _floatingController;

  String? _lastSearchSummary;
  bool _hasLastSearch = false;

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

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animationController.forward();

    _loadLastSearch();
  }

  Future<void> _loadLastSearch() async {
    final hasSearch = await SearchHistoryService.hasLastSearch();
    if (hasSearch) {
      final summary = await SearchHistoryService.getLastSearchSummary();
      setState(() {
        _hasLastSearch = true;
        _lastSearchSummary = summary ?? 'Guarda la tua ultima ricerca';
      });
    } else {
      setState(() {
        _hasLastSearch = false;
        _lastSearchSummary = null;
      });
    }
  }

  void _openLastSearch() async {
    final lastSearch = await SearchHistoryService.getLastSearch();
    if (lastSearch != null) {
      // Navigate to results page with last search parameters
      context.go('/results', extra: lastSearch);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nessuna ricerca precedente trovata.',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: CosmicTheme.primaryAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    super.dispose();
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
                        // Welcome section without logo
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.25,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Welcome text
                              Text(
                                'Trova il regalo perfetto',
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: CosmicTheme.textPrimaryOnDark,
                                  letterSpacing: -1,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 24),

                              Text(
                                '"Ogni regalo racconta una storia scritta nelle stelle"',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: CosmicTheme.textSecondaryOnDark.withOpacity(0.8),
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        // Cards section with white background
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Per chi stai cercando un regalo?',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: CosmicTheme.textPrimary,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Existing recipient option
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => context.push('/select-recipient'),
                                        borderRadius: BorderRadius.circular(14),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.people,
                                                color: CosmicTheme.primaryAccent,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Qualcuno che conosco già',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w600,
                                                        color: CosmicTheme.textPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Scegli tra i destinatari salvati',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13,
                                                        color: CosmicTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color: CosmicTheme.textSecondary,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // New recipient option with cosmic accent
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: CosmicTheme.buttonGradient,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: CosmicTheme.lightShadow,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => context.go('/gift-wizard'),
                                        borderRadius: BorderRadius.circular(14),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.person_add,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Inizia il wizard',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Crea idee regalo personalizzate',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13,
                                                        color: Colors.white.withOpacity(0.9),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: CosmicTheme.primaryAccentOnDark,
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  'Inizia',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Last search option
                                  if (_hasLastSearch)
                                    GestureDetector(
                                      onTap: _openLastSearch,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.history,
                                            color: CosmicTheme.primaryAccent,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              _lastSearchSummary ?? 'Guarda la tua ultima ricerca',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: CosmicTheme.primaryAccent,
                                                decoration: TextDecoration.underline,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Help button
              Positioned(
                top: 16,
                right: 24,
                child: IconButton(
                  icon: Icon(
                    Icons.help_outline,
                    color: CosmicTheme.textSecondaryOnDark,
                  ),
                  onPressed: () => _showHelpDialog(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildFloatingShapes() {
    return Stack(
      children: [
        // Top right cosmic element
        Positioned(
          top: 80,
          right: -30,
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingController.value * 10),
                child: Opacity(
                  opacity: 0.08,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: CosmicTheme.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Left side red accent
        Positioned(
          top: 200,
          left: -40,
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_floatingController.value * 8),
                child: Opacity(
                  opacity: 0.06,
                  child: Container(
                    width: 60,
                    height: 120,
                    decoration: BoxDecoration(
                      color: CosmicTheme.primaryAccentOnDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom floating shape
        Positioned(
          bottom: 120,
          right: 20,
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_floatingController.value * 5, 0),
                child: Opacity(
                  opacity: 0.05,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: CosmicTheme.primaryAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Come funziona',
          style: GoogleFonts.inter(
            color: CosmicTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Scegli se generare idee regalo per qualcuno che hai già salvato o per una nuova persona. La nostra IA creerà suggerimenti personalizzati in base alle informazioni che fornisci.',
          style: GoogleFonts.inter(
            color: CosmicTheme.textSecondary,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Capito',
              style: GoogleFonts.inter(
                color: CosmicTheme.primaryAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}