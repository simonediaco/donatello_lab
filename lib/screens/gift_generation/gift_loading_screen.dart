import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../theme/cosmic_theme.dart';

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
  late AnimationController _starsController;
  late AnimationController _galaxyController;

  late Animation<double> _particlesAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _backgroundOpacity;
  late Animation<double> _iconPulse;
  late Animation<double> _starsRotation;
  late Animation<double> _galaxyRotation;

  List<String> _loadingMessages = [
    '"Analizzando le stelle del cuore..."',
    '"Creando la magia perfetta..."',
    '"Quasi pronto, il tuo regalo sta nascendo..."',
  ];

  int _currentMessageIndex = 0;
  List<Offset> _starPositions = [];
  List<double> _starSizes = [];
  List<Color> _starColors = [];

  @override
  void initState() {
    super.initState();

    _generateStars();

    _particlesController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _iconController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _starsController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _galaxyController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

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
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeInOut,
    ));

    _starsRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _starsController,
      curve: Curves.linear,
    ));

    _galaxyRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _galaxyController,
      curve: Curves.linear,
    ));

    _startAnimations();
  }

  void _generateStars() {
    final random = math.Random();
    _starPositions.clear();
    _starSizes.clear();
    _starColors.clear();

    for (int i = 0; i < 30; i++) {
      _starPositions.add(Offset(
        random.nextDouble(),
        random.nextDouble(),
      ));
      _starSizes.add(random.nextDouble() * 3 + 1);
      _starColors.add([
        Colors.white,
        CosmicTheme.primaryAccent,
        const Color(0xFFFFD700),
        const Color(0xFF87CEEB),
        const Color(0xFFDDA0DD),
      ][random.nextInt(5)]);
    }
  }

  void _startAnimations() async {
    _backgroundController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _startTextRotation();
  }

  void _startTextRotation() {
    _textController.forward().then((_) {
      Future.delayed(const Duration(seconds: 3), () {
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
    _starsController.dispose();
    _galaxyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: CosmicTheme.cosmicGradient,
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Elegant twinkling stars background
                  _buildElegantStarField(),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // Central cosmic portal with pulsating icon
                        Container(
                          width: 120,
                          height: 120,
                          child: AnimatedBuilder(
                            animation: _iconController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _iconPulse.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        CosmicTheme.primaryAccent.withOpacity(0.3),
                                        CosmicTheme.primaryAccent.withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.3, 0.7, 1.0],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CosmicTheme.primaryAccent.withOpacity(0.4 * _iconPulse.value),
                                        blurRadius: 30 * _iconPulse.value,
                                        spreadRadius: 5 * (_iconPulse.value - 0.8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.auto_awesome,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 60),

                        // Cosmic title
                        Text(
                          'Donatello Lab',
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: CosmicTheme.textPrimaryOnDark,
                            letterSpacing: -1,
                            shadows: [
                              Shadow(
                                color: CosmicTheme.primaryAccent.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Laboratorio Cosmico dei Regali',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: CosmicTheme.textSecondaryOnDark,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 60),

                        // Dynamic loading message
                        AnimatedBuilder(
                          animation: _textFadeAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _textFadeAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.1),
                                      Colors.white.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: CosmicTheme.primaryAccent.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _loadingMessages[_currentMessageIndex],
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: CosmicTheme.textPrimaryOnDark,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 40),

                        // Elegant progress indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 600 + (index * 100)),
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: _currentMessageIndex >= index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: _currentMessageIndex >= index 
                                    ? LinearGradient(
                                        colors: [
                                          CosmicTheme.primaryAccent,
                                          const Color(0xFFFFD700),
                                        ],
                                      )
                                    : null,
                                color: _currentMessageIndex >= index 
                                    ? null 
                                    : Colors.white.withOpacity(0.3),
                                boxShadow: _currentMessageIndex >= index ? [
                                  BoxShadow(
                                    color: CosmicTheme.primaryAccent.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ] : null,
                              ),
                            );
                          }),
                        ),

                        const Spacer(),
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

  Widget _buildElegantStarField() {
    return AnimatedBuilder(
      animation: Listenable.merge([_starsController, _backgroundController]),
      builder: (context, child) {
        return Opacity(
          opacity: _backgroundOpacity.value,
          child: CustomPaint(
            size: Size.infinite,
            painter: ElegantStarFieldPainter(
              stars: _starPositions,
              sizes: _starSizes,
              colors: _starColors,
              animation: _starsRotation.value,
            ),
          ),
        );
      },
    );
  }
}

class ElegantStarFieldPainter extends CustomPainter {
  final List<Offset> stars;
  final List<double> sizes;
  final List<Color> colors;
  final double animation;

  ElegantStarFieldPainter({
    required this.stars,
    required this.sizes,
    required this.colors,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < stars.length; i++) {
      final star = stars[i];
      final starSize = sizes[i];
      final color = colors[i];

      final x = star.dx * size.width;
      final y = star.dy * size.height;

      // Slow, elegant twinkling
      final twinklePhase = (animation * 0.3 + i * 0.2) % (2 * math.pi);
      final opacity = 0.2 + 0.6 * (math.sin(twinklePhase) * 0.5 + 0.5);
      final scale = 0.7 + 0.3 * (math.sin(twinklePhase + math.pi / 4) * 0.5 + 0.5);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      // Draw elegant twinkling star
      canvas.drawCircle(
        Offset(x, y),
        starSize * scale,
        paint,
      );

      // Draw subtle glow for brighter stars
      if (opacity > 0.6) {
        final glowPaint = Paint()
          ..color = color.withOpacity(opacity * 0.3)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(x, y),
          starSize * scale * 2,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}