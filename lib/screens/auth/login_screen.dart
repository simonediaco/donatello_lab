import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.login(
        _emailController.text,
        _passwordController.text,
      );
      
      if (user != null && mounted) {
        ref.read(currentUserProvider.notifier).state = user;
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Immagine
              Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/renaissance_portrait.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
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
                isPassword: true,
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
    );
  }
}