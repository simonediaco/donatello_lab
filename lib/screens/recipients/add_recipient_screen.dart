
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class AddRecipientScreen extends ConsumerStatefulWidget {
  const AddRecipientScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddRecipientScreen> createState() => _AddRecipientScreenState();
}

class _AddRecipientScreenState extends ConsumerState<AddRecipientScreen>
    with TickerProviderStateMixin {
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
  String? _errorMessage;
  int _currentStep = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final PageController _pageController = PageController();

  final List<Map<String, String>> _genderOptions = [
    {'value': 'M', 'label': 'Uomo', 'icon': '👨'},
    {'value': 'F', 'label': 'Donna', 'icon': '👩'},
    {'value': 'X', 'label': 'Non-binario', 'icon': '🧑'},
    {'value': 'T', 'label': 'Transgender', 'icon': '🏳️‍⚧️'},
    {'value': 'O', 'label': 'Altro', 'icon': '👤'},
  ];

  final List<Map<String, String>> _relationOptions = [
    {'value': 'amico', 'label': 'Amico', 'icon': '👥'},
    {'value': 'partner', 'label': 'Partner', 'icon': '💕'},
    {'value': 'famiglia', 'label': 'Famiglia', 'icon': '👨‍👩‍👧‍👦'},
    {'value': 'collega', 'label': 'Collega', 'icon': '💼'},
    {'value': 'mentore', 'label': 'Mentore', 'icon': '🎓'},
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
    {'value': 'Moda', 'icon': '👗'},
    {'value': 'Gaming', 'icon': '🎮'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
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
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      if (_currentStep < 3) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      } else {
        _saveRecipient();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _birthDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  void _addCustomInterest() {
    final text = _customInterestController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _customInterests.add(text);
        _customInterestController.clear();
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
    setState(() => _errorMessage = null);

    if (_selectedGender == null) {
      setState(() => _errorMessage = 'Seleziona il genere');
      return;
    }

    final relation = _showCustomRelation ? _customRelationController.text.trim() : _selectedRelation;
    if (relation == null || relation.isEmpty) {
      setState(() => _errorMessage = 'Specifica la relazione');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final recipientData = {
        'name': _nameController.text.trim(),
        'gender': _selectedGender,
        'birth_date': _birthDateController.text.isNotEmpty ? _birthDateController.text : null,
        'relation': relation,
        'interests': [..._selectedInterests, ..._customInterests],
        'favorite_colors': <String>[],
        'dislikes': _dislikes,
        'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      };
      await apiService.createRecipient(recipientData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Destinatario salvato con successo')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Errore nel salvare il destinatario');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informazioni base',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            hint: 'Inserisci il nome',
            controller: _nameController,
            label: 'Nome',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Il nome è obbligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const Text('Genere', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genderOptions.map((option) {
              final isSelected = _selectedGender == option['value'];
              return GestureDetector(
                onTap: () => setState(() => _selectedGender = option['value']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
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
          ),
          const SizedBox(height: 16),
          CustomTextField(
            hint: 'YYYY-MM-DD',
            controller: _birthDateController,
            label: 'Data di nascita (opzionale)',
            hintText: 'YYYY-MM-DD',
            readOnly: true,
            onTap: _selectDate,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Relazione',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('Che relazione hai con questa persona?'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _relationOptions.map((option) {
              final isSelected = _selectedRelation == option['value'];
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedRelation = option['value'];
                  _showCustomRelation = false;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
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
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() {
              _showCustomRelation = !_showCustomRelation;
              if (_showCustomRelation) _selectedRelation = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _showCustomRelation ? AppTheme.primaryColor : Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _showCustomRelation ? AppTheme.primaryColor : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✏️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Altro',
                    style: TextStyle(
                      color: _showCustomRelation ? Colors.white : Colors.black87,
                      fontWeight: _showCustomRelation ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showCustomRelation) ...[
            const SizedBox(height: 16),
            CustomTextField(
              hint: 'es: Cugino, Vicino di casa...',
              controller: _customRelationController,
              label: 'Specifica la relazione',
              validator: (value) {
                if (_showCustomRelation && (value == null || value.isEmpty)) {
                  return 'Specifica la relazione';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interessi',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('Seleziona gli interessi di questa persona:'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interestOptions.map((option) {
              final isSelected = _selectedInterests.contains(option['value']);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(option['value']);
                  } else {
                    _selectedInterests.add(option['value']!);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(option['icon']!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        option['value']!,
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
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  hint: 'es: Giardinaggio, Fotografia...',
                  controller: _customInterestController,
                  label: 'Aggiungi interesse personalizzato',
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addCustomInterest,
                icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
              ),
            ],
          ),
          if (_customInterests.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _customInterests.map((interest) {
                return Chip(
                  label: Text(interest),
                  onDeleted: () => setState(() => _customInterests.remove(interest)),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Note aggiuntive',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  hint: 'es: Horror, Pesce, Sport estremi',
                  controller: _dislikesController,
                  label: 'Cose che non gradisce (separare con virgole)',
                  hintText: 'es: Horror, Pesce, Sport estremi',
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addDislike,
                icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
              ),
            ],
          ),
          if (_dislikes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dislikes.map((dislike) {
                return Chip(
                  label: Text(dislike),
                  onDeleted: () => setState(() => _dislikes.remove(dislike)),
                  backgroundColor: Colors.red.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          CustomTextField(
            hint: 'Aggiungi qualsiasi informazione utile...',
            controller: _notesController,
            label: 'Note personali (opzionale)',
            hintText: 'Aggiungi qualsiasi informazione utile...',
            maxLines: 4,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aggiungi Destinatario'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: List.generate(4, (index) {
                  final isActive = index <= _currentStep;
                  final isCompleted = index < _currentStep;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primaryColor : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
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
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  child: const Text('Indietro'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _currentStep < 3 ? 'Avanti' : 'Salva',
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
