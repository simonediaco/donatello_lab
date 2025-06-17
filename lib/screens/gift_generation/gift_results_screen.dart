import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/gift.dart';
import '../../models/recipient.dart';
import '../../services/api_service.dart';
import '../../services/search_history_service.dart';
import '../../services/affiliate_service.dart';
import '../../services/navigation_service.dart';
import '../../theme/cosmic_theme.dart';

class GiftResultsScreen extends ConsumerStatefulWidget {
  final String recipientName;
  final int? recipientAge;
  final List<dynamic> gifts;
  final Recipient? existingRecipient; // Nuovo parametro per destinatario esistente
  final Map<String, dynamic>? wizardData; // Dati del wizard per salvare il destinatario

  const GiftResultsScreen({
    Key? key,
    required this.recipientName,
    this.recipientAge,
    required this.gifts,
    this.existingRecipient,
    this.wizardData,
  }) : super(key: key);

  @override
  ConsumerState<GiftResultsScreen> createState() => _GiftResultsScreenState();
}

class _GiftResultsScreenState extends ConsumerState<GiftResultsScreen> {
  late List<Gift> _allGifts;
  List<Gift> _displayedGifts = [];
  bool _showingMore = false;
  bool _isLoading = false;
  bool _recipientSaved = false;
  Gift? _pendingGiftToSave;
  int? _savedRecipientId;
  Map<String, dynamic>? _savedRecipientData;

  @override
  void initState() {
    super.initState();
    _allGifts = widget.gifts.map((g) => Gift.fromJson(g)).toList();
    _displayedGifts = _allGifts.take(4).toList();
    // Se abbiamo un destinatario esistente, significa che è già salvato
    _recipientSaved = widget.existingRecipient != null;

    // Salva questa ricerca come ultima ricerca
    _saveCurrentSearch();

    // Debug print per controllare il parametro
    //print('GiftResultsScreen - existingRecipient: ${widget.existingRecipient}');
    //print('GiftResultsScreen - _recipientSaved: $_recipientSaved');
  }

  Future<void> _saveCurrentSearch() async {
    try {
      await SearchHistoryService.saveLastSearch(
        recipientName: widget.recipientName,
        recipientAge: widget.recipientAge,
        gifts: widget.gifts,
        existingRecipientId: widget.existingRecipient?.id,
        wizardData: widget.wizardData,
      );
    } catch (e) {
      print('Errore nel salvare l\'ultima ricerca: $e');
    }
  }

  Future<void> _saveGift(Gift gift) async {
    // Se non abbiamo un destinatario esistente e non ne abbiamo ancora salvato uno, mostra il disclaimer
    if (widget.existingRecipient == null && !_recipientSaved) {
      _showSaveGiftDisclaimer(gift);
      return;
    }

    // Se abbiamo un destinatario esistente, salva direttamente
    if (widget.existingRecipient != null) {
      await _performSaveGift(gift, widget.existingRecipient!.id);
    } else {
      // Se il destinatario è stato salvato durante questa sessione, usa il suo ID
      if (_savedRecipientId != null) {
        await _performSaveGift(gift, _savedRecipientId);
      }
    }
  }

  void _showSaveGiftDisclaimer(Gift gift) {
    showDialog(
      context: context,
      builder: (context) => _SaveGiftDisclaimerModal(
        gift: gift,
        onCreateRecipient: () {
          Navigator.of(context).pop();
          setState(() => _pendingGiftToSave = gift);
          _showSaveRecipientModal();
        },
      ),
    );
  }

  Future<void> _performSaveGift(Gift gift, int? recipientId) async {
    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);

      final giftData = gift.toJson();
      if (recipientId != null) {
        giftData['recipient'] = recipientId;
      }

      await apiService.saveGift(giftData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Regalo salvato con successo!'),
            backgroundColor: CosmicTheme.primaryAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadMore() {
    setState(() {
      _showingMore = true;
      _displayedGifts = _allGifts;
    });
  }

  void _showLess() {
    setState(() {
      _showingMore = false;
      _displayedGifts = _allGifts.take(4).toList();
    });
  }

  Future<void> _showPurchaseDisclaimer(Gift gift) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _PurchaseDisclaimerModal(gift: gift),
    );

