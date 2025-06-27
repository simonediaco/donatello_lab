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
import '../../widgets/gift_disclaimers.dart';

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
      builder: (context) => SaveGiftDisclaimerModal(
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
      builder: (context) => PurchaseDisclaimerModal(gift: gift),
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
      builder: (context) => SaveRecipientModal(
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
                        // Se ci sono più categorie separate da virgola o pipe, prendi la prima
                        String categoryForImage = gift.category!
                            .split(RegExp('[,|]'))[0]
                            .trim()
                            .toLowerCase()
                            .replaceAll(RegExp(r'[^a-z0-9]'), '_') // Sostituisce caratteri speciali con underscore
                            .replaceAll(RegExp(r'_+'), '_') // Rimuove underscore multipli
                            .replaceAll(RegExp(r'^_|_$'), ''); // Rimuove underscore all'inizio e alla fine
                        
                        imagePath = 'assets/images/categories/$categoryForImage.png';
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