
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/recipient.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';

class EditRecipientScreen extends ConsumerStatefulWidget {
  final int recipientId;

  const EditRecipientScreen({Key? key, required this.recipientId}) : super(key: key);

  @override
  ConsumerState<EditRecipientScreen> createState() => _EditRecipientScreenState();
}

class _EditRecipientScreenState extends ConsumerState<EditRecipientScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _customRelationController = TextEditingController();
  final _customInterestController = TextEditingController();
  final _dislikesController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedGender;
  String? _selectedRelation;
  List<String> _selectedInterests = [];
  List<String> _customInterests = [];
  List<String> _dislikes = [];
  bool _showCustomRelation = false;
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _errorMessage;
  Recipient? _recipient;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _genderOptions = [
    {'value': 'M', 'label': 'Uomo', 'icon': '👨'},
    {'value': 'F', 'label': 'Donna', 'icon': '👩'},
    {'value': 'X', 'label': 'Non binario', 'icon': '🧑'},
    {'value': 'T', 'label': 'Transgender', 'icon': '🏳️‍⚧️'},
    {'value': 'O', 'label': 'Altro', 'icon': '👤'},
  ];

  final List<Map<String, String>> _relationOptions = [
    {'value': 'Amico/a', 'icon': '👥'},
    {'value': 'Partner', 'icon': '💕'},
    {'value': 'Familiare', 'icon': '👨‍👩‍👧‍👦'},
    {'value': 'Collega', 'icon': '💼'},
    {'value': 'Mentor', 'icon': '🎓'},
  ];

  final List<Map<String, String>> _interestOptions = [
    {'value': 'Musica', 'icon': '🎵'},
    {'value': 'Sport', 'icon': '⚽'},
    {'value': 'Tecnologia', 'icon': '💻'},
    {'value': 'Arte', 'icon': '🎨'},
    {'value': 'Viaggi', 'icon': '✈️'},
    {'value': 'Cucina', 'icon': '👨‍🍳'},
    {'value': 'Lettura', 'icon': '📚'},
    {'value': 'Cinema', 'icon': '🎬'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadRecipientData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _customRelationController.dispose();
    _customInterestController.dispose();
    _dislikesController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipientData() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final recipientData = await apiService.getRecipient(widget.recipientId);
      _recipient = Recipient.fromJson(recipientData);

      // Popola i campi del form con i dati esistenti
      setState(() {
        _nameController.text = _recipient!.name;
        _selectedGender = _recipient!.gender;
        _birthDateController.text = _recipient!.birthDate ?? '';
        
        // Gestisci la relazione
        if (_relationOptions.any((option) => option['value'] == _recipient!.relation)) {
          _selectedRelation = _recipient!.relation;
          _showCustomRelation = false;
        } else {
          _showCustomRelation = true;
          _customRelationController.text = _recipient!.relation;
        }

        // Separa gli interessi predefiniti da quelli personalizzati
        _selectedInterests = _recipient!.interests
            .where((interest) => _interestOptions.any((option) => option['value'] == interest))
            .toList();
        _customInterests = _recipient!.interests
            .where((interest) => !_interestOptions.any((option) => option['value'] == interest))
            .toList();

        _dislikes = _recipient!.dislikes ?? [];
        _notesController.text = _recipient!.notes ?? '';
        
        _isLoadingData = false;
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoadingData = false;
        _errorMessage = 'Errore nel caricamento dei dati del destinatario';
      });
      _showErrorSnackBar('Errore nel caricamento dei dati');
    }
  }

  Future<void> _selectDate() async {
    try {
      DateTime? initialDate;
      if (_birthDateController.text.isNotEmpty) {
        try {
          initialDate = DateTime.parse(_birthDateController.text);
        } catch (e) {
          initialDate = DateTime(1995);
        }
      } else {
        initialDate = DateTime(1995);
      }

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.primaryColor,
                onPrimary: Colors.black,
                surface: AppTheme.cardColor,
                onSurface: Colors.white,
                brightness: Brightness.dark,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && mounted) {
        setState(() {
          _birthDateController.text = picked.toIso8601String().split('T')[0];
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Errore nella selezione della data');
      }
    }
  }

  void _addCustomInterest() {
    if (_customInterestController.text.trim().isNotEmpty) {
      setState(() {
        _customInterests.add(_customInterestController.text.trim());
        _customInterestController.clear();
      });
    }
  }

  void _addDislike() {
    final dislikesText = _dislikesController.text.trim();
    if (dislikesText.isNotEmpty) {
      final newDislikes = dislikesText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      setState(() {
        _dislikes.addAll(newDislikes);
        _dislikesController.clear();
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.black),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _updateRecipient() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = 'Compila tutti i campi obbligatori');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);

      final allInterests = [..._selectedInterests, ..._customInterests];
      final relation = _showCustomRelation ? _customRelationController.text.trim() : _selectedRelation!;

      final recipientData = {
        'name': _nameController.text.trim(),
        'gender': _selectedGender,
        'birth_date': _birthDateController.text.isNotEmpty ? _birthDateController.text : null,
        'relation': relation,
        'interests': allInterests,
        'dislikes': _dislikes,
        'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      };

      await apiService.updateRecipient(widget.recipientId, recipientData);

      if (mounted) {
        _showSuccessSnackBar('Destinatario aggiornato con successo! 🎉');
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          context.pop(true); // Ritorna true per indicare che è stato modificato
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Errore nell\'aggiornamento del destinatario';
        if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'Errore di connessione. Verifica la tua connessione internet';
        } else if (e.toString().contains('401') || e.toString().contains('token')) {
          errorMessage = 'Sessione scaduta. Effettua nuovamente il login';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Dati non validi. Controlla i campi inseriti';
        }

        setState(() => _errorMessage = errorMessage);
        _showErrorSnackBar(errorMessage);
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '✏️ Modifica Destinatario',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade400),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    color: Colors.red.shade300,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      _buildAnimatedSection(
                        icon: Icons.person,
                        title: 'Informazioni Base',
                        children: [
                          _buildStyledTextField(
                            controller: _nameController,
                            hint: 'Nome del destinatario',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Il nome è obbligatorio';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildGenderSelector(),
                          const SizedBox(height: 20),
                          _buildDateField(),
                        ],
                      ),

                      const SizedBox(height: 32),

                      _buildAnimatedSection(
                        icon: Icons.favorite,
                        title: 'Relazione',
                        children: [
                          _buildRelationSelector(),
                        ],
                      ),

                      const SizedBox(height: 32),

                      _buildAnimatedSection(
                        icon: Icons.interests,
                        title: 'Interessi',
                        children: [
                          _buildInterestsSection(),
                        ],
                      ),

                      const SizedBox(height: 32),

                      _buildAnimatedSection(
                        icon: Icons.thumb_down,
                        title: 'Non gradisce',
                        children: [
                          _buildDislikesSection(),
                        ],
                      ),

                      const SizedBox(height: 32),

                      _buildAnimatedSection(
                        icon: Icons.note,
                        title: 'Note',
                        children: [
                          _buildStyledTextField(
                            controller: _notesController,
                            hint: 'Note personali sul destinatario (opzionale)',
                            icon: Icons.note_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isLoading 
                              ? [Colors.grey.shade600, Colors.grey.shade700]
                              : [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateRecipient,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Aggiornando...',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.update, color: Colors.black),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Aggiorna Destinatario',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Tutti i metodi helper rimangono uguali a quelli dell'AddRecipientScreen
  Widget _buildAnimatedSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white54),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppTheme.primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _birthDateController.text.isEmpty 
                  ? 'Data di nascita *'
                  : _birthDateController.text,
                style: GoogleFonts.inter(
                  color: _birthDateController.text.isEmpty 
                    ? Colors.white54 
                    : Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genere *',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _genderOptions.map((gender) {
            final isSelected = _selectedGender == gender['value'];
            return GestureDetector(
              onTap: () => setState(() => _selectedGender = gender['value']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                      ? AppTheme.primaryColor 
                      : Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      gender['icon']!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      gender['label']!,
                      style: GoogleFonts.inter(
                        color: isSelected ? AppTheme.primaryColor : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRelationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Che relazione hai con questa persona? *',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._relationOptions.map((relation) {
              final isSelected = _selectedRelation == relation['value'] && !_showCustomRelation;
              return GestureDetector(
                onTap: () => setState(() {
                  _showCustomRelation = false;
                  _selectedRelation = relation['value'];
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                        ? AppTheme.primaryColor 
                        : Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        relation['icon']!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        relation['value']!,
                        style: GoogleFonts.inter(
                          color: isSelected ? AppTheme.primaryColor : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: () => setState(() {
                _showCustomRelation = true;
                _selectedRelation = null;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _showCustomRelation 
                    ? AppTheme.primaryColor.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _showCustomRelation 
                      ? AppTheme.primaryColor 
                      : Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✏️', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'Altro...',
                      style: GoogleFonts.inter(
                        color: _showCustomRelation ? AppTheme.primaryColor : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_showCustomRelation) ...[
          const SizedBox(height: 16),
          _buildStyledTextField(
            controller: _customRelationController,
            hint: 'Inserisci relazione personalizzata',
            icon: Icons.edit,
            validator: (value) {
              if (_showCustomRelation && (value == null || value.trim().isEmpty)) {
                return 'Inserisci la relazione';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seleziona gli interessi',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interestOptions.map((interest) {
            final isSelected = _selectedInterests.contains(interest['value']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(interest['value']);
                  } else {
                    _selectedInterests.add(interest['value']!);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      interest['icon']!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      interest['value']!,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_customInterests.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _customInterests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('⭐'),
                    const SizedBox(width: 6),
                    Text(
                      interest,
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _customInterests.remove(interest)),
                      child: Icon(Icons.close, size: 16, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStyledTextField(
                controller: _customInterestController,
                hint: 'Aggiungi interesse personalizzato',
                icon: Icons.add_circle_outline,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _addCustomInterest,
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.add, color: Colors.black, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDislikesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStyledTextField(
                controller: _dislikesController,
                hint: 'Aggiungi cosa non gradisce (separato da virgole)',
                icon: Icons.thumb_down_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade500],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _addDislike,
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('❌', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      dislike,
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _dislikes.remove(dislike)),
                      child: const Icon(Icons.close, size: 16, color: Colors.red),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
