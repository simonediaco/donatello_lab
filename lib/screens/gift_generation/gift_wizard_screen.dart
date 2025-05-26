import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/recipient.dart';
import '../../models/gift_request.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/recipient_avatar.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../theme/app_theme.dart';

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
  List<String> _selectedInterests = [];
  String _selectedCategory = '';
  String _budget = '';
  double _minBudget = 0;
  double _maxBudget = 100;

  bool _isLoading = false;

  final List<Map<String, dynamic>> _interests = [
    {'name': 'Musica', 'icon': Icons.music_note},
    {'name': 'Sport', 'icon': Icons.sports_tennis},
    {'name': 'Tech', 'icon': Icons.computer},
    {'name': 'Arte', 'icon': Icons.palette},
    {'name': 'Viaggi', 'icon': Icons.flight},
    {'name': 'Cibo', 'icon': Icons.restaurant},
    {'name': 'Moda', 'icon': Icons.checkroom},
    {'name': 'Lettura', 'icon': Icons.book},
    {'name': 'Gaming', 'icon': Icons.games},
    {'name': 'Astrologia', 'icon': Icons.star},
  ];

  final List<Map<String, String>> _categories = [
    {'name': 'Tech', 'image': 'assets/images/cat_tech.jpg'},
    {'name': 'Sports', 'image': 'assets/images/cat_sports.jpg'},
    {'name': 'Home', 'image': 'assets/images/cat_home.jpg'},
    {'name': 'Books', 'image': 'assets/images/cat_books.jpg'},
    {'name': 'Experiences', 'image': 'assets/images/cat_experiences.jpg'},
    {'name': 'Fashion', 'image': 'assets/images/cat_fashion.jpg'},
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
    }
  }

  Future<void> _generateGifts() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.generateGiftIdeas({
        'name': _recipientName,
        'age': _recipientAge,
        'gender': _recipientGender,
        'relation': _recipientRelation,
        'interests': _selectedInterests,
        'category': _selectedCategory,
        'min_price': _minBudget.toString(),
        'max_price': _maxBudget.toString(),
      });

      if (mounted) {
        context.go('/results', extra: {
          'recipientName': _recipientName.isNotEmpty ? _recipientName : 'Destinatario',
          'recipientAge': _recipientAge.isNotEmpty ? int.tryParse(_recipientAge) : null,
          'gifts': response['gifts'] ?? [],
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: ${e.toString()}')),
        );
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentStep > 0 ? _previousStep : () => context.pop(),
        ),
        title: const Text('New Gift'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // TODO: Show help
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: List.generate(
                5,
                (index) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? AppTheme.primaryColor
                          : AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: CustomButton(
              text: _currentStep < 4 ? 'Next' : 'Generate',
              onPressed: _nextStep,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _currentStep == 0 
          ? const CustomBottomNavigation(currentIndex: 3)
          : null,
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who is this gift for?',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 32),
          CustomTextField(
            hint: "Recipient's Name (optional)",
            onChanged: (value) => _recipientName = value,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _recipientAge.isEmpty ? null : _recipientAge,
                hint: Text("Recipient's Age"),
                isExpanded: true,
                items: List.generate(100, (index) => (index + 1).toString())
                    .map((age) => DropdownMenuItem(
                          value: age,
                          child: Text(age),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _recipientAge = value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildGenderButton('Male', 'M'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderButton('Female', 'F'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderButton('Other', 'O'),
              ),
            ],
          ),
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
          color: isSelected ? AppTheme.primaryColor : AppTheme.subtitleColor,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
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
            'Who is this gift for?',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildRelationCard('Friend', 'amico', 'assets/images/rel_friend.jpg'),
                _buildRelationCard('Family\nMember', 'famiglia', 'assets/images/rel_family.jpg'),
                _buildRelationCard('Colleague', 'collega', 'assets/images/rel_colleague.jpg'),
                _buildRelationCard('Partner', 'partner', 'assets/images/rel_partner.jpg'),
                _buildRelationCard('Mentor', 'mentore', 'assets/images/rel_mentor.jpg'),
                _buildRelationCard('Other', 'altro', 'assets/images/rel_other.jpg'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationCard(String label, String value, String image) {
    final isSelected = _recipientRelation == value;
    return GestureDetector(
      onTap: () => setState(() => _recipientRelation = value),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 48,
              color: isSelected ? AppTheme.primaryColor : AppTheme.subtitleColor,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.displaySmall,
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
            'What are their passions? Select all that apply.',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: _interests.map((interest) {
                final isSelected = _selectedInterests.contains(interest['name']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedInterests.remove(interest['name']);
                      } else {
                        _selectedInterests.add(interest['name']);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryColor.withOpacity(0.2) 
                          : AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          interest['icon'],
                          size: 32,
                          color: isSelected ? AppTheme.primaryColor : Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          interest['name'],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              // TODO: Add custom interest
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Add custom interest'),
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
            'What type of gift are you looking for?',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category['name']!),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category,
                          size: 48,
                          color: isSelected ? AppTheme.primaryColor : Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          category['name']!,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's your budget?",
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 48),
          _buildBudgetOption('Small', '0-20€', 0, 20),
          const SizedBox(height: 16),
          _buildBudgetOption('Medium', '20€ - 50€', 20, 50),
          const SizedBox(height: 16),
          _buildBudgetOption('Large', '50€ - 100€', 50, 100),
          const SizedBox(height: 16),
          _buildBudgetOption('Extra Large', '100€+', 100, 500),
          const SizedBox(height: 32),
          Text(
            'Custom Budget (€)',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          RangeSlider(
            values: RangeValues(_minBudget, _maxBudget),
            min: 0,
            max: 500,
            divisions: 20,
            activeColor: AppTheme.primaryColor,
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
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            Text(
              range,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.subtitleColor,
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
    super.dispose();
  }
}