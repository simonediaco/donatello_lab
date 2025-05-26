import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthdateController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devi accettare i termini e condizioni')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le password non corrispondono')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final names = _nameController.text.split(' ');
      final authService = ref.read(authServiceProvider);
      final user = await authService.register({
        'email': _emailController.text,
        'password': _passwordController.text,
        'password_confirm': _confirmPasswordController.text,
        'first_name': names.first,
        'last_name': names.length > 1 ? names.sublist(1).join(' ') : '',
        'birth_date': _birthdateController.text,
      });

      if (user != null && mounted) {
        ref.read(currentUserProvider.notifier).state = user;
        context.go('/onboarding');
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Register'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              CustomTextField(
                hint: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                hint: 'Password',
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                hint: 'Re-enter Password',
                controller: _confirmPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                hint: 'Name',
                controller: _nameController,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                hint: 'Birthdate',
                controller: _birthdateController,
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() => _agreedToTerms = value ?? false);
                    },
                    fillColor: MaterialStateProperty.all(AppTheme.primaryColor),
                  ),
                  const Expanded(
                    child: Text('I agree to the terms and conditions'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              CustomButton(
                text: 'Register',
                onPressed: _register,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}