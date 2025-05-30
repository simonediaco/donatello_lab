
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/gift.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class GiftResultsScreen extends ConsumerStatefulWidget {
  final String recipientName;
  final int? recipientAge;
  final List<dynamic> gifts;

  const GiftResultsScreen({
    Key? key,
    required this.recipientName,
    this.recipientAge,
    required this.gifts,
  }) : super(key: key);

  @override
  ConsumerState<GiftResultsScreen> createState() => _GiftResultsScreenState();
}

class _GiftResultsScreenState extends ConsumerState<GiftResultsScreen> {
  late List<Gift> _allGifts;
  List<Gift> _displayedGifts = [];
  bool _showingMore = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _allGifts = widget.gifts.map((g) => Gift.fromJson(g)).toList();
    // Mostra solo i primi 4 regali
    _displayedGifts = _allGifts.take(4).toList();
  }

  Future<void> _saveGift(Gift gift) async {
    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.saveGift(gift.toJson());
      
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
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'Gift Ideas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Save Recipient section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Save Recipient',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.recipientName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.recipientAge != null)
                    Text(
                      '${widget.recipientAge} years old',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                ],
              ),
            ),
            
            // Gift Ideas section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Gift Ideas',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showingMore ? _showLess : _loadMore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _showingMore ? 'Show Less' : 'Load More',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernGiftCard(Gift gift) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Gift info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gift.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gift.category ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '€${gift.price?.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isLoading ? null : () => _saveGift(gift),
                        icon: Icon(
                          Icons.bookmark_border,
                          color: _isLoading ? Colors.grey : Colors.white,
                        ),
                      ),
                      if (gift.amazonLink != null && gift.amazonLink != 'None')
                        IconButton(
                          onPressed: () => _launchUrl(gift.amazonLink),
                          icon: const Icon(
                            Icons.shopping_cart,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Gift image
          Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: AppTheme.primaryColor,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
