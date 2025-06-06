
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/gift.dart';
import '../../models/recipient.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

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

    // Debug print per controllare il parametro
    print('GiftResultsScreen - existingRecipient: ${widget.existingRecipient}');
    print('GiftResultsScreen - _recipientSaved: $_recipientSaved');
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
            backgroundColor: AppTheme.primaryColor,
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
    if (url == null || url == 'None') return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.home, color: AppTheme.textPrimaryColor),
          onPressed: () => context.go('/home'),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        title: Text(
          'Idee Regalo',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Save Recipient Banner (solo se non viene da destinatario esistente)
              if (widget.existingRecipient == null && !_recipientSaved) _buildSaveRecipientBanner(),

              // Recipient info section
              _buildRecipientInfoSection(),

              // Gift Ideas section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.card_giftcard,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Idee Regalo Personalizzate',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
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
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentColor.withOpacity(0.3),
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
            AppTheme.accentColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bookmark_add,
              color: AppTheme.accentColor,
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
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Potrai generare nuove idee regalo più facilmente in futuro',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _showSaveRecipientModal,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
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
            AppTheme.accentColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
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
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_recipientSaved || widget.existingRecipient != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.accentColor.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark,
                              color: AppTheme.accentColor,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Salvato',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.accentColor,
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
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                if (displayAge != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$displayAge anni',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppTheme.textSecondaryColor,
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
            AppTheme.surfaceColor,
            AppTheme.surfaceColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
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
                  gift.category != null && gift.category!.isNotEmpty
                      ? Image.asset(
                          'assets/images/categories/${gift.category!.toLowerCase().replaceAll(' ', '_')}.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 160,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/categories/placeholder.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 160,
                              errorBuilder: (context, error2, stackTrace2) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
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
                        )
                      : Image.asset(
                          'assets/images/categories/placeholder.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 160,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
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
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Compatibilità: ${gift.match}%',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Price and actions row
                Row(
                  children: [
                    // Prezzo con gradient primary
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '€${gift.price?.toStringAsFixed(0) ?? '0'}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Bottone salva
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.borderColor,
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: _isLoading ? null : () => _saveGift(gift),
                        icon: Icon(
                          _isLoading 
                            ? Icons.hourglass_empty 
                            : Icons.favorite_border,
                          color: _isLoading 
                            ? AppTheme.textTertiaryColor 
                            : AppTheme.primaryColor,
                          size: 20,
                        ),
                        tooltip: 'Salva regalo',
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Bottone acquisto - stesso livello
                    if (gift.amazonLink != null && gift.amazonLink != 'None')
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.accentColor.withOpacity(0.3),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton.icon(
                            onPressed: () => _showPurchaseDisclaimer(gift),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(
                              Icons.open_in_new,
                              size: 16,
                              color: AppTheme.accentColor,
                            ),
                            label: Text(
                              'Vedi prodotto',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.accentColor,
                              ),
                            ),
                          ),
                        ),
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
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.favorite,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Salva il regalo',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Per salvare "${gift.name}" e associarlo al destinatario, devi prima creare il destinatario.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Salvare i regali per un destinatario aiuterà l\'AI a trovare regali ancora più personalizzati in futuro!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onCreateRecipient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.person_add),
                    label: Text(
                      'Crea destinatario e salva regalo',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Non ora',
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
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.open_in_new,
                color: Colors.orange,
                size: 32,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Stai per uscire dall\'app',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Sarai reindirizzato al negozio online per acquistare "${gift.name}". Cosa vuoi fare?',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Action buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop('save_and_follow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.bookmark_add),
                    label: Text(
                      'Salva regalo e vai al negozio',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop('follow_only'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(
                      'Vai solo al negozio',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop('cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Annulla e rimani nell\'app',
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

// Modal per salvare il destinatario
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
            backgroundColor: AppTheme.primaryColor,
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
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_add,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Salva Destinatario',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Nome
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Il nome è obbligatorio';
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
                        decoration: InputDecoration(
                          labelText: 'Genere',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _genderOptions.map((option) {
                          return DropdownMenuItem(
                            value: option['value'],
                            child: Text(option['label']!),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedGender = value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRelation,
                        decoration: InputDecoration(
                          labelText: 'Relazione',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _relationOptions.map((option) {
                          return DropdownMenuItem(
                            value: option['value'],
                            child: Text(option['label']!),
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
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data di nascita',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _birthDate != null
                        ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                        : 'Seleziona data',
                      style: TextStyle(
                        color: _birthDate != null 
                          ? AppTheme.textPrimaryColor 
                          : AppTheme.textSecondaryColor,
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
                      icon: Icon(Icons.add, color: AppTheme.primaryColor),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
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
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
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

                const SizedBox(height: 24),

                // Pulsanti
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Annulla',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveRecipient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                              'Salva',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
