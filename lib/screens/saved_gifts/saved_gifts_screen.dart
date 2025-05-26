import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/gift.dart';
import '../../models/recipient.dart';
import '../../theme/app_theme.dart';

class SavedGiftsScreen extends ConsumerStatefulWidget {
  const SavedGiftsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SavedGiftsScreen> createState() => _SavedGiftsScreenState();
}

class _SavedGiftsScreenState extends ConsumerState<SavedGiftsScreen> {
  Map<int, List<Gift>> _giftsByRecipient = {};
  Map<int, Recipient> _recipients = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedGifts();
  }

  Future<void> _loadSavedGifts() async {
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
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Saved Gifts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _giftsByRecipient.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 80,
                        color: AppTheme.subtitleColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nessun regalo salvato',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'I regali salvati appariranno qui',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.subtitleColor,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _giftsByRecipient.length,
                  itemBuilder: (context, index) {
                    final recipientId = _giftsByRecipient.keys.elementAt(index);
                    final recipient = _recipients[recipientId];
                    final gifts = _giftsByRecipient[recipientId]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (recipient != null) ...[
                          Text(
                            'For ${recipient.name}',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 16),
                        ],
                        ...gifts.map((gift) => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              // Gift image placeholder
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.card_giftcard,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                              // Gift details
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        gift.name,
                                        style: Theme.of(context).textTheme.displaySmall,
                                      ),
                                      if (gift.description != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          gift.description!,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: AppTheme.subtitleColor,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Text(
                                        '€${gift.price.toStringAsFixed(0)}',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/recipients');
              break;
            case 2:
              // Already on saved gifts
              break;
            case 3:
              context.go('/generate');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.backgroundColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.subtitleColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Homepage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Recipients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Saved Gifts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Generate',
          ),
        ],
      ),
    );
  }
}