import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/gift.dart';
import '../services/api_service.dart';
import '../theme/cosmic_theme.dart';
import 'buttons.dart';

// Modal per il disclaimer di salvataggio regalo
class SaveGiftDisclaimerModal extends StatelessWidget {
  final Gift gift;
  final VoidCallback onCreateRecipient;

  const SaveGiftDisclaimerModal({
    Key? key,
    required this.gift,
    required this.onCreateRecipient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        margin: const EdgeInsets.symmetric(vertical: 80),
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(
          maxWidth: 360,
          maxHeight: 400,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header minimalista
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: CosmicTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add,
                color: Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(height: 16),

            // Titolo
            Text(
              'Crea destinatario',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CosmicTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Messaggio conciso
            Text(
              'Salva questo regalo creando prima un destinatario',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CosmicTheme.textSecondary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Nome del regalo - più compatto
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: CosmicTheme.primaryAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '"${gift.name}"',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CosmicTheme.primaryAccent,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Column(
              children: [
                PrimaryButton(
                  text: 'Crea destinatario',
                  onPressed: onCreateRecipient,
                  icon: Icons.add,
                  height: 42,
                ),

                const SizedBox(height: 10),

                GreyButton(
                  text: 'Forse dopo',
                  onPressed: () => Navigator.of(context).pop(),
                  height: 42,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Modal per confermare l'apertura di link esterni
class ExternalLinkDisclaimerModal extends StatelessWidget {
  final String url;
  final VoidCallback onConfirm;

  const ExternalLinkDisclaimerModal({
    Key? key,
    required this.url,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        margin: const EdgeInsets.symmetric(vertical: 80),
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(
          maxWidth: 360,
          maxHeight: 380,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con icona colorata
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: CosmicTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart,
                color: Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(height: 16),

            // Titolo
            Text(
              'Visualizza prodotto',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CosmicTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Messaggio principale
            Text(
              'Stai per uscire dall\'app per vedere il prodotto nel negozio online.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CosmicTheme.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Reminder box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: CosmicTheme.primaryAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CosmicTheme.primaryAccent.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: CosmicTheme.primaryAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ricordati di tornare su Donatello per scoprire altri regali!',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CosmicTheme.primaryAccent,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Column(
              children: [
                PrimaryButton(
                  text: 'Vai al prodotto',
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  icon: Icons.open_in_new,
                  height: 42,
                ),

                const SizedBox(height: 10),

                GreyButton(
                  text: 'Rimani nell\'app',
                  onPressed: () => Navigator.of(context).pop(),
                  height: 42,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Modal per il disclaimer di acquisto
class PurchaseDisclaimerModal extends StatelessWidget {
  final Gift gift;

  const PurchaseDisclaimerModal({
    Key? key,
    required this.gift,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        margin: const EdgeInsets.symmetric(vertical: 80),
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(
          maxWidth: 360,
          maxHeight: 420,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header minimalista
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: CosmicTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart,
                color: Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Acquista regalo',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CosmicTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Come vuoi procedere con "${gift.name}"?',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CosmicTheme.textSecondary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Action buttons
            Column(
              children: [
                // Primary action - Save and go
                PrimaryButton(
                  text: 'Salva e vai al negozio',
                  onPressed: () => Navigator.of(context).pop('save_and_follow'),
                  icon: Icons.bookmark_add,
                  height: 44,
                ),

                const SizedBox(height: 10),

                // Secondary action - Just go
                SecondaryButton(
                  text: 'Vai solo al negozio',
                  onPressed: () => Navigator.of(context).pop('follow_only'),
                  icon: Icons.open_in_new,
                  height: 44,
                  borderColor: CosmicTheme.secondaryAccent,
                  textColor: CosmicTheme.secondaryAccent,
                ),

                const SizedBox(height: 10),

                // Cancel action
                GreyButton(
                  text: 'Rimani qui',
                  onPressed: () => Navigator.of(context).pop('cancel'),
                  height: 44,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Modal per salvare il destinatario - versione cosmica
class SaveRecipientModal extends ConsumerStatefulWidget {
  final String recipientName;
  final int? recipientAge;
  final Map<String, dynamic>? wizardData;
  final Function(Map<String, dynamic>) onSaved;

  const SaveRecipientModal({
    Key? key,
    required this.recipientName,
    this.recipientAge,
    this.wizardData,
    required this.onSaved,
  }) : super(key: key);

  @override
  ConsumerState<SaveRecipientModal> createState() => _SaveRecipientModalState();
}

class _SaveRecipientModalState extends ConsumerState<SaveRecipientModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  final TextEditingController _interestsController = TextEditingController();

  String _selectedGender = 'M';
  String _selectedRelation = 'friend';
  DateTime? _birthDate;
  List<String> _interests = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Stati di validazione per evidenziare errori
  bool _nameError = false;
  bool _genderError = false;
  bool _relationError = false;

  final List<Map<String, String>> _genderOptions = [
    {'value': 'M', 'label': 'Uomo'},
    {'value': 'F', 'label': 'Donna'},
    {'value': 'X', 'label': 'Non binario'},
    {'value': 'O', 'label': 'Altro'},
  ];

  final List<Map<String, String>> _relationOptions = [
    {'value': 'friend', 'label': 'Amico/a'},
    {'value': 'family_member', 'label': 'Familiare'},
    {'value': 'partner', 'label': 'Partner'},
    {'value': 'colleague', 'label': 'Collega'},
    {'value': 'other', 'label': 'Altro'},
  ];

  // Mappa i valori del wizard ai valori del dropdown
  String _mapWizardRelationToDropdownValue(String? wizardRelation) {
    switch (wizardRelation) {
      case 'amico':
      case 'amica':
        return 'friend';
      case 'familiare':
      case 'famiglia':
        return 'family_member';
      case 'partner':
      case 'fidanzato':
      case 'fidanzata':
        return 'partner';
      case 'collega':
        return 'colleague';
      default:
        return 'friend';
    }
  }

  @override
  void initState() {
    super.initState();

    // Se abbiamo i dati del wizard, li usiamo
    if (widget.wizardData != null) {
      final data = widget.wizardData!;
      _nameController = TextEditingController(text: data['name'] ?? widget.recipientName);
      _notesController = TextEditingController(text: data['notes'] ?? '');
      _selectedGender = data['gender'] ?? 'M';
      _selectedRelation = _mapWizardRelationToDropdownValue(data['relation']);
      _interests = List<String>.from(data['interests'] ?? []);

      // Gestisci la data di nascita
      if (data['birthDate'] != null) {
        _birthDate = DateTime.parse(data['birthDate']);
      } else if (widget.recipientAge != null) {
        final now = DateTime.now();
        _birthDate = DateTime(now.year - widget.recipientAge!, now.month, now.day);
      }
    } else {
      // Fallback ai valori predefiniti
      _nameController = TextEditingController(text: widget.recipientName);
      _notesController = TextEditingController();

      if (widget.recipientAge != null) {
        final now = DateTime.now();
        _birthDate = DateTime(now.year - widget.recipientAge!, now.month, now.day);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  void _addInterest([String? submittedText]) {
    final interest = _interestsController.text.trim();
    if (interest.isNotEmpty && !_interests.contains(interest)) {
      setState(() {
        _interests.add(interest);
        _interestsController.clear();
      });
    }
  }

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
    });
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _birthDate = date;
      });
    }
  }

  bool _validateForm() {
    bool isValid = true;
    
    // Reset errori precedenti
    setState(() {
      _nameError = false;
      _genderError = false;
      _relationError = false;
      _errorMessage = null;
    });

    // Valida nome
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = true);
      isValid = false;
    }

    // Valida genere
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      setState(() => _genderError = true);
      isValid = false;
    }

    // Valida relazione
    if (_selectedRelation == null || _selectedRelation!.isEmpty) {
      setState(() => _relationError = true);
      isValid = false;
    }

    if (!isValid) {
      setState(() {
        _errorMessage = 'Compila tutti i campi obbligatori evidenziati in rosso';
      });
    }

    return isValid;
  }

  Future<void> _saveRecipient() async {
    // Valida prima di procedere
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);

      final recipientData = {
        'name': _nameController.text.trim(),
        'gender': _selectedGender,
        'birth_date': _birthDate?.toIso8601String().split('T')[0],
        'relation': _selectedRelation,
        'interests': _interests,
        'notes': _notesController.text.trim(),
      };

      final savedRecipient = await apiService.createRecipient(recipientData);

      widget.onSaved(savedRecipient);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Destinatario salvato con successo!'),
            backgroundColor: CosmicTheme.primaryAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Errore nel salvare il destinatario: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(
          maxWidth: 480,
          maxHeight: 600,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: CosmicTheme.primaryAccent.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: CosmicTheme.primaryAccent.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header compatto
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Crea destinatario',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: CosmicTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Salva per il futuro',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: CosmicTheme.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: CosmicTheme.textSecondary,
                        size: 24,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: CosmicTheme.textSecondary.withOpacity(0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Error Message Display
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              color: Colors.red.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Nome
                TextFormField(
                  controller: _nameController,
                  onChanged: (value) {
                    if (_nameError && value.trim().isNotEmpty) {
                      setState(() => _nameError = false);
                    }
                  },
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nome destinatario *',
                    labelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: _nameError ? Colors.red : CosmicTheme.primaryAccent,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _nameError ? Colors.red : CosmicTheme.primaryAccent.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _nameError ? Colors.red : CosmicTheme.primaryAccent.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _nameError ? Colors.red : CosmicTheme.primaryAccent, 
                        width: 2
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Genere e Relazione
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: CosmicTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Genere *',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: _genderError ? Colors.red : CosmicTheme.secondaryAccent,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _genderError ? Colors.red : CosmicTheme.secondaryAccent.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _genderError ? Colors.red : CosmicTheme.secondaryAccent.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _genderError ? Colors.red : CosmicTheme.secondaryAccent, 
                              width: 2
                            ),
                          ),
                        ),
                        items: _genderOptions.map((option) {
                          return DropdownMenuItem(
                            value: option['value'],
                            child: Text(
                              option['label']!,
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value!;
                            if (_genderError) _genderError = false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRelation,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: CosmicTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Relazione *',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: _relationError ? Colors.red : CosmicTheme.secondaryAccent,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _relationError ? Colors.red : CosmicTheme.secondaryAccent.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _relationError ? Colors.red : CosmicTheme.secondaryAccent.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _relationError ? Colors.red : CosmicTheme.secondaryAccent, 
                              width: 2
                            ),
                          ),
                        ),
                        items: _relationOptions.map((option) {
                          return DropdownMenuItem(
                            value: option['value'],
                            child: Text(
                              option['label']!,
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRelation = value!;
                            if (_relationError) _relationError = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Data di nascita
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data di nascita',
                      labelStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: CosmicTheme.primaryAccent,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: CosmicTheme.primaryAccent.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: CosmicTheme.primaryAccent.withOpacity(0.3)),
                      ),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: CosmicTheme.primaryAccent,
                        size: 18,
                      ),
                    ),
                    child: Text(
                      _birthDate != null
                        ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                        : 'Seleziona data',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _birthDate != null 
                          ? CosmicTheme.textPrimary 
                          : CosmicTheme.textSecondary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Interessi
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _interestsController,
                        decoration: InputDecoration(
                          labelText: 'Aggiungi interesse',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onFieldSubmitted: (_) => _addInterest(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addInterest,
                      icon: Icon(Icons.add, color: CosmicTheme.primaryAccent),
                      style: IconButton.styleFrom(
                        backgroundColor: CosmicTheme.primaryAccent.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),

                if (_interests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _interests.map((interest) {
                      return Chip(
                        label: Text(interest),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeInterest(interest),
                        backgroundColor: CosmicTheme.primaryAccent.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),

                // Note
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Note (opzionale)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                // Pulsanti
                Column(
                  children: [
                    // Pulsante principale
                    PrimaryButton(
                      text: 'Crea destinatario',
                      onPressed: _isLoading ? null : _saveRecipient,
                      isLoading: _isLoading,
                      height: 44,
                    ),

                    const SizedBox(height: 10),

                    // Pulsante secondario
                    GreyButton(
                      text: 'Annulla',
                      onPressed: () => Navigator.of(context).pop(),
                      height: 44,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}