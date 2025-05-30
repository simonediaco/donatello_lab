// File: add_recipient_screen.dart

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
    {'value': 'M', 'label': 'Male', 'icon': '👨'},
    {'value': 'F', 'label': 'Female', 'icon': '👩'},
    {'value': 'X', 'label': 'Non-binary', 'icon': '🧑'},
    {'value': 'T', 'label': 'Transgender', 'icon': '🏳️‍⚧️'},
    {'value': 'O', 'label': 'Other', 'icon': '👤'},
  ];

  final List<Map<String, String>> _relationOptions = [
    {'value': 'Friend', 'icon': '👥'},
    {'value': 'Partner', 'icon': '💕'},
    {'value': 'Family', 'icon': '👨‍👩‍👧‍👦'},
    {'value': 'Colleague', 'icon': '💼'},
    {'value': 'Mentor', 'icon': '🎓'},
  ];

  final List<Map<String, String>> _interestOptions = [
    {'value': 'Music', 'icon': '🎵'},
    {'value': 'Sports', 'icon': '⚽'},
    {'value': 'Technology', 'icon': '💻'},
    {'value': 'Art', 'icon': '🎨'},
    {'value': 'Travel', 'icon': '✈️'},
    {'value': 'Cooking', 'icon': '👨‍🍳'},
    {'value': 'Reading', 'icon': '📚'},
    {'value': 'Movies', 'icon': '🎬'},
    {'value': 'Fashion', 'icon': '👗'},
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
      setState(() => _errorMessage = 'Please select a gender');
      return;
    }

    final relation = _showCustomRelation ? _customRelationController.text.trim() : _selectedRelation;
    if (relation == null || relation.isEmpty) {
      setState(() => _errorMessage = 'Please specify the relationship');
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
          SnackBar(content: Text('Recipient saved successfully')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save recipient');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Recipient')),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // TODO: Replace with actual step widgets (_buildStep1(), etc.)
            Center(child: Text('Step 1')),
            Center(child: Text('Step 2')),
            Center(child: Text('Step 3')),
            Center(child: Text('Step 4')),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                child: Text(_currentStep < 3 ? 'Next' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
