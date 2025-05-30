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

class _EditRecipientScreenState extends ConsumerState<EditRecipientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _relationController = TextEditingController();
  final _interestsController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  Recipient? _recipient;

  @override
  void initState() {
    super.initState();
    _loadRecipient();
  }

  Future<void> _loadRecipient() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final data = await apiService.getRecipient(widget.recipientId);
      setState(() {
        _recipient = Recipient.fromJson(data);
        _nameController.text = _recipient?.name ?? '';
        _birthDateController.text = _recipient?.birthDate ?? '';
        _relationController.text = _recipient?.relation ?? '';
        _interestsController.text = _recipient?.interests?.join(', ') ?? '';
        _notesController.text = _recipient?.notes ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load recipient';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRecipient() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      final apiService = ref.read(apiServiceProvider);
      final updatedData = {
        'name': _nameController.text,
        'birth_date': _birthDateController.text,
        'relation': _relationController.text,
        'interests': _interestsController.text.split(',').map((e) => e.trim()).toList(),
        'notes': _notesController.text
      };
      await apiService.updateRecipient(widget.recipientId, updatedData);
      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save recipient';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _relationController.dispose();
    _interestsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Recipient'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Name', hint: '',
                      validator: (value) => value!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _birthDateController,
                      label: 'Birth Date', hint: '',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _relationController,
                      label: 'Relation', hint: '',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _interestsController,
                      label: 'Interests (comma separated)', hint: '',
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _notesController,
                      label: 'Notes',
                      maxLines: 3, hint: '',
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Save',
                      onPressed: _saveRecipient,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
