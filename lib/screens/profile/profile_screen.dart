import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../theme/cosmic_theme.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _loadProfile();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _animationController.dispose();
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
        _showError('Errore nel caricamento del profilo: ${e.toString()}');
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
        _showSuccess('Profilo aggiornato con successo!');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        _showError('Errore nell\'aggiornamento: ${e.toString()}');
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

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: CosmicTheme.backgroundLightGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  _buildCosmicHeader(),
                  Expanded(
                    child: _isLoading 
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(CosmicTheme.primaryAccent),
                          ),
                        )
                      : _buildProfileContent(),
                  ),
                ],
              ),


            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildCosmicHeader() {
    return Container(
      height: _isEditing ? 100 : 160,
      decoration: const BoxDecoration(
        gradient: CosmicTheme.cosmicGradient,
      ),
      child: Stack(
        children: [
          // Floating cosmic shapes
          _buildFloatingShapes(),

          // Header content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and edit button row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Il mio Profilo',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: CosmicTheme.textPrimaryOnDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (!_isEditing) ...[
                          // Edit button with pencil icon (no box)
                          GestureDetector(
                            onTap: () => setState(() => _isEditing = true),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (!_isEditing) ...[
                      const SizedBox(height: 12),
                      // Share profile button below title
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Funzionalità in arrivo!')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Condividi profilo',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingShapes() {
    return Stack(
      children: [
        // Top right shape
        Positioned(
          top: 20,
          right: -10,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value * 0.1,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccentOnDark,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom left shape
        Positioned(
          bottom: 10,
          left: -20,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value * 0.08,
                child: Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccent.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }



  Widget _buildProfileContent() {
    if (_isEditing) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 20),
                    _buildContactInfoSection(),
                    const SizedBox(height: 20),
                    _buildBioSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildPersonalInfoSection(),
                const SizedBox(height: 20),
                _buildContactInfoSection(),
                const SizedBox(height: 20),
                _buildBioSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _isEditing ? null : BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: CosmicTheme.softShadow,
        border: Border.all(
          color: CosmicTheme.primaryAccent.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  gradient: CosmicTheme.buttonGradient,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Informazioni Personali',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CosmicTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(20),
      decoration: _isEditing ? null : BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: CosmicTheme.softShadow,
        border: Border.all(
          color: CosmicTheme.primaryAccent.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  gradient: CosmicTheme.buttonGradient,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Contatti',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CosmicTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Telefono',
            hint: 'Inserisci il tuo numero di telefono',
            controller: _phoneController,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: CosmicTheme.primaryAccent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _isEditing ? null : BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: CosmicTheme.softShadow,
        border: Border.all(
          color: CosmicTheme.primaryAccent.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  gradient: CosmicTheme.buttonGradient,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Bio',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CosmicTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Biografia',
            hint: 'Racconta qualcosa di te...',
            controller: _bioController,
            enabled: _isEditing,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _cancelEdit,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: CosmicTheme.primaryAccent,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Annulla',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CosmicTheme.primaryAccent,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                gradient: CosmicTheme.buttonGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: CosmicTheme.lightShadow,
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Salva',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}