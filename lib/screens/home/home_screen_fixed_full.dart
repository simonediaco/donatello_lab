import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/recipient_avatar.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../models/recipient.dart';
import '../../models/gift.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Recipient> _recipients = [];
  List<Gift> _popularGifts = [];
  bool _isLoadingRecipients = true;
  bool _isLoadingGifts = true;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
    _loadPopularGifts();
  }

  Future<void> _loadRecipients() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final recipientsData = await apiService.getRecipients();

      setState(() {
        _recipients = recipientsData
            .map((data) => Recipient.fromJson(data))
            .toList()
            .take(3)
            .toList();
        _isLoadingRecipients = false;
      });
    } catch (e) {
      print("Errore nel caricamento dei destinatari: $e");
      setState(() => _isLoadingRecipients = false);
    }
  }

  void _loadPopularGifts() {
    setState(() {
      _popularGifts = [
        Gift(
          name: 'Personalized Portrait',
          price: 120,
          description: 'Custom portrait in Renaissance style',
          image: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        ),
        Gift(
          name: 'Custom Jewelry',
          price: 85,
          description: 'Handcrafted jewelry with personal touch',
          image: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=400',
        ),
        Gift(
          name: 'Wireless Headphones',
          price: 150,
          description: 'Premium noise-canceling headphones',
          image: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400',
        ),
        Gift(
          name: 'Smart Watch',
          price: 299,
          description: 'Latest smartwatch with health tracking',
          image: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
        ),
      ];
      _isLoadingGifts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 280,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/auth/login-cover.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    right: 24,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: const Icon(Icons.notifications_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {},
                          child: const Icon(Icons.person_outline, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    child: Text(
                      'Ciao, ${user?.firstName ?? "Utente"}',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/generate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('Generate Gift Ideas', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Favorite Recipients', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70)),
            ),
            const SizedBox(height: 16),

            if (_recipients.isEmpty && !_isLoadingRecipients)
              GestureDetector(
                onTap: () => context.push('/recipients/add'),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.add, size: 32, color: AppTheme.primaryColor),
                      const SizedBox(height: 16),
                      Text('Aggiungi il primo destinatario', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _recipients.length,
                  itemBuilder: (context, index) {
                    final recipient = _recipients[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(recipient.name[0].toUpperCase(), style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          Text(recipient.name, style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Popular Gifts This Month', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70)),
            ),
            const SizedBox(height: 16),

            if (_isLoadingGifts)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppTheme.primaryColor)))
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _popularGifts.length,
                  itemBuilder: (context, index) {
                    final gift = _popularGifts[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                                image: DecorationImage(image: NetworkImage(gift.image ?? ''), fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(gift.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                                  Text('\$${gift.price.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 0),
    );
  }
}