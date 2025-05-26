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

class _GiftWizardScreenState extends ConsumerState<GiftWizardScreen> {
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
  String _selectedCategory = '';
  String _budget = '';
  double _minBudget = 0;
  double _maxBudget = 100;

  bool _isLoading = false;

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

  final List<Map<String, String>> _categories = [
    {'name': 'Tecnologia', 'icon': 'computer'},
    {'name': 'Sport e Fitness', 'icon': 'sports_tennis'},
    {'name': 'Casa e Giardino', 'icon': 'home'},
    {'name': 'Libri e Cultura', 'icon': 'book'},
    {'name': 'Esperienze', 'icon': 'explore'},
    {'name': 'Moda e Bellezza', 'icon': 'checkroom'},
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
        'category': _selectedCategory,
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _previousStep,
        ),
        title: _isLoading
            ? Text(
                'Generazione in corso...',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : Text(
                'Crea il regalo perfetto',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
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
      body: Column(
        children: [
          // Progress indicator
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${_currentStep + 1} of 5',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: MediaQuery.of(context).size.width * 
                                   ((_currentStep + 1) / 5) * 
                                   (1 - 48/MediaQuery.of(context).size.width), // Account for padding
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(3),
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
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentStep < 4 ? 'Continua' : 'Genera idee regalo',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aiutaci a conoscere meglio il destinatario',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
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
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Slider(
                  value: _recipientAge.isEmpty ? 18 : double.parse(_recipientAge),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: Colors.white.withOpacity(0.3),
                  onChanged: (value) {
                    setState(() => _recipientAge = value.round().toString());
                  },
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
              color: Colors.white,
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
    return OutlinedButton(
      onPressed: () => setState(() => _recipientGender = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.transparent,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.3),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
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
              color: Colors.white,
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
                _buildRelationImageCard('Friend', 'amico', 'assets/images/rel_friend.jpg'),
                _buildRelationImageCard('Family\nMember', 'famiglia', 'assets/images/rel_family.jpg'),
                _buildRelationImageCard('Colleague', 'collega', 'assets/images/rel_colleague.jpg'),
                _buildRelationImageCard('Partner', 'partner', 'assets/images/rel_partner.jpg'),
                _buildRelationImageCard('Mentor', 'mentore', 'assets/images/rel_mentor.jpg'),
                _buildRelationImageCard('Other', 'altro', 'assets/images/rel_other.jpg'),
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

  Widget _buildInterestImageCard(String label, String value, String imagePath) {
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.2),
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.cardColor,
                      child: Icon(
                        _getInterestIconFromString(value),
                        color: Colors.white54,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Text
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getInterestIconFromString(String interest) {
    switch (interest.toLowerCase()) {
      case 'musica':
        return Icons.music_note;
      case 'sport':
        return Icons.sports_tennis;
      case 'tecnologia':
        return Icons.computer;
      case 'arte':
        return Icons.palette;
      case 'viaggi':
        return Icons.flight;
      case 'cucina':
        return Icons.restaurant;
      case 'moda':
        return Icons.checkroom;
      case 'lettura':
        return Icons.book;
      case 'gaming':
        return Icons.games;
      case 'benessere':
        return Icons.spa;
      default:
        return Icons.star;
    }
  }

  Widget _buildRelationImageCard(String label, String value, String imagePath) {
    final isSelected = _recipientRelation == value;
    return GestureDetector(
      onTap: () => setState(() => _recipientRelation = value),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.2),
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.cardColor,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Text
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryImageCard(String label, String value, String imagePath) {
    final isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.2),
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.cardColor,
                      child: Icon(
                        _getCategoryIconFromString(value),
                        color: Colors.white54,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // Text
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                ),
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

  Widget _buildRelationCard(String label, String value, IconData icon) {
    final isSelected = _recipientRelation == value;
    return GestureDetector(
      onTap: () => setState(() => _recipientRelation = value),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? AppTheme.primaryColor : Colors.white70,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seleziona tutti gli interessi che si applicano',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
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
                      _buildInterestImageCard('Musica', 'musica', 'assets/images/int_music.jpg'),
                      _buildInterestImageCard('Sport', 'sport', 'assets/images/int_sport.jpg'),
                      _buildInterestImageCard('Tecnologia', 'tecnologia', 'assets/images/int_tech.jpg'),
                      _buildInterestImageCard('Arte', 'arte', 'assets/images/int_art.jpg'),
                      _buildInterestImageCard('Viaggi', 'viaggi', 'assets/images/int_travel.jpg'),
                      _buildInterestImageCard('Cucina', 'cucina', 'assets/images/int_cooking.jpg'),
                      _buildInterestImageCard('Moda', 'moda', 'assets/images/int_fashion.jpg'),
                      _buildInterestImageCard('Lettura', 'lettura', 'assets/images/int_reading.jpg'),
                      _buildInterestImageCard('Gaming', 'gaming', 'assets/images/int_gaming.jpg'),
                      _buildInterestImageCard('Benessere', 'benessere', 'assets/images/int_wellness.jpg'),
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
                                color: Colors.white,
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
                                        color: Colors.white,
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
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Es: fotografia, giardinaggio, yoga...',
                                  hintStyle: GoogleFonts.inter(
                                    color: Colors.white60,
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Che tipo di regalo stai cercando?',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scegli una categoria per orientare i suggerimenti',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
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
                _buildCategoryImageCard('Tech', 'Tecnologia', 'assets/images/cat_tech.jpg'),
                _buildCategoryImageCard('Sports', 'Sport e Fitness', 'assets/images/cat_sports.jpg'),
                _buildCategoryImageCard('Home', 'Casa e Giardino', 'assets/images/cat_home.jpg'),
                _buildCategoryImageCard('Books', 'Libri e Cultura', 'assets/images/cat_books.jpg'),
                _buildCategoryImageCard('Experiences', 'Esperienze', 'assets/images/cat_experiences.jpg'),
                _buildCategoryImageCard('Fashion', 'Moda e Bellezza', 'assets/images/cat_fashion.jpg'),
              ],
            ),
          ),
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aiutaci a trovare regali nella tua fascia di prezzo',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 48),

          _buildBudgetOption('Bozzetto', '0-20€', 0, 20),
          const SizedBox(height: 16),
          _buildBudgetOption('Affresco', '20€ - 50€', 20, 50),
          const SizedBox(height: 16),
          _buildBudgetOption('Dipinto', '50€ - 100€', 50, 100),
          const SizedBox(height: 16),
          _buildBudgetOption('Capolavoro', '100€+', 100, 450),

          const SizedBox(height: 32),

          Text(
            'Budget personalizzato (€)',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                RangeSlider(
                  values: RangeValues(_minBudget, _maxBudget),
                  min: 0,
                  max: 450,
                  divisions: 25,
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: Colors.white.withOpacity(0.3),
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '€${_minBudget.round()}',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '€${_maxBudget.round()}',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildBudgetOption(String label, String range, double min, double max) {
    final isSelected = _minBudget == min && _maxBudget == max;
    return GestureDetector(
      onTap: () {
        setState(() {
          _minBudget = min;
          _maxBudget = max;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.1),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              range,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _customInterestController.dispose();
    super.dispose();
  }
}