    if (result == 'save_and_follow') {
      await _saveGift(gift);
      await _launchUrl(gift.amazonLink);
    } else if (result == 'follow_only') {
      await _launchUrl(gift.amazonLink);
    }
    // Se result è 'cancel' o null, non facciamo nulla
  }

  void _showSaveRecipientModal() {
    showDialog(
      context: context,
      builder: (context) => _SaveRecipientModal(
        recipientName: widget.recipientName,
        recipientAge: widget.recipientAge,
        wizardData: widget.wizardData,
        onSaved: (savedRecipient) {
          setState(() {
            _recipientSaved = true;
            _savedRecipientId = savedRecipient['id'];
            _savedRecipientData = savedRecipient;
          });
          // Se abbiamo un regalo pendente da salvare, ora possiamo salvarlo
          if (_pendingGiftToSave != null) {
            _performSaveGift(_pendingGiftToSave!, savedRecipient['id']);
            _pendingGiftToSave = null;
          }
        },
      ),
    );
  }

  Future<void> _launchUrl(String? url) async {
    if (!AffiliateService.isValidUrl(url)) return;

    await AffiliateService.openAffiliateLink(
      context: context,
      url: url!,
      title: 'Prodotto Affiliato',
    );
  }

  @override
  Widget build(BuildContext context) {
    bool _allGiftsSaved = false;

    return Scaffold(
      backgroundColor: CosmicTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.rocket_launch, color: CosmicTheme.primaryAccent, size: 24),
          onPressed: () {
            // Usa il context locale invece del NavigationService
            context.go('/home');
          },
        ),
        title: Text(
          'Idee Regalo',
          style: GoogleFonts.inter(
            color: CosmicTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Elegant cosmic header - centered and balanced
            Container(
              decoration: const BoxDecoration(
                gradient: CosmicTheme.cosmicGradient,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Main title with subtle cosmic glow
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Text(
                              'Regali per ${widget.recipientName}',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: CosmicTheme.primaryAccent.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (widget.recipientAge != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${widget.recipientAge} anni',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Save recipient button if not saved - centered
                      if (widget.existingRecipient == null && !_recipientSaved) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _showSaveRecipientModal,
                              icon: const Icon(Icons.bookmark_add, color: Colors.white, size: 20),
                              label: Text(
                                'Salva destinatario',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

              // White background section for gifts
            // White background section for gifts
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Gift Ideas section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: CosmicTheme.primaryAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.card_giftcard,
                            color: CosmicTheme.primaryAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Idee Regalo Personalizzate',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: CosmicTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Gift list
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: _displayedGifts.map((gift) => 
                        _buildModernGiftCard(gift)
                      ).toList(),
                    ),
                  ),

                  // Load More/Show Less button
                  if (_allGifts.length > 4)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: CosmicTheme.buttonGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: CosmicTheme.primaryAccent.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _showingMore ? _showLess : _loadMore,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _showingMore ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _showingMore 
                                    ? 'Mostra meno regali' 
                                    : 'Carica altri regali (${_allGifts.length - 4})',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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

  Widget _buildCosmicSaveRecipientBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bookmark_add,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salva questo destinatario',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Potrai generare nuove idee regalo più facilmente in futuro',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _showSaveRecipientModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: CosmicTheme.primaryAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Salva',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveRecipientBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CosmicTheme.primaryAccent.withOpacity(0.1),
            CosmicTheme.primaryAccent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CosmicTheme.primaryAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CosmicTheme.primaryAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bookmark_add,
              color: CosmicTheme.primaryAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Salva questo destinatario',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CosmicTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Potrai generare nuove idee regalo più facilmente in futuro',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: CosmicTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _showSaveRecipientModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: CosmicTheme.primaryAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Salva',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCosmicRecipientInfoSection() {
    // Determina quale nome mostrare
    String displayName = widget.recipientName;
    int? displayAge = widget.recipientAge;

    // Se abbiamo salvato un destinatario, usa i suoi dati
    if (_recipientSaved && _savedRecipientData != null) {
      displayName = _savedRecipientData!['name'] ?? widget.recipientName;
      // Calcola l'età dalla data di nascita se disponibile
      if (_savedRecipientData!['birth_date'] != null) {
        try {
          final birthDate = DateTime.parse(_savedRecipientData!['birth_date']);
          final now = DateTime.now();
          displayAge = now.year - birthDate.year;
          if (now.month < birthDate.month || 
              (now.month == birthDate.month && now.day < birthDate.day)) {
            displayAge = displayAge! - 1;
          }
        } catch (e) {
          // Se c'è un errore nel parsing, mantieni l'età originale
        }
      }
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(24, widget.existingRecipient == null && !_recipientSaved ? 0 : 24, 24, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty 
                  ? displayName[0].toUpperCase() 
                  : '?',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CosmicTheme.primaryAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Idee regalo per',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_recipientSaved || widget.existingRecipient != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Salvato',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  displayName.isNotEmpty 
                    ? displayName 
                    : 'Destinatario',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (displayAge != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$displayAge anni',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientInfoSection() {
    // Determina quale nome mostrare
    String displayName = widget.recipientName;
    int? displayAge = widget.recipientAge;

    // Se abbiamo salvato un destinatario, usa i suoi dati
    if (_recipientSaved && _savedRecipientData != null) {
      displayName = _savedRecipientData!['name'] ?? widget.recipientName;
      // Calcola l'età dalla data di nascita se disponibile
      if (_savedRecipientData!['birth_date'] != null) {
        try {
          final birthDate = DateTime.parse(_savedRecipientData!['birth_date']);
          final now = DateTime.now();
          displayAge = now.year - birthDate.year;
          if (now.month < birthDate.month || 
              (now.month == birthDate.month && now.day < birthDate.day)) {
            displayAge = displayAge! - 1;
          }
        } catch (e) {
          // Se c'è un errore nel parsing, mantieni l'età originale
        }
      }
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(24, widget.existingRecipient == null && !_recipientSaved ? 0 : 24, 24, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CosmicTheme.primaryAccent.withOpacity(0.1),
            CosmicTheme.primaryAccent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CosmicTheme.primaryAccent.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: CosmicTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: CosmicTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CosmicTheme.primaryAccent.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty 
                  ? displayName[0].toUpperCase() 
                  : '?',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Idee regalo per',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CosmicTheme.primaryAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_recipientSaved || widget.existingRecipient != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: CosmicTheme.primaryAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: CosmicTheme.primaryAccent.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark,
                              color: CosmicTheme.primaryAccent,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Salvato',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: CosmicTheme.primaryAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  displayName.isNotEmpty 
                    ? displayName 
                    : 'Destinatario',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: CosmicTheme.textPrimary,
                  ),
                ),
                if (displayAge != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$displayAge anni',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: CosmicTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernGiftCard(Gift gift) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CosmicTheme.surfaceColor,
            CosmicTheme.surfaceColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CosmicTheme.secondaryAccent,
          width: 1,
        ),
        boxShadow: CosmicTheme.softShadow,
      ),
      child: Column(
        children: [
          // Header con immagine full-width
          Container(
            height: 160,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  // Immagine di sfondo
                  Builder(
                    builder: (context) {
                      // Determina quale immagine usare
                      String imagePath;
                      if (gift.category != null && gift.category!.isNotEmpty) {
                        imagePath = 'assets/images/categories/${gift.category!.toLowerCase().replaceAll(' ', '_')}.png';
                        //print(imagePath); // Debug: stampa il percorso dell'immagine
                      } else {
                        imagePath = 'assets/images/categories/placeholder.png';
                      }

                      return Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 160,
                        errorBuilder: (context, error, stackTrace) {
                          // Se l'immagine della categoria non esiste, prova con placeholder
                          return Image.asset(
                            'assets/images/categories/placeholder.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 160,
                            errorBuilder: (context, error2, stackTrace2) {
                              // Se anche placeholder non esiste, mostra un container con gradient
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: CosmicTheme.primaryGradient,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.card_giftcard,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),

                  // Overlay gradient per leggibilità
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),

                  // Testo sovrapposto
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (gift.category != null && gift.category!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              gift.category!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          gift.name,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content area
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Match info
                if (gift.match != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: CosmicTheme.primaryAccent,
                        size: 16,
                      ),                      const SizedBox(width: 6),
                      Text(
                        'Compatibilità: ${gift.match}%',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CosmicTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Price and actions row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Prezzo con spazio limitato
                    Expanded(
                      flex: 2,
                      child: Text(
                        '€${gift.price?.toStringAsFixed(0) ?? '0'}',
                        style: GoogleFonts.inter(
                          color: CosmicTheme.primaryAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),

                    // Pulsanti allineati a destra
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bottone salva con cuore rosso pulito
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: _isLoading ? null : () => _saveGift(gift),
                            icon: Icon(
                              _isLoading 
                                ? Icons.hourglass_empty 
                                : Icons.favorite_border,
                              color: Colors.red.shade600,
                              size: 20,
                            ),
                            tooltip: 'Salva regalo',
                            padding: EdgeInsets.zero,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Bottone acquisto con icona gialla pulita
                        if (gift.amazonLink != null && gift.amazonLink != 'None')
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () => _launchUrl(gift.amazonLink),
                              icon: const Icon(
                                Icons.open_in_new,
                                color: Color(0xFFF59E0B),
                                size: 20,
                              ),
                              tooltip: 'Vai al prodotto',
                              padding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Modal per il disclaimer di salvataggio regalo
class _SaveGiftDisclaimerModal extends StatelessWidget {
  final Gift gift;
  final VoidCallback onCreateRecipient;

  const _SaveGiftDisclaimerModal({
    required this.gift,
    required this.onCreateRecipient,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.all(40),
        constraints: const BoxConstraints(
          maxWidth: 520,
          maxHeight: 680,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: CosmicTheme.primaryAccent.withOpacity(0.4),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: CosmicTheme.primaryAccent.withOpacity(0.3),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header cosmico più grande
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: CosmicTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CosmicTheme.primaryAccent.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 48,
              ),
            ),

            const SizedBox(height: 32),

            // Titolo più grande e chiaro
            Text(
              'Crea il tuo destinatario',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: CosmicTheme.textPrimary,
                letterSpacing: -1,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              'nel cosmo di Donatello',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: CosmicTheme.primaryAccent,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Messaggio principale più chiaro
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CosmicTheme.primaryAccent.withOpacity(0.08),
                    CosmicTheme.primaryAccent.withOpacity(0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: CosmicTheme.primaryAccent.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Per salvare',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: CosmicTheme.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: CosmicTheme.primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CosmicTheme.primaryAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '"${gift.name}"',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CosmicTheme.primaryAccent,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'devi prima creare il destinatario nel tuo universo personale.',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: CosmicTheme.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Benefit box più visibile
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CosmicTheme.secondaryAccent.withOpacity(0.15),
                    CosmicTheme.secondaryAccent.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: CosmicTheme.secondaryAccent.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: CosmicTheme.accentGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.stars,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Ogni regalo salvato rende le future scoperte più magiche e personalizzate!',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: CosmicTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // Action buttons più grandi
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: CosmicTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: CosmicTheme.primaryAccent.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: onCreateRecipient,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 24),
                      label: Text(
                        'Crea destinatario cosmico',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: CosmicTheme.textSecondary,
                      backgroundColor: CosmicTheme.textSecondary.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Forse più tardi',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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
class _PurchaseDisclaimerModal extends StatelessWidget {
  final Gift gift;

  const _PurchaseDisclaimerModal({required this.gift});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        margin: const EdgeInsets.symmetric(vertical: 80),
        padding: const EdgeInsets.all(28),
        constraints: const BoxConstraints(
          maxWidth: 420,
          maxHeight: 480,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with cosmic styling
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.9),
                    Colors.deepOrange.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.rocket_launch,
                color: Colors.white,
                size: 32,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Viaggio nel cosmo',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: CosmicTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Stai per acquistare "${gift.name}". Come vuoi procedere?',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: CosmicTheme.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Action buttons
            Column(
              children: [
                // Primary action - Save and go
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: CosmicTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: CosmicTheme.primaryAccent.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop('save_and_follow'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.bookmark_add, size: 18),
                      label: Text(
                        'Salva e vai al negozio',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Secondary action - Just go (orange gradient)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: CosmicTheme.accentGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: CosmicTheme.secondaryAccent.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop('follow_only'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(
                        'Vai solo al negozio',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Cancel action
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop('cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CosmicTheme.textSecondary,
                      side: BorderSide(
                        color: CosmicTheme.textSecondary.withOpacity(0.3),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Rimani qui',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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
class _SaveRecipientModal extends ConsumerStatefulWidget {
  final String recipientName;
  final int? recipientAge;
  final Map<String, dynamic>? wizardData;
  final Function(Map<String, dynamic>) onSaved;

  const _SaveRecipientModal({
    required this.recipientName,
    this.recipientAge,
    this.wizardData,
    required this.onSaved,
  });

  @override
  ConsumerState<_SaveRecipientModal> createState() => _SaveRecipientModalState();
}

class _SaveRecipientModalState extends ConsumerState<_SaveRecipientModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  final TextEditingController _interestsController = TextEditingController();

  String _selectedGender = 'M';
  String _selectedRelation = 'friend';
  DateTime? _birthDate;
  List<String> _interests = [];
  bool _isLoading = false;

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

  Future<void> _saveRecipient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvare il destinatario: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
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

                // Nome
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nome destinatario',
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: CosmicTheme.primaryAccent, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome obbligatorio';
                    }
                    return null;
                  },
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
                          labelText: 'Genere',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: CosmicTheme.secondaryAccent,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: CosmicTheme.secondaryAccent.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: CosmicTheme.secondaryAccent.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: CosmicTheme.secondaryAccent, width: 2),
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
                        onChanged: (value) => setState(() => _selectedGender = value!),
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
                          labelText: 'Relazione',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: CosmicTheme.secondaryAccent,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: CosmicTheme.secondaryAccent.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: CosmicTheme.secondaryAccent.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: CosmicTheme.secondaryAccent, width: 2),
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
                        onChanged: (value) => setState(() => _selectedRelation = value!),
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
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: CosmicTheme.buttonGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: CosmicTheme.primaryAccent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveRecipient,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Crea destinatario',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Pulsante secondario
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: CosmicTheme.textSecondary,
                          backgroundColor: CosmicTheme.textSecondary.withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Annulla',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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