import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/gift.dart';
import '../../services/api_service.dart';
import '../../widgets/gift_card.dart';
import '../../theme/app_theme.dart';

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
  late List<Gift> _gifts;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gifts = widget.gifts.map((g) => Gift.fromJson(g)).toList();
  }

  Future<void> _saveGift(Gift gift) async {
    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.saveGift(gift.toJson());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Regalo salvato con successo!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    // TODO: Implement load more functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caricamento di altre idee...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Gift Ideas'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Save Recipient section
          Container(
            padding: const EdgeInsets.all(24),
            color: AppTheme.cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Save Recipient',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.subtitleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.recipientName,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                if (widget.recipientAge != null)
                  Text(
                    '${widget.recipientAge} years old',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.subtitleColor,
                        ),
                  ),
              ],
            ),
          ),
          
          // Gift Ideas section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Gift Ideas',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ),
          
          // Gift list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _gifts.length,
              itemBuilder: (context, index) {
                final gift = _gifts[index];
                return GiftCard(
                  gift: gift,
                  onSave: _isLoading ? null : () => _saveGift(gift),
                );
              },
            ),
          ),
          
          // Load More button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadMore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Load More',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}