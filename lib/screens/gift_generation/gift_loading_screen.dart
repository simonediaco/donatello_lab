
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late AnimationController _mainController;
  late AnimationController _particlesController;
  late AnimationController _textController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _particlesAnimation;
  late Animation<double> _textFadeAnimation;

  List<String> _loadingMessages = [
    'Analizzo i tuoi gusti...',
    'Cerco tra migliaia di prodotti...',
    'Seleziono le opzioni migliori...',
    'Quasi pronto con le tue idee regalo...',
  ];

  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _particlesController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.linear,
    ));

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
    _mainController.dispose();
    _particlesController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated particles background
            ...List.generate(20, (index) => _buildParticle(index)),

            // Main content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Main loading animation with modern design
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotationAnimation.value * 2 * 3.14159,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryColor.withOpacity(0.8),
                                  AppTheme.primaryColor.withOpacity(0.4),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 0.8, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.backgroundColor,
                                border: Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                size: 60,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 80),

                  // Modern title with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Donatello AI',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'sta lavorando per te',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.white70,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 60),

                  // Dynamic loading messages with modern design
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AnimatedBuilder(
                      animation: _textFadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textFadeAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _loadingMessages[_currentMessageIndex],
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Modern progress indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: _currentMessageIndex >= index ? 30 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: _currentMessageIndex >= index 
                              ? LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.primaryColor.withOpacity(0.7),
                                  ],
                                )
                              : null,
                          color: _currentMessageIndex >= index 
                              ? null 
                              : Colors.white.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),

                  const Spacer(),

                  // Bottom inspirational text with modern styling
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.palette,
                          color: AppTheme.primaryColor.withOpacity(0.7),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'L\'arte del regalo perfetto\nrichiede creatività e intelligenza',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white60,
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
  }

  Widget _buildParticle(int index) {
    final delay = index * 0.2;

    return AnimatedBuilder(
      animation: _particlesAnimation,
      builder: (context, child) {
        final progress = (_particlesAnimation.value + delay) % 1.0;
        final size = MediaQuery.of(context).size;

        final x = (index % 4) * (size.width / 4) + 
                  50 * sin(progress * 2 * 3.14159 + index);
        final y = progress * size.height;

        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: (1 - progress) * 0.6,
            child: Container(
              width: 4 + (index % 3) * 2,
              height: 4 + (index % 3) * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.6),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

double sin(double value) {
  return (value * 180 / 3.14159).remainder(360) * 3.14159 / 180;
}
