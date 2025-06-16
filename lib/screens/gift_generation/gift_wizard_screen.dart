import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../theme/cosmic_theme.dart';
import 'gift_loading_screen.dart';

class GiftWizardScreen extends ConsumerStatefulWidget {
  const GiftWizardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GiftWizardScreen> createState() => _GiftWizardScreenState();
}

class _GiftWizardScreenState extends ConsumerState<GiftWizardScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form data
  String _recipientName = '';
  String _recipientAge = '';
  String _recipientGender = 'M';
  String _recipientRelation = 'amico';
  String _customRelation = '';
  List<String> _selectedInterests = [];
  List<String> _customInterests = [];
  final TextEditingController _customInterestController = TextEditingController();
  String _selectedOccasion = '';
  String _customOccasion = '';
  final TextEditingController _customOccasionController = TextEditingController();
  double _minBudget = 0;
  double _maxBudget = 100;

  bool _isLoading = false;

  // Animation controllers
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animation
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    _pageController.dispose();
    _customInterestController.dispose();
    _customOccasionController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _interests = [
    {'name': 'Musica', 'icon': Icons.music_note},
    {'name': 'Sport', 'icon': Icons.sports_tennis},
    {'name': 'Tecnologia', 'icon': Icons.computer},
    {'name': 'Arte', 'icon': Icons.palette},
    {'name': 'Viaggi', 'icon': Icons.flight},
    {'name': 'Cucina', 'icon': Icons.restaurant},
    {'name': 'Moda', 'icon': Icons.checkroom},
    {'name': 'Lettura', 'icon': Icons.book},
    {'name': 'Gaming', 'icon': Icons.games},
    {'name': 'Benessere', 'icon': Icons.spa},
  ];

  final List<Map<String, dynamic>> _occasions = [
    {'name': 'Compleanno', 'icon': Icons.cake},
    {'name': 'Natale', 'icon': Icons.card_giftcard},
    {'name': 'San Valentino', 'icon': Icons.favorite},
    {'name': 'Anniversario', 'icon': Icons.celebration},
    {'name': 'Laurea', 'icon': Icons.school},
    {'name': 'Matrimonio', 'icon': Icons.favorite_border},
    {'name': 'Festa della Mamma', 'icon': Icons.volunteer_activism},
    {'name': 'Festa del Papà', 'icon': Icons.face},
  ];

  void _nextStep() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _generateGifts();
    }
  }

  bool _canProceedFromCurrentStep() {
    switch (_currentStep) {
      case 0:
        return true; // No mandatory fields in step 1
      case 1:
        return true; // Relation is always selected
      case 2:
        return _selectedInterests.isNotEmpty;
      case 3:
        return _selectedOccasion.isNotEmpty || _customOccasion.trim().isNotEmpty;
      case 4:
        return _validateBudget(); // Budget must be properly set
      default:
        return false;
    }
  }

  bool _validateBudget() {
    // Check if user has actually set a budget (not the default values)
    return _minBudget >= 0 && _maxBudget > 0 && _minBudget < _maxBudget && 
           !(_minBudget == 0 && _maxBudget == 100); // Not default values
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      // Torna alla intro page
      context.go('/generate-gifts');
    }
  }

  void _addCustomInterest(String interest) {
    final trimmedInterest = interest.trim();
    if (trimmedInterest.isNotEmpty && 
        !_customInterests.contains(trimmedInterest) && 
        !_selectedInterests.contains(trimmedInterest)) {
      setState(() {
        _customInterests.add(trimmedInterest);
        _selectedInterests.add(trimmedInterest);
        _customInterestController.clear();
      });
    }
  }

  bool _validateAllWizardData() {
    // Validate interests
    if (_selectedInterests.isEmpty) {
      _showError('Seleziona almeno un interesse');
      return false;
    }

    // Validate occasion
    if (_selectedOccasion.isEmpty && _customOccasion.trim().isEmpty) {
      _showError('Seleziona un\'occasione per il regalo');
      return false;
    }

    // Validate budget
    if (!_validateBudget()) {
      _showError('Imposta un budget valido (diverso da quello predefinito)');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _generateGifts() async {
    // Validate all required data before making API call
    if (!_validateAllWizardData()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Prepare the final occasion value
      final finalOccasion = _customOccasion.trim().isNotEmpty 
          ? _customOccasion.trim() 
          : _selectedOccasion;

      final requestData = {
        'name': _recipientName.isNotEmpty ? _recipientName : 'Destinatario',
        'age': _recipientAge.isNotEmpty ? (int.tryParse(_recipientAge) ?? 25) : 25,
        'gender': _recipientGender,
        'relation': _recipientRelation == 'altro' && _customRelation.trim().isNotEmpty 
            ? _customRelation.trim() 
            : _recipientRelation,
        'interests': _selectedInterests,
        'occasion': finalOccasion,
        'min_price': _minBudget.round(),
        'max_price': _maxBudget.round(),
      };

      final response = await apiService.generateGiftIdeas(requestData);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (response != null && 
            response.containsKey('results') && 
            response['results'] != null && 
            response['results'] is List &&
            (response['results'] as List).isNotEmpty) {
          context.go('/results', extra: {
            'recipientName': _recipientName.isNotEmpty ? _recipientName : 'Destinatario',
            'recipientAge': _recipientAge.isNotEmpty ? int.tryParse(_recipientAge) : null,
            'gifts': response['results'],
            'wizardData': {
              'name': _recipientName.isNotEmpty ? _recipientName : 'Destinatario',
              'gender': _recipientGender,
              'age': _recipientAge.isNotEmpty ? int.tryParse(_recipientAge) : null,
              'relation': _recipientRelation,
              'interests': _selectedInterests,
              'occasion': _customOccasion.isNotEmpty ? _customOccasion : _selectedOccasion,
              'minBudget': _minBudget.round(),
              'maxBudget': _maxBudget.round(),
            },
          });
        } else {
          _showError('Nessuna idea regalo generata. Prova con parametri diversi.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Errore nella generazione delle idee regalo';
        
        if (e.toString().contains('500')) {
          errorMessage = 'Errore del server. Riprova tra qualche momento.';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Parametri non validi. Controlla i dati inseriti.';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Servizio non disponibile. Riprova più tardi.';
        } else if (e.toString().contains('Connection') || e.toString().contains('network')) {
          errorMessage = 'Errore di connessione. Controlla la tua connessione internet.';
        }

        _showError(errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostra la schermata di loading quando sta generando i regali
    if (_isLoading) {
      return const GiftLoadingScreen();
    }

    return Scaffold(
      backgroundColor: CosmicTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: CosmicTheme.textPrimary),
          onPressed: _previousStep,
        ),
        title: _isLoading
            ? Text(
                'Generazione in corso...',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CosmicTheme.textPrimary,
                ),
              )
            : Column(
                children: [
                  Text(
                    'Crea il regalo perfetto',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CosmicTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '"L\'arte del donare è scritta nell\'universo"',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: CosmicTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: CosmicTheme.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Segui i passaggi per creare il regalo perfetto',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  backgroundColor: CosmicTheme.primaryAccent,
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: CosmicTheme.backgroundColor,
        ),
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
            // Progress indicator
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} di 5',
                      style: GoogleFonts.inter(
                        color: CosmicTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: CosmicTheme.secondaryAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              width: MediaQuery.of(context).size.width * 
                                     ((_currentStep + 1) / 5) * 
                                     (1 - 48/MediaQuery.of(context).size.width), // Account for padding
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    CosmicTheme.primaryAccentOnDark,
                                    CosmicTheme.primaryAccent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Step content
            Expanded(
              child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1(),
                        _buildStep2(),
                        _buildStep3(),
                        _buildStep4(),
                        _buildStep5(),
                      ],
                    ),
            ),

          // Navigation buttons
            if (!_isLoading)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: CosmicTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: CosmicTheme.lightShadow,
                    ),
                    child: ElevatedButton(
                        onPressed: _canProceedFromCurrentStep() ? _nextStep : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _currentStep < 4 ? 'Continua' : 'Genera idee regalo',
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
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: CosmicTheme.primaryAccentOnDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Per chi è questo regalo?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CosmicTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Aiutaci a conoscere meglio il destinatario',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CosmicTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          CustomTextField(
            hint: "Nome del destinatario (opzionale)",
            onChanged: (value) => _recipientName = value,
          ),
          const SizedBox(height: 16),

          // Modern age input
          Text(
            'Età',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CosmicTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: CosmicTheme.cardDecoration,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_recipientAge.isEmpty ? "18" : _recipientAge} anni',
                      style: GoogleFonts.inter(
                        color: CosmicTheme.primaryAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Scorri per cambiare',
                      style: GoogleFonts.inter(
                        color: CosmicTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: CosmicTheme.primaryAccent,
                    inactiveTrackColor: CosmicTheme.secondaryAccent,
                    thumbColor: CosmicTheme.primaryAccent,
                    overlayColor: CosmicTheme.primaryAccent.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _recipientAge.isEmpty ? 18 : double.parse(_recipientAge),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (value) {
                      setState(() => _recipientAge = value.round().toString());
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Genere',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CosmicTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildGenderButton('Uomo', 'M'),
              _buildGenderButton('Donna', 'F'),
              _buildGenderButton('Non binario', 'X'),
              _buildGenderButton('Transgender', 'T'),
              _buildGenderButton('Preferisco non dire', 'P'),
              _buildGenderButton('Altro', 'O'),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String label, String value) {
    final isSelected = _recipientGender == value;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected ? CosmicTheme.cosmicShadow : [],
      ),
      child: OutlinedButton(
        onPressed: () => setState(() => _recipientGender = value),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? CosmicTheme.primaryAccent : CosmicTheme.surfaceColor,
          side: BorderSide(
            color: isSelected ? CosmicTheme.primaryAccent : CosmicTheme.secondaryAccent,
            width: isSelected ? 2 : 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : CosmicTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: CosmicTheme.primaryAccentOnDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Chi è questa persona per te?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CosmicTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildRelationCard('Amico/a', 'amico', Icons.people),
              _buildRelationCard('Familiare', 'famiglia', Icons.family_restroom),
              _buildRelationCard('Collega', 'collega', Icons.work),
              _buildRelationCard('Partner', 'partner', Icons.favorite),
              _buildRelationCard('Mentore', 'mentore', Icons.school),
              _buildRelationCard('Altro', 'altro', Icons.person),
            ],
          ),

          // Custom relationship input
          if (_recipientRelation == 'altro') ...[
            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CosmicTheme.primaryAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.psychology,
                          color: CosmicTheme.primaryAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Descrivi la relazione',
                        style: GoogleFonts.inter(
                          color: CosmicTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: CosmicTheme.surfaceColor,
                      border: Border.all(
                        color: CosmicTheme.primaryAccent.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: CosmicTheme.softShadow,
                    ),
                    child: TextFormField(
                      initialValue: _customRelation,
                      style: GoogleFonts.inter(
                        color: CosmicTheme.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Es: migliore amica, collega del corso di yoga, vicina di casa...',
                        hintStyle: GoogleFonts.inter(
                          color: CosmicTheme.textSecondary,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(20),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Icon(
                            Icons.edit_note,
                            color: CosmicTheme.primaryAccent,
                            size: 20,
                          ),
                        ),
                      ),
                      maxLines: 2,
                      onChanged: (value) => _customRelation = value,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Più specifico sarai, più personalizzati saranno i suggerimenti!',
                    style: GoogleFonts.inter(
                      color: CosmicTheme.primaryAccent,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRelationCard(String label, String value, IconData icon) {
    final isSelected = _recipientRelation == value;
    return GestureDetector(
      onTap: () => setState(() => _recipientRelation = value),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? CosmicTheme.primaryAccent.withOpacity(0.15) : CosmicTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? CosmicTheme.primaryAccent : CosmicTheme.secondaryAccent,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? CosmicTheme.cosmicShadow : CosmicTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isSelected ? CosmicTheme.accentGradient : null,
                    color: isSelected ? null : CosmicTheme.primaryAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: CosmicTheme.primaryAccent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? Colors.white : CosmicTheme.primaryAccent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CosmicTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '✓',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: CosmicTheme.primaryAccentOnDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quali sono le sue passioni?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CosmicTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Seleziona tutti gli interessi che si applicano',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CosmicTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Predefined interests grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildInterestCard('Musica', 'musica', Icons.music_note),
              _buildInterestCard('Sport', 'sport', Icons.sports_tennis),
              _buildInterestCard('Tecnologia', 'tecnologia', Icons.computer),
              _buildInterestCard('Arte', 'arte', Icons.palette),
              _buildInterestCard('Viaggi', 'viaggi', Icons.flight),
              _buildInterestCard('Cucina', 'cucina', Icons.restaurant),
              _buildInterestCard('Moda', 'moda', Icons.checkroom),
              _buildInterestCard('Lettura', 'lettura', Icons.book),
              _buildInterestCard('Gaming', 'gaming', Icons.games),
              _buildInterestCard('Benessere', 'benessere', Icons.spa),
            ],
          ),

          const SizedBox(height: 32),

          // Custom interests section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: CosmicTheme.surfaceColor,
              border: Border.all(
                color: CosmicTheme.primaryAccent.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: CosmicTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CosmicTheme.primaryAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_circle,
                        color: CosmicTheme.primaryAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Aggiungi altri interessi',
                      style: GoogleFonts.inter(
                        color: CosmicTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Display custom interests as chips
                if (_customInterests.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _customInterests.map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: CosmicTheme.primaryAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: CosmicTheme.primaryAccent.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              interest,
                              style: GoogleFonts.inter(
                                color: CosmicTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _customInterests.remove(interest);
                                  _selectedInterests.remove(interest);
                                });
                              },
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: CosmicTheme.primaryAccent,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Add new interest input
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _customInterestController,
                        style: GoogleFonts.inter(
                          color: CosmicTheme.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Es: fotografia, giardinaggio, yoga...',
                          hintStyle: GoogleFonts.inter(
                            color: CosmicTheme.textSecondary,
                            fontSize: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: CosmicTheme.secondaryAccent),
                          ),
                          filled: true,
                          fillColor: CosmicTheme.backgroundColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onFieldSubmitted: _addCustomInterest,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: CosmicTheme.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => _addCustomInterest(_customInterestController.text),
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Premi Invio o tocca + per aggiungere un interesse',
                  style: GoogleFonts.inter(
                    color: CosmicTheme.primaryAccent,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInterestCard(String label, String value, IconData icon) {
    final isSelected = _selectedInterests.contains(value);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedInterests.remove(value);
          } else {
            _selectedInterests.add(value);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? CosmicTheme.primaryAccent.withOpacity(0.15) : CosmicTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? CosmicTheme.primaryAccent : CosmicTheme.secondaryAccent,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? CosmicTheme.cosmicShadow : CosmicTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isSelected ? CosmicTheme.accentGradient : null,
                    color: isSelected ? null : CosmicTheme.primaryAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: CosmicTheme.primaryAccent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? Colors.white : CosmicTheme.primaryAccent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CosmicTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '✓',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: CosmicTheme.primaryAccentOnDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Per quale occasione?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CosmicTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Seleziona l\'occasione per rendere il regalo più appropriato',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CosmicTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Grid delle occasioni predefinite
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: _occasions.map((occasion) {
              return _buildOccasionCard(
                occasion['name'],
                occasion['name'].toLowerCase(),
                occasion['icon'],
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Sezione occasione personalizzata
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: CosmicTheme.surfaceColor,
              border: Border.all(
                color: CosmicTheme.primaryAccent.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: CosmicTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CosmicTheme.primaryAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_calendar,
                        color: CosmicTheme.primaryAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Occasione personalizzata',
                      style: GoogleFonts.inter(
                        color: CosmicTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _customOccasionController,
                  style: GoogleFonts.inter(
                    color: CosmicTheme.textPrimary,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Es: festa di pensionamento, battesimo, prima comunione...',
                    hintStyle: GoogleFonts.inter(
                      color: CosmicTheme.textSecondary,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: CosmicTheme.secondaryAccent),
                    ),
                    filled: true,
                    fillColor: CosmicTheme.backgroundColor,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.event_note,
                        color: CosmicTheme.primaryAccent,
                        size: 20,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _customOccasion = value;
                      if (value.isNotEmpty) {
                        _selectedOccasion = '';
                      }
                    });
                  },
                ),

                const SizedBox(height: 12),
                Text(
                  'Descrivi l\'occasione speciale per suggerimenti più mirati!',
                  style: GoogleFonts.inter(
                    color: CosmicTheme.primaryAccent,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOccasionCard(String label, String value, IconData icon) {
    final isSelected = _selectedOccasion == value;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedOccasion = value;
        _customOccasion = '';
        _customOccasionController.clear();
      }),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? CosmicTheme.primaryAccent.withOpacity(0.15) : CosmicTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? CosmicTheme.primaryAccent : CosmicTheme.secondaryAccent,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? CosmicTheme.cosmicShadow : CosmicTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isSelected ? CosmicTheme.accentGradient : null,
                    color: isSelected ? null : CosmicTheme.primaryAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: CosmicTheme.primaryAccent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isSelected ? Colors.white : CosmicTheme.primaryAccent,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CosmicTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '✓',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: CosmicTheme.primaryAccentOnDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Qual è il tuo budget?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CosmicTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Scegli la fascia di prezzo più adatta alle tue esigenze',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CosmicTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          // Budget requirement notice
          if (!_validateBudget()) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seleziona una fascia di prezzo per continuare',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          _buildBudgetCard('Essenziale', 'Regali semplici ma significativi', '0€ - 20€', Icons.favorite_border, 0, 20),
          const SizedBox(height: 16),
          _buildBudgetCard('Classico', 'Il giusto equilibrio qualità-prezzo', '20€ - 50€', Icons.card_giftcard, 20, 50),
          const SizedBox(height: 16),
          _buildBudgetCard('Premium', 'Regali di qualità superiore', '50€ - 100€', Icons.diamond, 50, 100),
          const SizedBox(height: 16),
          _buildBudgetCard('Lusso', 'Per occasioni davvero speciali', '100€+', Icons.auto_awesome, 100, 450),

          const SizedBox(height: 32),

          // Budget personalizzato
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: CosmicTheme.surfaceColor,
              border: Border.all(
                color: CosmicTheme.primaryAccent.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: CosmicTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CosmicTheme.primaryAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: CosmicTheme.primaryAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Budget personalizzato',
                      style: GoogleFonts.inter(
                        color: CosmicTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                RangeSlider(
                  values: RangeValues(_minBudget, _maxBudget),
                  min: 0,
                  max: 450,
                  divisions: 45,
                  activeColor: CosmicTheme.primaryAccent,
                  inactiveColor: CosmicTheme.secondaryAccent,
                  labels: RangeLabels(
                    '€${_minBudget.round()}',
                    '€${_maxBudget.round()}',
                  ),
                  onChanged: (values) {
                    setState(() {
                      _minBudget = values.start;
                      _maxBudget = values.end;
                    });
                  },
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Min',
                          style: GoogleFonts.inter(
                            color: CosmicTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '€${_minBudget.round()}',
                          style: GoogleFonts.inter(
                            color: CosmicTheme.primaryAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Max',
                          style: GoogleFonts.inter(
                            color: CosmicTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '€${_maxBudget.round()}',
                          style: GoogleFonts.inter(
                            color: CosmicTheme.primaryAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(String title, String description, String range, IconData icon, double min, double max) {
    final isSelected = _minBudget == min && _maxBudget == max;
    return GestureDetector(
      onTap: () {
        setState(() {
          _minBudget = min;
          _maxBudget = max;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? CosmicTheme.primaryAccent.withOpacity(0.15) : CosmicTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? CosmicTheme.primaryAccent : CosmicTheme.secondaryAccent,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? CosmicTheme.cosmicShadow : CosmicTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: isSelected ? CosmicTheme.accentGradient : null,
                color: isSelected ? null : CosmicTheme.primaryAccent.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: CosmicTheme.primaryAccent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : CosmicTheme.primaryAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CosmicTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: CosmicTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  range,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CosmicTheme.primaryAccent,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CosmicTheme.primaryAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '✓',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}