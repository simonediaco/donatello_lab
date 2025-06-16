
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/recipient.dart';
import '../../services/api_service.dart';
import '../../theme/cosmic_theme.dart';
import 'gift_loading_screen.dart';

class GiftWizardRecipientScreen extends ConsumerStatefulWidget {
  final Recipient recipient;

  const GiftWizardRecipientScreen({Key? key, required this.recipient}) : super(key: key);

  @override
  ConsumerState<GiftWizardRecipientScreen> createState() => _GiftWizardRecipientScreenState();
}

class _GiftWizardRecipientScreenState extends ConsumerState<GiftWizardRecipientScreen>
    with TickerProviderStateMixin {
  
  // Wizard steps
  int _currentStep = 0;
  final int _totalSteps = 2;
  
  // Step 1: Occasion selection
  String _selectedOccasion = '';
  String _customOccasion = '';
  final TextEditingController _customOccasionController = TextEditingController();
  
  // Step 2: Budget selection
  double _minBudget = 0;
  double _maxBudget = 100;
  
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customOccasionController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  bool _canProceedFromStep(int step) {
    switch (step) {
      case 0: // Occasion step
        return _selectedOccasion.isNotEmpty || _customOccasion.trim().isNotEmpty;
      case 1: // Budget step
        return _validateBudget();
      default:
        return false;
    }
  }

  bool _validateBudget() {
    // Check if user has actually set a budget (not the default values)
    return _minBudget >= 0 && _maxBudget > 0 && _minBudget < _maxBudget && 
           !(_minBudget == 0 && _maxBudget == 100); // Not default values
  }

  bool _validateRecipientWizardData() {
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
    if (!_validateRecipientWizardData()) {
      return;
    }

    // Additional validation for recipient ID
    if (widget.recipient.id == null) {
      _showError('Errore: ID destinatario non valido');
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

      final response = await apiService.generateGiftIdeasForRecipient(
        widget.recipient.id!,
        {
          'occasion': finalOccasion,
          'min_price': _minBudget.round(),
          'max_price': _maxBudget.round(),
        }
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response['results'] != null) {
          context.go('/results', extra: {
            'recipientName': widget.recipient.name,
            'recipientAge': widget.recipient.age,
            'gifts': response['results'] ?? [],
            'existingRecipient': widget.recipient,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Nessuna idea regalo trovata. Prova con parametri diversi.',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.orange.shade700,
            ),
          );
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
    if (_isLoading) {
      return const GiftLoadingScreen();
    }

    return Scaffold(
      backgroundColor: CosmicTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: CosmicTheme.textPrimary),
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              context.go('/generate-gifts');
            }
          },
        ),
        title: Column(
          children: [
            Text(
              'Regalo per ${widget.recipient.name}',
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: CosmicTheme.backgroundColor,
        ),
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${_currentStep + 1} di $_totalSteps',
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
                                   ((_currentStep + 1) / _totalSteps) * 
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

            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildStepContent(),
                  ),
                ),
              ),
            ),

            // Bottom navigation
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CosmicTheme.primaryAccent,
                          side: BorderSide(color: CosmicTheme.primaryAccent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Indietro',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: CosmicTheme.buttonGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: CosmicTheme.lightShadow,
                      ),
                      child: ElevatedButton(
                        onPressed: _canProceedFromStep(_currentStep) 
                          ? (_currentStep == _totalSteps - 1 ? _generateGifts : _nextStep)
                          : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentStep == _totalSteps - 1 ? 'Genera idee regalo' : 'Continua',
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
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildOccasionStep();
      case 1:
        return _buildBudgetStep();
      default:
        return Container();
    }
  }

  Widget _buildOccasionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipient info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: CosmicTheme.cardDecoration,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: CosmicTheme.accentGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.recipient.name.isNotEmpty 
                        ? widget.recipient.name[0].toUpperCase() 
                        : '?',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.recipient.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CosmicTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.recipient.relation.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.recipient.relation,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CosmicTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (widget.recipient.age != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${widget.recipient.age} anni',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CosmicTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Occasion selection
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
        const SizedBox(height: 24),

        // Grid delle occasioni
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: _occasions.map((occasion) {
            return _buildOccasionCard(
              occasion['name'],
              occasion['name'].toLowerCase(),
              occasion['icon'],
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        // Custom occasion
        Container(
          padding: const EdgeInsets.all(16),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: CosmicTheme.primaryAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.edit_calendar,
                      color: CosmicTheme.primaryAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Occasione personalizzata',
                      style: GoogleFonts.inter(
                        color: CosmicTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customOccasionController,
                style: GoogleFonts.inter(
                  color: CosmicTheme.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Es: festa di pensionamento, battesimo...',
                  hintStyle: GoogleFonts.inter(
                    color: CosmicTheme.textSecondary,
                    fontSize: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: CosmicTheme.backgroundColor,
                  contentPadding: const EdgeInsets.all(12),
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
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBudgetStep() {
    return Column(
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
        const SizedBox(height: 24),

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
          padding: const EdgeInsets.all(16),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: CosmicTheme.primaryAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.tune,
                      color: CosmicTheme.primaryAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Budget personalizzato',
                      style: GoogleFonts.inter(
                        color: CosmicTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 8),
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
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '€${_minBudget.round()}',
                        style: GoogleFonts.inter(
                          color: CosmicTheme.primaryAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '€${_maxBudget.round()}',
                        style: GoogleFonts.inter(
                          color: CosmicTheme.primaryAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? CosmicTheme.primaryAccent : CosmicTheme.secondaryAccent,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? CosmicTheme.cosmicShadow : CosmicTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: isSelected ? CosmicTheme.accentGradient : null,
                  color: isSelected ? null : CosmicTheme.primaryAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : CosmicTheme.primaryAccent,
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
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? CosmicTheme.primaryAccent.withOpacity(0.15) : CosmicTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? CosmicTheme.primaryAccent : CosmicTheme.secondaryAccent,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? CosmicTheme.cosmicShadow : CosmicTheme.softShadow,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isSelected ? CosmicTheme.accentGradient : null,
                  color: isSelected ? null : CosmicTheme.primaryAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSelected ? Colors.white : CosmicTheme.primaryAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CosmicTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CosmicTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    range,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: CosmicTheme.primaryAccent,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: CosmicTheme.primaryAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
