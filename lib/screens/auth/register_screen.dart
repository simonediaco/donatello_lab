
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../theme/app_theme.dart';
import '../../models/auth_exception.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Validazione campi obbligatori
    if (_firstNameController.text.trim().isEmpty) {
      _showError('Inserisci il nome');
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      _showError('Inserisci il cognome');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showError('Inserisci un indirizzo email');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showError('Inserisci un indirizzo email valido');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError('Inserisci la password');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('La password deve essere di almeno 6 caratteri');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Le password non corrispondono');
      return;
    }

    if (_birthdateController.text.trim().isEmpty) {
      _showError('Inserisci la data di nascita');
      return;
    }

    if (!_isValidDate(_birthdateController.text.trim())) {
      _showError('Inserisci una data valida (gg/mm/aaaa)');
      return;
    }

    if (!_agreedToTerms) {
      _showError('Devi accettare i termini e le condizioni');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.register({
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'password_confirm': _confirmPasswordController.text,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'birth_date': _formatDateForApi(_birthdateController.text.trim()),
      });

      if (user != null && mounted) {
        ref.read(currentUserProvider.notifier).state = user;
        context.go('/onboarding');
      } else {
        _showError('Registrazione fallita. Riprova.');
      }
    } catch (e) {
      if (mounted) {
        _handleRegisterError(e);
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

  bool _isValidDate(String date) {
    try {
      final parts = date.split('/');
      if (parts.length != 3) return false;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      if (day < 1 || day > 31) return false;
      if (month < 1 || month > 12) return false;
      if (year < 1900 || year > DateTime.now().year) return false;
      
      // Controllo età minima (13 anni)
      final birthDate = DateTime(year, month, day);
      final today = DateTime.now();
      final age = today.year - birthDate.year;
      if (age < 13) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  String _formatDateForApi(String date) {
    // Converte da gg/mm/aaaa a aaaa-mm-gg
    final parts = date.split('/');
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
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

  void _handleRegisterError(dynamic error) {
    String message;

    if (error is AuthException) {
      message = error.message;
    } else {
      message = 'Errore durante la registrazione. Riprova.';

      if (error.toString().contains('DioException')) {
        if (error.toString().contains('status code of 400')) {
          message = 'Dati non validi. Controlla i campi inseriti';
        } else if (error.toString().contains('status code of 409')) {
          message = 'Email già registrata. Prova con un\'altra email';
        } else if (error.toString().contains('status code of 500')) {
          message = 'Errore del server. Riprova più tardi';
        } else if (error.toString().contains('timeout') || error.toString().contains('connection')) {
          message = 'Problema di connessione. Controlla la tua rete';
        }
      }
    }

    _showError(message);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthdateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
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
        title: const Text('Registrazione'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crea il tuo account',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Unisciti alla famiglia di Donatello Lab',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Nome
                CustomTextField(
                  hint: 'Nome',
                  controller: _firstNameController,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 16),

                // Cognome
                CustomTextField(
                  hint: 'Cognome',
                  controller: _lastNameController,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  hint: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Data di nascita
                CustomTextField(
                  hint: 'Data di nascita (gg/mm/aaaa)',
                  controller: _birthdateController,
                  keyboardType: TextInputType.datetime,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.calendar_today,
                      color: const Color(0xFFB8860B),
                    ),
                    onPressed: _selectDate,
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  hint: 'Password (min. 6 caratteri)',
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
                const SizedBox(height: 16),

                // Conferma Password
                CustomTextField(
                  hint: 'Conferma password',
                  controller: _confirmPasswordController,
                  isPassword: !_isConfirmPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFFB8860B),
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Termini e condizioni
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) {
                          setState(() => _agreedToTerms = value ?? false);
                        },
                        fillColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return AppTheme.primaryColor;
                          }
                          return Colors.grey[400];
                        }),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Accetto i termini e le condizioni',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                // TODO: Navigare alla pagina dei termini
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('I termini d\'uso saranno disponibili presto'),
                                  ),
                                );
                              },
                              child: Text(
                                'Leggi i termini d\'uso e la privacy policy',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Confermo di avere almeno 13 anni e accetto che i miei dati vengano trattati secondo la privacy policy per ricevere idee regalo personalizzate.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Pulsante registrazione
                CustomButton(
                  text: 'Crea Account',
                  onPressed: _register,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),

                // Link al login
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hai già un account? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Accedi',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
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
    );
  }
}
