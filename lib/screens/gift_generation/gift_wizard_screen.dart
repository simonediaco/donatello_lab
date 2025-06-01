import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/recipient.dart';
import '../../models/gift_request.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/recipient_avatar.dart';
import '../../widgets/custom_text_field.dart';
import '../../theme/app_theme.dart';
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

  Future<void> _generateGifts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.generateGiftIdeas({
        'name': _recipientName,
        'age': _recipientAge.isNotEmpty ? int.parse(_recipientAge) : 25,
        'gender': _recipientGender,
        'relation': _recipientRelation == 'altro' && _customRelation.isNotEmpty 
            ? _customRelation 
            : _recipientRelation,
        'interests': _selectedInterests,
        'occasion': _customOccasion.isNotEmpty ? _customOccasion : _selectedOccasion,
        'min_price': _minBudget.toString(),
        'max_price': _maxBudget.toString(),
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        print('API Response: $response');
        if (response['results'] != null) {
          print('Navigating to results with ${response['results'].length} gifts');
          context.go('/results', extra: {
            'recipientName': _recipientName.isNotEmpty ? _recipientName : 'Destinatario',
            'recipientAge': _recipientAge.isNotEmpty ? int.tryParse(_recipientAge) : null,
            'gifts': response['results'] ?? [],
          });
        } else {
          print('No gifts found in response');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Errore nella generazione delle idee regalo: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: _previousStep,
        ),
        title: _isLoading
            ? Text(
                'Generazione in corso...',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              )
            : Text(
                'Crea il regalo perfetto',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: AppTheme.textSecondaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Segui i passaggi per creare il regalo perfetto',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
            // Progress indicator
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} di 5',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              width: MediaQuery.of(context).size.width * 
                                     ((_currentStep + 1) / 5) * 
                                     (1 - 48/MediaQuery.of(context).size.width), // Account for padding
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
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
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      _currentStep < 4 ? 'Continua' : 'Genera idee regalo',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Per chi è questo regalo?',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aiutaci a conoscere meglio il destinatario',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),

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
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_recipientAge.isEmpty ? "18" : _recipientAge} anni',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Scorri per cambiare',
                      style: GoogleFonts.inter(
                        color: AppTheme.textTertiaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: AppTheme.borderColor,
                    thumbColor: AppTheme.primaryColor,
                    overlayColor: AppTheme.primaryColor.withOpacity(0.2),
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
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildGenderButton('Uomo', 'M'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderButton('Donna', 'F'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildGenderButton('Non binario', 'X'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderButton('Transgender', 'T'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildGenderButton('Altro', 'O'),
          const SizedBox(height: 24), // Extra padding at bottom
        ],
      ),
    );
  }

  Widget _buildGenderButton(String label, String value) {
    final isSelected = _recipientGender == value;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected ? AppTheme.softShadow : [],
      ),
      child: OutlinedButton(
        onPressed: () => setState(() => _recipientGender = value),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
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
            color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi è questa persona per te?',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.0, // Square cards
              children: [
                _buildRelationCard('Amico/a', 'amico', Icons.people),
                _buildRelationCard('Familiare', 'famiglia', Icons.family_restroom),
                _buildRelationCard('Collega', 'collega', Icons.work),
                _buildRelationCard('Partner', 'partner', Icons.favorite),
                _buildRelationCard('Mentore', 'mentore', Icons.school),
                _buildRelationCard('Altro', 'altro', Icons.person),
              ],
            ),
          ),

          // Custom relationship input - only appears when "altro" is selected
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
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.psychology,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Descrivi la relazione',
                        style: GoogleFonts.inter(
                          color: Colors.white,
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
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.primaryColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: TextFormField(
                      initialValue: _customRelation,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Es: migliore amica, collega del corso di yoga, vicina di casa...',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.all(20),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Icon(
                            Icons.edit_note,
                            color: AppTheme.primaryColor,
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
                      color: AppTheme.primaryColor.withOpacity(0.8),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getRelationDisplayName(String relation) {
    switch (relation) {
      case 'amico':
        return 'Amico/a';
      case 'famiglia':
        return 'Familiare';
      case 'collega':
        return 'Collega';
      case 'partner':
        return 'Partner';
      case 'mentore':
        return 'Mentore';
      case 'altro':
        return '';
      default:
        return relation;
    }
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
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : AppTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected ? null : AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
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
        ),
      ),
    );
  }

  IconData _getCategoryIconFromString(String category) {
    switch (category.toLowerCase()) {
      case 'tecnologia':
        return Icons.computer;
      case 'sport e fitness':
        return Icons.sports_tennis;
      case 'casa e giardino':
        return Icons.home;
      case 'libri e cultura':
        return Icons.book;
      case 'esperienze':
        return Icons.explore;
      case 'moda e bellezza':
        return Icons.checkroom;
      default:
        return Icons.category;
    }
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
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : AppTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected ? null : AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
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
        ),
      ),
    );
  }

  Widget _buildRelationCard(String label, String value, IconData icon) {
    final isSelected = _recipientRelation == value;
    return GestureDetector(
      onTap: () => setState(() => _recipientRelation = value),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : AppTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected ? null : AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
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
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quali sono le sue passioni?',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seleziona tutti gli interessi che si applicano',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Predefined interests grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.0, // Square cards
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
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.1),
                          AppTheme.primaryColor.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
Icons.add_circle,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Aggiungi altri interessi',
                              style: GoogleFonts.inter(
                                color: AppTheme.textPrimaryColor,
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
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      interest,
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textPrimaryColor,
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
                                        color: AppTheme.primaryColor,
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
                                  color: AppTheme.textPrimaryColor,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Es: fotografia, giardinaggio, yoga...',
                                  hintStyle: GoogleFonts.inter(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onFieldSubmitted: _addCustomInterest,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => _addCustomInterest(_customInterestController.text),
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Premi Invio o tocca + per aggiungere un interesse',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryColor.withOpacity(0.8),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
          Text(
            'Per quale occasione?',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seleziona l\'occasione per rendere il regalo più appropriato',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),

          // Grid delle occasioni predefinite
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
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
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_calendar,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Occasione personalizzata',
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimaryColor,
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
                    color: AppTheme.textPrimaryColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Es: festa di pensionamento, battesimo, prima comunione...',
                    hintStyle: GoogleFonts.inter(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.borderColor,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.event_note,
                        color: AppTheme.primaryColor,
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
                    color: AppTheme.primaryColor.withOpacity(0.8),
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

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'computer':
        return Icons.computer;
      case 'sports_tennis':
        return Icons.sports_tennis;
      case 'home':
        return Icons.home;
      case 'book':
        return Icons.book;
      case 'explore':
        return Icons.explore;
      case 'checkroom':
        return Icons.checkroom;
      default:
        return Icons.category;
    }
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qual è il tuo budget?',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scegli la fascia di prezzo più adatta alle tue esigenze',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),

          _buildBudgetCard('Bozzetto', 'Perfetto per pensieri carini', '0€ - 20€', Icons.edit, 0, 20),
          const SizedBox(height: 16),
          _buildBudgetCard('Regalo Delizioso', 'Idee bilanciate e apprezzate', '20€ - 50€', Icons.card_giftcard, 20, 50),
          const SizedBox(height: 16),
          _buildBudgetCard('Regalo Prezioso', 'Sorprendi con qualità', '50€ - 100€', Icons.diamond, 50, 100),
          const SizedBox(height: 16),
          _buildBudgetCard('Capolavoro', 'Il regalo dei sogni', '100€+', Icons.auto_awesome, 100, 450),

          const SizedBox(height: 32),

          // Budget personalizzato
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Budget personalizzato',
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimaryColor,
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
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: AppTheme.borderColor,
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
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '€${_minBudget.round()}',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryColor,
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
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '€${_maxBudget.round()}',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryColor,
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
          const SizedBox(height: 24), // Extra padding at bottom for scroll
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
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.15) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : AppTheme.primaryColor,
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
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
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
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
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