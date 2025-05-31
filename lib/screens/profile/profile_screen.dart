
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../models/user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);
      
      final apiService = ref.read(apiServiceProvider);
      final profileData = await apiService.getProfile();
      
      _user = User.fromJson(profileData);
      
      // Popoliamo i controller con i dati esistenti
      _firstNameController.text = _user!.firstName;
      _lastNameController.text = _user!.lastName;
      _emailController.text = _user!.email;
      _phoneController.text = _user!.profile?.phoneNumber ?? '';
      _bioController.text = _user!.profile?.bio ?? '';
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel caricamento del profilo: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      final apiService = ref.read(apiServiceProvider);
      
      final updateData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'profile': {
          'phone_number': _phoneController.text.trim(),
          'bio': _bioController.text.trim(),
        }
      };

      final updatedData = await apiService.updateProfile(updateData);
      
      // Aggiorniamo l'utente nel provider
      final updatedUser = User.fromJson(updatedData);
      ref.read(currentUserProvider.notifier).state = updatedUser;
      
      setState(() {
        _user = updatedUser;
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profilo aggiornato con successo!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nell\'aggiornamento: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    // Ripristiniamo i valori originali
    if (_user != null) {
      _firstNameController.text = _user!.firstName;
      _lastNameController.text = _user!.lastName;
      _phoneController.text = _user!.profile?.phoneNumber ?? '';
      _bioController.text = _user!.profile?.bio ?? '';
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _buildProfileContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppTheme.textPrimaryColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Il mio Profilo',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          if (!_isEditing) ...[
            GestureDetector(
              onTap: () => setState(() => _isEditing = true),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.softShadow,
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProfileAvatar(),
            const SizedBox(height: 32),
            _buildPersonalInfoSection(),
            const SizedBox(height: 24),
            _buildContactInfoSection(),
            const SizedBox(height: 24),
            _buildBioSection(),
            const SizedBox(height: 32),
            if (_isEditing) _buildActionButtons(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Center(
        child: _user?.firstName.isNotEmpty == true
          ? Text(
              '${_user!.firstName[0]}${_user!.lastName.isNotEmpty ? _user!.lastName[0] : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w700,
              ),
            )
          : const Icon(
              Icons.person,
              color: Colors.white,
              size: 48,
            ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informazioni Personali',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Nome',
            hint: 'Inserisci il tuo nome',
            controller: _firstNameController,
            enabled: _isEditing,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Il nome è obbligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Cognome',
            hint: 'Inserisci il tuo cognome',
            controller: _lastNameController,
            enabled: _isEditing,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Il cognome è obbligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Email',
            hint: 'La tua email',
            controller: _emailController,
            enabled: false, // L'email non può essere modificata
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contatti',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Telefono',
            hint: 'Inserisci il tuo numero di telefono',
            controller: _phoneController,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bio',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Biografia',
            hint: 'Racconta qualcosa di te...',
            controller: _bioController,
            enabled: _isEditing,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Annulla',
            onPressed: _cancelEdit,
            // variant: ButtonVariant.outline,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            text: 'Salva',
            onPressed: _saveProfile,
            isLoading: _isSaving,
          ),
        ),
      ],
    );
  }
}
