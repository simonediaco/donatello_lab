import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/gift.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class GenerateScreen extends ConsumerStatefulWidget {
  const GenerateScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _interestsController = TextEditingController();
  
  String _selectedGender = '';
  String _selectedRelation = '';
  String _selectedCategory = '';
  bool _isGenerating = false;
  List<Gift> _generatedGifts = [];

  late AnimationController _animationController;
  late AnimationController _resultsController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _resultsFadeAnimation;

  final List<String> _genders = ['M', 'F', 'Other'];
  final List<String> _relations = [
    'Partner', 'Friend', 'Family', 'Colleague', 'Acquaintance', 'Other'
  ];
  final List<String> _categories = [
    'Tech', 'Fashion', 'Books', 'Sports', 'Home', 'Art', 'Food', 'Travel', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _resultsController = AnimationController(
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
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _resultsFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _resultsController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _interestsController.dispose();
    _animationController.dispose();
    _resultsController.dispose();
    super.dispose();
  }

  Future<void> _generateGifts() async {
    // Validation
    if (_ageController.text.trim().isEmpty) {
      _showError('Please enter the recipient\'s age');
      return;
    }

    if (_selectedGender.isEmpty) {
      _showError('Please select gender');
      return;
    }

    if (_selectedRelation.isEmpty) {
      _showError('Please select relationship');
      return;
    }

    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 1 || age > 120) {
      _showError('Please enter a valid age (1-120)');
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      
      final interests = _interestsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final response = await apiService.generateGiftIdeas({
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'gender': _selectedGender,
        'relation': _selectedRelation.toLowerCase(),
        'interests': interests,
        'category': _selectedCategory.isNotEmpty ? _selectedCategory : null,
        'min_price': _minPriceController.text.trim(),
        'max_price': _maxPriceController.text.trim(),
      });

      final gifts = (response['results'] as List<dynamic>?)
          ?.map((item) => Gift.fromJson(item))
          .toList() ?? [];

      setState(() {
        _generatedGifts = gifts;
        _isGenerating = false;
      });

      if (gifts.isNotEmpty) {
        _resultsController.forward();
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _scrollToResults();
        }
      } else {
        _showError('No gift ideas generated. Please try different parameters.');
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      _showError('Error generating gifts: ${e.toString()}');
    }
  }

  void _scrollToResults() {
    // Implement scrolling to results section
    // This would depend on your scroll controller implementation
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.softShadow,
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text('Generate Gift Ideas'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.softShadow,
              ),
              child: const Icon(Icons.history, size: 20),
            ),
            onPressed: () => context.push('/history'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header section
                  _buildHeader(),
                  const SizedBox(height: 32),
                  
                  // Form section
                  _buildForm(),
                  const SizedBox(height: 32),
                  
                  // Generate button
                  CustomButton(
                    text: 'Generate Gift Ideas',
                    onPressed: _generateGifts,
                    isLoading: _isGenerating,
                    icon: Icons.auto_awesome,
                  ),
                  
                  // Results section
                  if (_generatedGifts.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    _buildResults(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.elevatedCardDecoration,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.mediumShadow,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'AI-Powered Gift Ideas',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about the recipient and we\'ll suggest perfect gifts tailored just for them',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recipient Details',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          
          // Name (optional)
          CustomTextField(
            label: 'Name (Optional)',
            hint: 'Enter recipient\'s name',
            controller: _nameController,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 20),
          
          // Age and Gender
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'Age *',
                  hint: 'Age',
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderSelector(),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Relationship
          _buildRelationshipSelector(),
          const SizedBox(height: 20),
          
          // Interests
          CustomTextField(
            label: 'Interests (Optional)',
            hint: 'e.g., Music, Sports, Reading',
            controller: _interestsController,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          
          // Category
          _buildCategorySelector(),
          const SizedBox(height: 20),
          
          // Price range
          Text(
            'Price Range (Optional)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  hint: 'Min price',
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.euro, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  hint: 'Max price',
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.euro, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender *',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender.isEmpty ? null : _selectedGender,
              hint: const Text('Select'),
              isExpanded: true,
              items: _genders.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(_getGenderLabel(gender)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedGender = value ?? '');
              },
            ),
          ),
        ),
      ],
    );
  }

  String _getGenderLabel(String gender) {
    switch (gender) {
      case 'M': return 'Male';
      case 'F': return 'Female';
      case 'Other': return 'Other';
      default: return gender;
    }
  }

  Widget _buildRelationshipSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relationship *',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _relations.map((relation) {
            final isSelected = _selectedRelation == relation;
            return GestureDetector(
              onTap: () => setState(() => _selectedRelation = relation),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected ? AppTheme.softShadow : null,
                ),
                child: Text(
                  relation,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category (Optional)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return GestureDetector(
              onTap: () => setState(() => 
                _selectedCategory = isSelected ? '' : category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return FadeTransition(
      opacity: _resultsFadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generated Gift Ideas',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            '${_generatedGifts.length} personalized suggestions',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _generatedGifts.length,
            itemBuilder: (context, index) {
              return _buildGiftCard(_generatedGifts[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGiftCard(Gift gift, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showGiftDetails(gift),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gift image placeholder
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Gift details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gift.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          if (gift.price > 0) ...[
                            Text(
                              '€${gift.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (gift.match != null && gift.match! > 0) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.stars,
                                  color: AppTheme.warningColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${gift.match}% match',
                                  style: TextStyle(
                                    color: AppTheme.warningColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Save button
                    IconButton(
                      onPressed: () => _saveGift(gift),
                      icon: Icon(
                        Icons.bookmark_outline,
                        color: AppTheme.textTertiaryColor,
                      ),
                    ),
                  ],
                ),
                
                if (gift.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Text(
                    gift.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                if (gift.category?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      gift.category!,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGiftDetails(Gift gift) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Gift details
              Text(
                gift.name,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 16),
              
              if (gift.description?.isNotEmpty == true) ...[
                Text(
                  gift.description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
              ],
              
              // Action buttons
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Save Gift',
                      onPressed: () {
                        Navigator.pop(context);
                        _saveGift(gift);
                      },
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Share',
                      onPressed: () {
                        Navigator.pop(context);
                        _shareGift(gift);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveGift(Gift gift) {
    // TODO: Implement save gift functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${gift.name} saved to your collection'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _shareGift(Gift gift) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }
}