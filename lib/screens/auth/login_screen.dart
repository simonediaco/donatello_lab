import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../theme/app_theme.dart';
import '../../models/auth_exception.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Validazione input
    if (_emailController.text.trim().isEmpty) {
      _showError('Inserisci un indirizzo email');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError('Inserisci la password');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showError('Inserisci un indirizzo email valido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null && mounted) {
        ref.read(currentUserProvider.notifier).state = user;
        context.go('/home');
      } else {
        _showError('Login fallito. Riprova.');
      }
    } catch (e) {
      if (mounted) {
        _handleLoginError(e);
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

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleLoginError(dynamic error) {
    String message;

    // Gestione delle nostre eccezioni personalizzate
    if (error is AuthException) {
      message = error.message;
    } else {
      // Fallback per errori non gestiti
      message = 'Errore di connessione. Riprova.';

      // Gestione DioException con status code
      if (error.toString().contains('DioException')) {
        if (error.toString().contains('status code of 400') || 
            error.toString().contains('status code of 401') ||
            error.toString().contains('401') || 
            error.toString().contains('Unauthorized')) {
          message = 'Email o password non corretti';
        } else if (error.toString().contains('status code of 404') || error.toString().contains('404')) {
          message = 'Servizio non disponibile';
        } else if (error.toString().contains('status code of 500') || error.toString().contains('500')) {
          message = 'Errore del server. Riprova più tardi';
        } else if (error.toString().contains('timeout') || error.toString().contains('connection')) {
          message = 'Problema di connessione. Controlla la tua rete';
        }
      }
    }

    _showError(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Immagine cover a schermo intero
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/auth/login_cover.png'), 
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Contenuto inferiore con form
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome to Donatello Lab',
                      style: Theme.of(context).textTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    CustomTextField(
                      hint: 'Enter your email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      hint: 'Enter your password',
                      controller: _passwordController,
                      isPassword: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFFB8860B),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    CustomButton(
                      text: 'Login',
                      onPressed: _login,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),

                    CustomButton(
                      text: 'Register',
                      onPressed: () => context.push('/register'),
                      isOutlined: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}