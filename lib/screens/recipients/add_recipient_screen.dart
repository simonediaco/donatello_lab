
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/cosmic_theme.dart';
import '../../widgets/custom_text_field.dart';

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
      duration: const Duration(milliseconds: 800),
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
    if (_currentStep < 3) {
      if (_validateCurrentStep()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      }
    } else {
      _saveRecipient();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          _showError('Il nome è obbligatorio');
          return false;
        }
        if (_selectedGender == null) {
          _showError('Seleziona il genere');
          return false;
        }
        return true;
      case 1:
        final relation = _showCustomRelation ? _customRelationController.text.trim() : _selectedRelation;
        if (relation == null || relation.isEmpty) {
          _showError('Specifica la relazione');
          return false;
        }
        return true;
      default:
        return true;
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
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

    final relation = _showCustomRelation ? _customRelationController.text.trim() : _selectedRelation;

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
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Destinatario salvato con successo!',
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
        context.pop();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Errore nel salvare il destinatario');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              
              // Progress
              _buildProgress(),
              
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
                  child: Form(
                    key: _formKey,
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
                ),
              ),
              
              // Bottom actions
              _buildBottomActions(),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuovo Destinatario',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Crea un profilo per trovare regali perfetti',
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

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CosmicTheme.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Passo 1 di 4',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CosmicTheme.primaryAccent,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Informazioni Base',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: CosmicTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Iniziamo con le informazioni essenziali',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: CosmicTheme.textSecondary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              CustomTextField(
                hint: 'Inserisci il nome',
                controller: _nameController,
                label: 'Nome *',
              ),
              
              const SizedBox(height: 24),
              
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
              
              const SizedBox(height: 24),
              
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
                        'Data di nascita (opzionale)',
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
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CosmicTheme.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Passo 2 di 4',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CosmicTheme.primaryAccent,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Relazione',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: CosmicTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Che relazione hai con questa persona?',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: CosmicTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _relationOptions.map((option) {
              final isSelected = _selectedRelation == option['value'];
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedRelation = option['value'];
                  _showCustomRelation = false;
                }),
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
          
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: () => setState(() {
              _showCustomRelation = !_showCustomRelation;
              if (_showCustomRelation) _selectedRelation = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: _showCustomRelation ? CosmicTheme.buttonGradient : null,
                color: _showCustomRelation ? null : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _showCustomRelation ? Colors.transparent : Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: _showCustomRelation ? CosmicTheme.lightShadow : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✏️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Altro',
                    style: GoogleFonts.inter(
                      color: _showCustomRelation ? Colors.white : CosmicTheme.textPrimary,
                      fontWeight: _showCustomRelation ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_showCustomRelation) ...[
            const SizedBox(height: 24),
            CustomTextField(
              hint: 'es: Cugino, Vicino di casa...',
              controller: _customRelationController,
              label: 'Specifica la relazione *',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CosmicTheme.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Passo 3 di 4',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CosmicTheme.primaryAccent,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Interessi',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: CosmicTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Seleziona gli interessi di questa persona',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: CosmicTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
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
                        option['value']!,
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
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  hint: 'es: Giardinaggio, Fotografia...',
                  controller: _customInterestController,
                  label: 'Aggiungi interesse personalizzato',
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
                  onPressed: _addCustomInterest,
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          
          if (_customInterests.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _customInterests.map((interest) {
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
                        onTap: () => setState(() => _customInterests.remove(interest)),
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
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CosmicTheme.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Passo 4 di 4',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CosmicTheme.primaryAccent,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Note Aggiuntive',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: CosmicTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Aggiungi dettagli che ci aiutino a trovare regali perfetti',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: CosmicTheme.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  hint: 'es: Horror, Pesce, Sport estremi',
                  controller: _dislikesController,
                  label: 'Cose che non gradisce (separare con virgole)',
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
          
          const SizedBox(height: 24),
          
          CustomTextField(
            hint: 'Aggiungi qualsiasi informazione utile...',
            controller: _notesController,
            label: 'Note personali (opzionale)',
            maxLines: 4,
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
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CosmicTheme.primaryAccent.withOpacity(0.3),
                    ),
                  ),
                  child: TextButton(
                    onPressed: _previousStep,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Indietro',
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
            ],
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: CosmicTheme.buttonGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: CosmicTheme.lightShadow,
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _currentStep < 3 ? 'Continua' : 'Salva Destinatario',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
