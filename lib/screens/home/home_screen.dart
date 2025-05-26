import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/recipient_avatar.dart';
import '../../models/recipient.dart';
import '../../models/gift.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  List<Recipient> _recipients = [];
  List<Gift> _popularGifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final recipientsData = await apiService.getRecipients();
      
      setState(() {
        _recipients = recipientsData
            .map((data) => Recipient.fromJson(data))
            .toList()
            .take(3)
            .toList();
        
        // Mock popular gifts
        _popularGifts = [
          const Gift(
            name: 'Personalized Portrait',
            price: 120,
            description: 'A custom portrait inspired by Renaissance art',
            image: 'assets/images/gift_portrait.jpg',
          ),
          const Gift(
            name: 'Custom Jewelry',
            price: 85,
            description: 'Handcrafted jewelry with personal touch',
            image: 'assets/images/gift_jewelry.jpg',
          ),
        ];
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        context.push('/recipients');
        break;
      case 2:
        context.push('/saved-gifts');
        break;
      case 3:
        context.push('/generate');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Donatello Lab',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      // TODO: Implement notifications
                    },
                  ),
                ],
              ),
            ),
            
            // Hero section
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage('assets/images/renaissance_hero.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    child: Text(
                      'Ciao, ${user?.firstName ?? "Artista"}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Generate button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CustomButton(
                text: 'Generate Gift Ideas',
                onPressed: () => context.push('/generate'),
              ),
            ),
            
            // Favorite Recipients
            if (_recipients.isNotEmpty) ...[
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Favorite Recipients',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _recipients.length,
                  itemBuilder: (context, index) {
                    final recipient = _recipients[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Navigate to recipient detail
                        },
                        child: Column(
                          children: [
                            RecipientAvatar(
                              name: recipient.name,
                              size: 80,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recipient.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // Popular Gifts
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Popular Gifts This Month',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _popularGifts.length,
                itemBuilder: (context, index) {
                  final gift = _popularGifts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      title: Text(
                        gift.name,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      subtitle: Text(
                        '\${gift.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
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