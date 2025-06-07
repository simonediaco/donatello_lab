import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/recipient.dart';
import '../../models/gift.dart';
import '../../services/api_service.dart';
import '../../theme/cosmic_theme.dart';

class RecipientDetailScreen extends ConsumerStatefulWidget {
  final int recipientId;

  const RecipientDetailScreen({Key? key, required this.recipientId}) : super(key: key);

  @override
  ConsumerState<RecipientDetailScreen> createState() => _RecipientDetailScreenState();
}

class _RecipientDetailScreenState extends ConsumerState<RecipientDetailScreen>
    with TickerProviderStateMixin {
  Recipient? _recipient;
  List<Gift> _gifts = [];
  bool _isLoading = true;
  bool _isEditMode = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

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
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);

      // Load recipient
      final recipientData = await apiService.getRecipient(widget.recipientId);
      final recipient = Recipient.fromJson(recipientData);

      // Load gifts for this recipient
      final giftsData = await apiService.getSavedGifts();
      final allGifts = giftsData.map((data) => Gift.fromJson(data)).toList();
      final recipientGifts = allGifts.where((gift) => gift.recipient == widget.recipientId).toList();

      setState(() {
        _recipient = recipient;
        _gifts = recipientGifts;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore nel caricamento dei dati';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRecipient() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Elimina Destinatario',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CosmicTheme.textPrimary,
          ),
        ),
        content: Text(
          'Sei sicuro di voler eliminare ${_recipient?.name}? Questa azione non può essere annullata.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: CosmicTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Annulla',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CosmicTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Elimina',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CosmicTheme.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.deleteRecipient(widget.recipientId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Destinatario eliminato con successo',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              backgroundColor: CosmicTheme.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          context.pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Errore nell\'eliminazione: ${e.toString()}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              backgroundColor: CosmicTheme.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url == 'None' || url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  int? _calculateAge(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return null;

    try {
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: CosmicTheme.cosmicGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? _buildLoadingState()
                      : _errorMessage != null
                          ? _buildErrorState()
                          : _recipient == null
                              ? _buildNotFoundState()
                              : _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(
              Icons.arrow_back,
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
                  _recipient?.name ?? 'Caricamento...',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _recipient?.relation ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_recipient != null) ...[
            GestureDetector(
              onTap: () async {
                final result = await context.push('/recipients/${_recipient!.id}/edit');
                if (result == true) {
                  _loadData();
                }
              },
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: _deleteRecipient,
              child: Icon(
                Icons.delete,
                color: CosmicTheme.red,
                size: 24,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: CosmicTheme.primaryAccent),
          SizedBox(height: 16),
          Text('Caricamento destinatario...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: CosmicTheme.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: CosmicTheme.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Errore di caricamento',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: CosmicTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Errore sconosciuto',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: CosmicTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: CosmicTheme.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.person_off,
                size: 40,
                color: CosmicTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Destinatario non trovato',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: CosmicTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final age = _calculateAge(_recipient!.birthDate);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: CosmicTheme.buttonGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CosmicTheme.primaryAccent.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _recipient!.name.isNotEmpty ? _recipient!.name[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Basic Info Section
              _buildSection(
                'Informazioni',
                Icons.person_outline,
                [
                  _buildInfoRow('Nome', _recipient!.name),
                  _buildInfoRow('Relazione', _recipient!.relation),
                  if (_recipient!.gender != null)
                    _buildInfoRow('Genere', _getGenderLabel(_recipient!.gender!)),
                  if (age != null)
                    _buildInfoRow('Età', '$age anni'),
                  if (_recipient!.birthDate?.isNotEmpty == true)
                    _buildInfoRow('Data di nascita', _formatDate(_recipient!.birthDate!)),
                ],
              ),

              const SizedBox(height: 24),

              // Notes Section
              if (_recipient!.notes?.isNotEmpty == true) ...[
                _buildSection(
                  'Note',
                  Icons.note_alt_outlined,
                  [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        _recipient!.notes!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: CosmicTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Interests Section
              if (_recipient!.interests?.isNotEmpty == true) ...[
                _buildSection(
                  'Interessi',
                  Icons.favorite_outline,
                  [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_recipient!.interests ?? []).map((interest) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: CosmicTheme.primaryAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: CosmicTheme.primaryAccent.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            interest,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: CosmicTheme.primaryAccent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Dislikes Section
              if (_recipient!.dislikes?.isNotEmpty == true) ...[
                _buildSection(
                  'Non gradisce',
                  Icons.thumb_down_outlined,
                  [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (_recipient!.dislikes ?? []).map((dislike) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: CosmicTheme.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: CosmicTheme.red.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            dislike,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: CosmicTheme.red,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Saved Gifts Section
              _buildSection(
                'Regali Salvati (${_gifts.length})',
                Icons.card_giftcard_outlined,
                [
                  if (_gifts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: CosmicTheme.primaryAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Icon(
                              Icons.card_giftcard_outlined,
                              size: 40,
                              color: CosmicTheme.primaryAccent,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nessun regalo salvato',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: CosmicTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Genera idee regalo personalizzate per questo destinatario',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: CosmicTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              gradient: CosmicTheme.buttonGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: CosmicTheme.lightShadow,
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.auto_awesome, color: Colors.white),
                              label: Text(
                                'Genera Regali',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed: () => context.push('/gift-generation'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        ...List.generate(_gifts.length, (index) {
                          final gift = _gifts[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: index < _gifts.length - 1 ? 16 : 0),
                            child: _buildGiftCard(gift),
                          );
                        }),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: CosmicTheme.buttonGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: CosmicTheme.lightShadow,
                          ),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.auto_awesome, color: Colors.white),
                            label: Text(
                              'Genera Altri Regali',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () => context.push('/gift-generation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CosmicTheme.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: CosmicTheme.primaryAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CosmicTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CosmicTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CosmicTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftCard(Gift gift) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gift icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CosmicTheme.primaryAccent.withOpacity(0.3),
                      CosmicTheme.primaryAccent.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.card_giftcard,
                  color: CosmicTheme.primaryAccent,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // Gift info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gift.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CosmicTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Price and match
                    Row(
                      children: [
                        if (gift.price > 0) ...[
                          Text(
                            '€${gift.price.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        if (gift.match != null && gift.match! > 0) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.stars,
                                color: CosmicTheme.yellow,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${gift.match}%',
                                style: GoogleFonts.inter(
                                  color: CosmicTheme.yellow,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              if (gift.amazonLink != null && gift.amazonLink != 'None' && gift.amazonLink!.isNotEmpty)
                IconButton(
                  onPressed: () => _launchUrl(gift.amazonLink),
                  icon: Icon(
                    Icons.shopping_cart,
                    color: CosmicTheme.yellow,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          // Description
          if (gift.description?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              gift.description!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CosmicTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _getGenderLabel(String gender) {
    switch (gender) {
      case 'M': return 'Uomo';
      case 'F': return 'Donna';
      case 'X': return 'Non-binario';
      case 'T': return 'Transgender';
      case 'O': return 'Altro';
      default: return gender;
    }
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }
}