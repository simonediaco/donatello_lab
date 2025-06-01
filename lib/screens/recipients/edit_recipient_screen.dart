
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/recipient.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

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
  final _interestsController = TextEditingController();
  final _notesController = TextEditingController();
  final _dislikesController = TextEditingController();
  final _interestController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _selectedGender;
  List<String> _selectedFavoriteColors = [];
  List<String> _interests = [];
  List<String> _dislikes = [];
  Recipient? _recipient;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _genderOptions = [
    {'value': 'M', 'label': 'Uomo', 'icon': '👨'},
    {'value': 'F', 'label': 'Donna', 'icon': '👩'},
    {'value': 'X', 'label': 'Non-binario', 'icon': '🧑'},
    {'value': 'T', 'label': 'Transgender', 'icon': '🏳️‍⚧️'},
    {'value': 'O', 'label': 'Altro', 'icon': '👤'},
  ];

  final List<Map<String, dynamic>> _colorOptions = [
    {'value': 'Rosso', 'color': Colors.red, 'icon': '🔴'},
    {'value': 'Blu', 'color': Colors.blue, 'icon': '🔵'},
    {'value': 'Verde', 'color': Colors.green, 'icon': '🟢'},
    {'value': 'Giallo', 'color': Colors.yellow, 'icon': '🟡'},
    {'value': 'Viola', 'color': Colors.purple, 'icon': '🟣'},
    {'value': 'Arancione', 'color': Colors.orange, 'icon': '🟠'},
    {'value': 'Rosa', 'color': Colors.pink, 'icon': '🩷'},
    {'value': 'Nero', 'color': Colors.black, 'icon': '⚫'},
    {'value': 'Bianco', 'color': Colors.grey[300], 'icon': '⚪'},
    {'value': 'Marrone', 'color': Colors.brown, 'icon': '🟤'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadRecipient();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _relationController.dispose();
    _interestsController.dispose();
    _notesController.dispose();
    _dislikesController.dispose();
    _interestController.dispose();
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
        _interestsController.text = _recipient?.interests?.join(', ') ?? '';
        _notesController.text = _recipient?.notes ?? '';
        _selectedFavoriteColors = List<String>.from(_recipient?.favoriteColors ?? []);
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
    final text = _dislikesController.text.trim();
    if (text.isNotEmpty) {
      final newDislikes = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      setState(() {
        _dislikes.addAll(newDislikes);
        _dislikesController.clear();
      });
    }
  }

  Future<void> _saveRecipient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final updatedData = {
        'name': _nameController.text.trim(),
        'gender': _selectedGender,
        'birth_date': _birthDateController.text.isNotEmpty ? _birthDateController.text : null,
        'relation': _relationController.text.trim(),
        'interests': _interests,
        'favorite_colors': _selectedFavoriteColors,
        'dislikes': _dislikes,
        'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      };
      await apiService.updateRecipient(widget.recipientId, updatedData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Destinatario aggiornato con successo'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
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

  Widget _buildSection(String title, Widget content, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Wrap(
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
              color: isSelected ? AppTheme.primaryColor : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(option['icon']!, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  option['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seleziona i colori preferiti:',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colorOptions.map((option) {
            final isSelected = _selectedFavoriteColors.contains(option['value']);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _selectedFavoriteColors.remove(option['value']);
                } else {
                  _selectedFavoriteColors.add(option['value']!);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: option['color'],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      option['value']!,
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
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

  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                hint: 'es: Musica, Sport, Tecnologia',
                controller: _interestController,
                label: 'Aggiungi interesse',
                hintText: 'Inserisci un interesse',
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _addInterest,
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Aggiungi',
              ),
            ),
          ],
        ),
        if (_interests.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Interessi:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interests.map((interest) {
              return Chip(
                label: Text(
                  interest,
                  style: const TextStyle(fontSize: 12),
                ),
                onDeleted: () => setState(() => _interests.remove(interest)),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                deleteIconColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
              );
            }).toList(),
          ),
        ],
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
              child: CustomTextField(
                hint: 'es: Horror, Pesce, Sport estremi',
                controller: _dislikesController,
                label: 'Aggiungi cosa che non gradisce',
                hintText: 'Separare con virgole',
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _addDislike,
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Aggiungi',
              ),
            ),
          ],
        ),
        if (_dislikes.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Cose che non gradisce:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dislikes.map((dislike) {
              return Chip(
                label: Text(
                  dislike,
                  style: const TextStyle(fontSize: 12),
                ),
                onDeleted: () => setState(() => _dislikes.remove(dislike)),
                backgroundColor: Colors.red.withOpacity(0.1),
                deleteIconColor: Colors.red,
                side: BorderSide(color: Colors.red.withOpacity(0.3)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Modifica Destinatario',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),

                    _buildSection(
                      'Informazioni Base',
                      Column(
                        children: [
                          CustomTextField(
                            hint: 'Inserisci il nome',
                            controller: _nameController,
                            label: 'Nome',
                            validator: (value) => value!.isEmpty ? 'Il nome è obbligatorio' : null,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Genere',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          _buildGenderSelection(),
                          const SizedBox(height: 16),
                          CustomTextField(
                            hint: 'YYYY-MM-DD',
                            controller: _birthDateController,
                            label: 'Data di nascita',
                            readOnly: true,
                            onTap: _selectDate,
                          ),
                        ],
                      ),
                      icon: Icons.person,
                    ),

                    _buildSection(
                      'Relazione',
                      CustomTextField(
                        hint: 'es: amico, partner, famiglia...',
                        controller: _relationController,
                        label: 'Che relazione hai con questa persona?',
                      ),
                      icon: Icons.people,
                    ),

                    

                    // _buildSection(
                    //   'Colori Preferiti',
                    //   _buildColorSelection(),
                    //   icon: Icons.palette,
                    // ),

                    _buildSection(
                      'Interessi',
                      _buildInterestsSection(),
                      icon: Icons.favorite,
                    ),

                    _buildSection(
                      'Cose che Non Gradisce',
                      _buildDislikesSection(),
                      icon: Icons.not_interested,
                    ),

                    _buildSection(
                      'Note Aggiuntive',
                      CustomTextField(
                        hint: 'Aggiungi qualsiasi informazione utile...',
                        controller: _notesController,
                        label: 'Note personali',
                        maxLines: 4,
                      ),
                      icon: Icons.note_alt,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveRecipient,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Salva Modifiche',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
