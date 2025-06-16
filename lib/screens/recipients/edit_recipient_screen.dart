import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/recipient.dart';
import '../../services/api_service.dart';
import '../../theme/cosmic_theme.dart';
import '../../widgets/custom_text_field.dart';

class EditRecipientScreen extends ConsumerStatefulWidget {
  final int recipientId;

  const EditRecipientScreen({Key? key, required this.recipientId}) : super(key: key);

  @override
  ConsumerState<EditRecipientScreen> createState() => _EditRecipientScreenState();
}

class _EditRecipientScreenState extends ConsumerState<EditRecipientScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _relationController = TextEditingController();
  final _notesController = TextEditingController();
  final _interestController = TextEditingController();
  final _dislikeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _selectedGender;
  List<String> _interests = [];
  List<String> _dislikes = [];
  Recipient? _recipient;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final List<Map<String, String>> _genderOptions = [
    {'value': 'M', 'label': 'Uomo', 'icon': '👨'},
    {'value': 'F', 'label': 'Donna', 'icon': '👩'},
    {'value': 'X', 'label': 'Non-binario', 'icon': '🧑'},
    {'value': 'T', 'label': 'Transgender', 'icon': '🏳️‍⚧️'},
    {'value': 'O', 'label': 'Altro', 'icon': '👤'},
  ];

  @override
  void initState() {
    super.initState();
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
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _loadRecipient();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _relationController.dispose();
    _notesController.dispose();
    _interestController.dispose();
    _dislikeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipient() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final data = await apiService.getRecipient(widget.recipientId);
      setState(() {
        _recipient = Recipient.fromJson(data);
        _nameController.text = _recipient?.name ?? '';
        _selectedGender = _recipient?.gender;
        _birthDateController.text = _recipient?.birthDate ?? '';
        _relationController.text = _recipient?.relation ?? '';
        _notesController.text = _recipient?.notes ?? '';
        _interests = List<String>.from(_recipient?.interests ?? []);
        _dislikes = List<String>.from(_recipient?.dislikes ?? []);
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore nel caricamento del destinatario';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDateController.text.isNotEmpty 
        ? DateTime.tryParse(_birthDateController.text) ?? DateTime(1995)
        : DateTime(1995),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: CosmicTheme.primaryAccent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _birthDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  void _addInterest() {
    final text = _interestController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _interests.add(text);
        _interestController.clear();
      });
    }
  }

  void _addDislike() {
    final text = _dislikeController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _dislikes.add(text);
        _dislikeController.clear();
      });
    }
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
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: CosmicTheme.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _saveRecipient() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Il nome è obbligatorio');
      return;
    }

    if (_selectedGender == null) {
      _showError('Seleziona il genere');
      return;
    }

    if (_relationController.text.trim().isEmpty) {
      _showError('La relazione è obbligatoria');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final updatedData = {
        'name': _nameController.text.trim(),
        'gender': _selectedGender,
        'birth_date': _birthDateController.text.isNotEmpty ? _birthDateController.text : null,
        'relation': _relationController.text.trim(),
        'interests': _interests,
        'favorite_colors': _recipient?.favoriteColors ?? [],
        'dislikes': _dislikes,
        'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      };
      await apiService.updateRecipient(widget.recipientId, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Destinatario aggiornato con successo!',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: CosmicTheme.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Errore nel salvare le modifiche');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: CosmicTheme.cosmicGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? _buildLoadingState()
                      : _recipient == null
                          ? _buildErrorState()
                          : _buildEditForm(),
                ),
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
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modifica Destinatario',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _recipient?.name ?? 'Caricamento...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: CosmicTheme.primaryAccent),
          SizedBox(height: 16),
          Text('Caricamento destinatario...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: CosmicTheme.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: CosmicTheme.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Errore di caricamento',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: CosmicTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Non è stato possibile caricare i dati del destinatario.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: CosmicTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: CosmicTheme.buttonGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CosmicTheme.primaryAccent.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _nameController.text.isNotEmpty 
                            ? _nameController.text[0].toUpperCase()
                            : '?',
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Basic Information Section
                _buildSection(
                  'Informazioni Base',
                  Icons.person_outline,
                  [
                    CustomTextField(
                      hint: 'Inserisci il nome',
                      controller: _nameController,
                      label: 'Nome *',
                      onChanged: (value) => setState(() {}), // Update avatar
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Genere *',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CosmicTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _genderOptions.map((option) {
                        final isSelected = _selectedGender == option['value'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedGender = option['value']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: isSelected ? CosmicTheme.buttonGradient : null,
                              color: isSelected ? null : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Colors.grey.shade200,
                                width: 1,
                              ),
                              boxShadow: isSelected ? CosmicTheme.lightShadow : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(option['icon']!, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(
                                  option['label']!,
                                  style: GoogleFonts.inter(
                                    color: isSelected ? Colors.white : CosmicTheme.textPrimary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data di nascita',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CosmicTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: CosmicTheme.textSecondary,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _birthDateController.text.isNotEmpty 
                                    ? _birthDateController.text 
                                    : 'Seleziona data',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: _birthDateController.text.isNotEmpty 
                                      ? CosmicTheme.textPrimary 
                                      : CosmicTheme.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Relationship Section
                _buildSection(
                  'Relazione',
                  Icons.people_outline,
                  [
                    CustomTextField(
                      hint: 'es: amico, partner, famiglia...',
                      controller: _relationController,
                      label: 'Che relazione hai con questa persona? *',
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Interests Section
                _buildSection(
                  'Interessi',
                  Icons.favorite_outline,
                  [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            hint: 'es: Musica, Sport, Tech...',
                            controller: _interestController,
                            label: 'Aggiungi interesse',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: CosmicTheme.buttonGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: CosmicTheme.lightShadow,
                          ),
                          child: IconButton(
                            onPressed: _addInterest,
                            icon: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    if (_interests.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _interests.map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: CosmicTheme.primaryAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: CosmicTheme.primaryAccent.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  interest,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: CosmicTheme.primaryAccent,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => setState(() => _interests.remove(interest)),
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: CosmicTheme.primaryAccent,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 32),

                // Dislikes Section
                _buildSection(
                  'Cose che Non Gradisce',
                  Icons.thumb_down_outlined,
                  [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            hint: 'es: Horror, Pesce, Sport estremi...',
                            controller: _dislikeController,
                            label: 'Aggiungi cosa che non gradisce',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: CosmicTheme.buttonGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: CosmicTheme.lightShadow,
                          ),
                          child: IconButton(
                            onPressed: _addDislike,
                            icon: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    if (_dislikes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _dislikes.map((dislike) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: CosmicTheme.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: CosmicTheme.red.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  dislike,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: CosmicTheme.red,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => setState(() => _dislikes.remove(dislike)),
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: CosmicTheme.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 32),

                // Notes Section
                _buildSection(
                  'Note Aggiuntive',
                  Icons.note_alt_outlined,
                  [
                    CustomTextField(
                      hint: 'Aggiungi qualsiasi informazione utile...',
                      controller: _notesController,
                      label: 'Note personali',
                      maxLines: 4,
                    ),
                  ],
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CosmicTheme.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CosmicTheme.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: CosmicTheme.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: CosmicTheme.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Save button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: CosmicTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: CosmicTheme.lightShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveRecipient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Salva Modifiche',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CosmicTheme.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: CosmicTheme.primaryAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CosmicTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
