
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _typewriterController;
  late AnimationController _loadingController;
  late Animation<int> _typewriterAnimation;
  
  final String _fullText = "Donatello";

  @override
  void initState() {
    super.initState();
    
    // Animazione typewriter per il testo
    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Animazione per il loading
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _typewriterAnimation = IntTween(
      begin: 0,
      end: _fullText.length,
    ).animate(CurvedAnimation(
      parent: _typewriterController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    // Avvia animazione typewriter del testo
    await _typewriterController.forward();
    
    // Dopo un piccolo delay, avvia il loading
    await Future.delayed(const Duration(milliseconds: 500));
    _loadingController.forward();

    // Aspetta un momento per permettere all'utente di vedere la splash
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Controlla lo stato di autenticazione
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
    _typewriterController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Testo animato "Donatello" con effetto typewriter
            AnimatedBuilder(
              animation: _typewriterAnimation,
              builder: (context, child) {
                String displayText = _fullText.substring(0, _typewriterAnimation.value);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayText,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 48,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                    ),
                    // Cursore lampeggiante
                    if (_typewriterAnimation.value < _fullText.length)
                      AnimatedBuilder(
                        animation: _typewriterController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: (_typewriterController.value * 3) % 1 > 0.5 ? 1.0 : 0.0,
                            child: Text(
                              '|',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 48,
                                color: Colors.white60,
                                letterSpacing: 2.0,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 60),
            
            // Loading indicator animato
            AnimatedBuilder(
              animation: _loadingController,
              builder: (context, child) {
                return Opacity(
                  opacity: _loadingController.value,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                    strokeWidth: 3.0,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Testo di loading (opzionale)
            AnimatedBuilder(
              animation: _loadingController,
              builder: (context, child) {
                return Opacity(
                  opacity: _loadingController.value * 0.7,
                  child: Text(
                    'Preparando la tua esperienza...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
