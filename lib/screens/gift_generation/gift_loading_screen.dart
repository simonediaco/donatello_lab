
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../../theme/app_theme.dart';

class GiftLoadingScreen extends StatefulWidget {
  final String message;

  const GiftLoadingScreen({
    Key? key,
    this.message = 'Sto creando le idee regalo perfette...',
  }) : super(key: key);

  @override
  State<GiftLoadingScreen> createState() => _GiftLoadingScreenState();
}

class _GiftLoadingScreenState extends State<GiftLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _particlesController;
  late AnimationController _textController;
  late AnimationController _backgroundController;
  late AnimationController _iconController;

  late Animation<double> _particlesAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _backgroundOpacity;
  late Animation<double> _iconPulse;

  List<String> _loadingMessages = [
    'Analizzo i gusti e le preferenze...',
    'Esploro migliaia di prodotti unici...',
    'Confronto prezzi e caratteristiche...',
    'Seleziono le migliori opzioni...',
    'Creo suggerimenti personalizzati...',
    'Quasi pronto con le idee perfette!',
  ];

  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();

    _particlesController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _iconController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _particlesAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _particlesController,
      curve: Curves.linear,
    ));

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _backgroundOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));

    _iconPulse = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    _backgroundController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _startTextRotation();
  }

  void _startTextRotation() {
    _textController.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _textController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _currentMessageIndex = 
                    (_currentMessageIndex + 1) % _loadingMessages.length;
              });
              _startTextRotation();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _particlesController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    _iconController.dispose();
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
                  AppTheme.backgroundColor.withOpacity(_backgroundOpacity.value),
                  AppTheme.cardColor.withOpacity(_backgroundOpacity.value),
                  AppTheme.primaryColor.withOpacity(0.1 * _backgroundOpacity.value),
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Floating geometric shapes in background (like splash screen)
                  _buildFloatingShapes(),
                  
                  // Particles animation (cascata di stelle/cerchi)
                  ...List.generate(25, (index) => _buildParticle(index)),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // Central pulsating star animation - smooth and fluid
                        Container(
                          width: 80,
                          height: 80,
                          child: AnimatedBuilder(
                            animation: _iconController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _iconPulse.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(40),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.3 * _iconPulse.value),
                                        blurRadius: 20 * _iconPulse.value,
                                        spreadRadius: 5 * (_iconPulse.value - 0.8),
                                      ),
                                    ],
                                  ),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 60),

                        // App title with consistent fonts
                        Text(
                          'Donatello',
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor,
                            letterSpacing: -1,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'sta lavorando per te',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 60),

                        // Dynamic loading messages
                        Container(
                          height: 100,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: AnimatedBuilder(
                            animation: _textFadeAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _textFadeAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.psychology_outlined,
                                          color: AppTheme.primaryColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          _loadingMessages[_currentMessageIndex],
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            color: AppTheme.textPrimaryColor,
                                            fontWeight: FontWeight.w500,
                                            height: 1.3,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Progress indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 400 + (index * 50)),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentMessageIndex >= index ? 32 : 12,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: _currentMessageIndex >= index 
                                    ? AppTheme.primaryGradient
                                    : null,
                                color: _currentMessageIndex >= index 
                                    ? null 
                                    : AppTheme.textTertiaryColor.withOpacity(0.3),
                                boxShadow: _currentMessageIndex >= index ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ] : null,
                              ),
                            );
                          }),
                        ),

                        const Spacer(),

                        // Bottom text
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.palette_outlined,
                                color: AppTheme.primaryColor.withOpacity(0.7),
                                size: 24,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'L\'arte del regalo perfetto\nrichiede creatività e intelligenza',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
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

  Widget _buildParticle(int index) {
    final delay = index * 0.15;

    return AnimatedBuilder(
      animation: _particlesAnimation,
      builder: (context, child) {
        final progress = (_particlesAnimation.value + delay) % 1.0;
        final size = MediaQuery.of(context).size;

        final x = (index % 5) * (size.width / 5) + 
                  30 * sin(progress * 2 * 3.14159 + index);
        final y = progress * (size.height + 100) - 50;

        return Positioned(
          left: x.clamp(0, size.width - 20),
          top: y,
          child: Opacity(
            opacity: (1 - progress) * 0.6,
            child: Transform.rotate(
              angle: progress * 2 * 3.14159,
              child: Container(
                width: 8 + (index % 3) * 4,
                height: 8 + (index % 3) * 4,
                child: ShaderMask(
                  shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
                  child: Icon(
                    Icons.star,
                    size: 8 + (index % 3) * 4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
                    color: AppTheme.primaryColor,
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
                    color: AppTheme.primaryLight,
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
                    color: AppTheme.primaryDark,
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

double sin(double value) {
  return (value * 180 / 3.14159).remainder(360) * 3.14159 / 180;
}
