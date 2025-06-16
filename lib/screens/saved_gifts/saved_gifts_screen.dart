
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../models/gift.dart';
import '../../models/recipient.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../theme/app_theme.dart';

class SavedGiftsScreen extends ConsumerStatefulWidget {
  const SavedGiftsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SavedGiftsScreen> createState() => _SavedGiftsScreenState();
}

class _SavedGiftsScreenState extends ConsumerState<SavedGiftsScreen>
    with TickerProviderStateMixin {
  Map<int, List<Gift>> _giftsByRecipient = {};
  Map<int, Recipient> _recipients = {};
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _loadSavedGifts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedGifts() async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = ref.read(apiServiceProvider);
      
      // Load recipients first
      final recipientsData = await apiService.getRecipients();
      final recipients = recipientsData.map((data) => Recipient.fromJson(data)).toList();
      
      // Load saved gifts
      final giftsData = await apiService.getSavedGifts();
      final gifts = giftsData.map((data) => Gift.fromJson(data)).toList();
      
      // Group gifts by recipient
      final giftsByRecipient = <int, List<Gift>>{};
      for (final gift in gifts) {
        if (gift.recipient != null) {
          giftsByRecipient.putIfAbsent(gift.recipient!, () => []).add(gift);
        }
      }
      
      setState(() {
        _recipients = {for (var r in recipients) r.id!: r};
        _giftsByRecipient = giftsByRecipient;
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel caricamento dei regali salvati: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  List<int> _getFilteredRecipientIds() {
    if (_searchQuery.isEmpty) {
      return _giftsByRecipient.keys.toList();
    }
    
    return _giftsByRecipient.keys.where((recipientId) {
      final recipient = _recipients[recipientId];
      final gifts = _giftsByRecipient[recipientId] ?? [];
      
      // Search in recipient name
      if (recipient?.name.toLowerCase().contains(_searchQuery.toLowerCase()) == true) {
        return true;
      }
      
      // Search in gift names and descriptions
      return gifts.any((gift) =>
          gift.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (gift.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (gift.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false));
    }).toList();
  }

  int get _totalGiftsCount {
    return _giftsByRecipient.values.fold(0, (sum, gifts) => sum + gifts.length);
  }

  Future<void> _refreshGifts() async {
    await _loadSavedGifts();
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url == 'None' || url.isEmpty) return;
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deleteGift(Gift gift) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rimuovi Regalo',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: Text(
          'Sei sicuro di voler rimuovere "${gift.name}" dai tuoi regali salvati?',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && gift.id != null) {
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.deleteSavedGift(gift.id!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Regalo rimosso con successo'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        _loadSavedGifts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nella rimozione: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Search bar
              if (!_isLoading && _totalGiftsCount > 0) _buildSearchBar(),
              
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _totalGiftsCount == 0
                        ? _buildEmptyState()
                        : _buildGiftsListByRecipient(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Regali Salvati',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_totalGiftsCount regali per ${_giftsByRecipient.length} ${_giftsByRecipient.length == 1 ? 'destinatario' : 'destinatari'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (_totalGiftsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_totalGiftsCount',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: AppTheme.cardDecoration,
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Cerca nei regali salvati...',
            hintStyle: TextStyle(
              color: AppTheme.textTertiaryColor,
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: AppTheme.textTertiaryColor,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: AppTheme.textTertiaryColor,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Caricamento regali salvati...',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Empty state illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.favorite_outline,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Nessun regalo salvato',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Inizia a generare idee regalo e salva i tuoi preferiti per vederli qui organizzati per destinatario.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Call to action card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.elevatedCardDecoration,
                child: Column(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Genera le Tue Prime Idee Regalo',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Usa la nostra IA per creare suggerimenti personalizzati, poi salva i tuoi preferiti.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/generate-gifts'),
                        icon: const Icon(Icons.auto_awesome, size: 20),
                        label: const Text('Genera Idee Regalo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Widget _buildGiftsListByRecipient() {
    final filteredRecipientIds = _getFilteredRecipientIds();
    
    if (filteredRecipientIds.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: AppTheme.textTertiaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Nessun risultato',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Prova a modificare i termini di ricerca',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshGifts,
          color: AppTheme.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: filteredRecipientIds.length,
            itemBuilder: (context, index) {
              final recipientId = filteredRecipientIds[index];
              final recipient = _recipients[recipientId];
              final gifts = _giftsByRecipient[recipientId] ?? [];
              
              return _buildRecipientSection(recipient!, gifts);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientSection(Recipient recipient, List<Gift> gifts) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipient header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryLight.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      recipient.name.isNotEmpty 
                        ? recipient.name[0].toUpperCase()
                        : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipient.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${gifts.length} ${gifts.length == 1 ? 'regalo salvato' : 'regali salvati'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${gifts.length}',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Gifts list for this recipient
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: gifts.asMap().entries.map((entry) {
                final index = entry.key;
                final gift = entry.value;
                return Column(
                  children: [
                    _buildGiftCard(gift),
                    if (index < gifts.length - 1) const SizedBox(height: 16),
                  ],
                );
              }).toList(),
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
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gift image placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.3),
                      AppTheme.primaryLight.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.card_giftcard,
                  color: AppTheme.primaryColor,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Price and match
                    Row(
                      children: [
                        if (gift.price > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '€${gift.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppTheme.successColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        if (gift.match != null && gift.match! > 0) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.stars,
                                color: AppTheme.warningColor,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${gift.match}%',
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
                  ],
                ),
              ),
              
              // Actions menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: AppTheme.textTertiaryColor,
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 18, color: AppTheme.textPrimaryColor),
                        const SizedBox(width: 8),
                        const Text('Dettagli'),
                      ],
                    ),
                  ),
                  if (gift.amazonLink != null && gift.amazonLink != 'None' && gift.amazonLink!.isNotEmpty)
                    PopupMenuItem(
                      value: 'buy',
                      child: Row(
                        children: [
                          Icon(Icons.shopping_cart, size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Acquista'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: AppTheme.errorColor),
                        const SizedBox(width: 8),
                        Text('Rimuovi', style: TextStyle(color: AppTheme.errorColor)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteGift(gift);
                  } else if (value == 'buy') {
                    _launchUrl(gift.amazonLink);
                  } else if (value == 'view') {
                    _showGiftDetails(gift);
                  }
                },
              ),
            ],
          ),
          
          // Description
          if (gift.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              gift.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          // Category
          if (gift.category?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                gift.category!,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showGiftDetails(Gift gift) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
              
              const SizedBox(height: 12),
              
              // Price and match row
              Row(
                children: [
                  if (gift.price > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '€${gift.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  if (gift.match != null && gift.match! > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 20),
              
              if (gift.description?.isNotEmpty == true) ...[
                Text(
                  'Descrizione',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  gift.description!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 24),
              ],
              
              if (gift.category?.isNotEmpty == true) ...[
                Text(
                  'Categoria',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    gift.category!,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Action buttons
              const Spacer(),
              Column(
                children: [
                  if (gift.amazonLink != null && gift.amazonLink != 'None' && gift.amazonLink!.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _launchUrl(gift.amazonLink);
                        },
                        icon: const Icon(Icons.shopping_cart, size: 20),
                        label: const Text('Acquista su Amazon'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteGift(gift);
                      },
                      icon: const Icon(Icons.delete, size: 20),
                      label: const Text('Rimuovi dai Salvati'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(color: AppTheme.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
    );
  }
}
