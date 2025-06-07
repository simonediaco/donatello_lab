import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/recipient.dart';
import '../../models/popular_gift.dart';
import '../../theme/cosmic_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_bottom_navigation.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  List<Recipient> _recipients = [];
  bool _isLoadingRecipients = true;
  List<PopularGift> _popularGifts = [];
  bool _isLoadingPopularGifts = true;

  late AnimationController _animationController;
  late AnimationController _cosmicAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _cosmicPulseAnimation;
  late Animation<double> _starRotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cosmicAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _cosmicPulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _cosmicAnimationController,
      curve: Curves.easeInOut,
    ));

    _starRotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_cosmicAnimationController);

    _animationController.forward();
    _cosmicAnimationController.repeat(reverse: true);
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
            .take(5)
            .toList();
        _isLoadingRecipients = false;
      });
    } catch (e) {
      print("Error loading recipients: $e");
      setState(() => _isLoadingRecipients = false);
    }
  }

  Future<void> _loadPopularGifts() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final popularGiftsData = await apiService.getPopularGifts();

      setState(() {
        _popularGifts = popularGiftsData
            .map((data) => PopularGift.fromJson(data))
            .toList();
        _isLoadingPopularGifts = false;
      });
    } catch (e) {
      print("Error loading popular gifts: $e");
      setState(() => _isLoadingPopularGifts = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cosmicAnimationController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      await ref.read(authServiceProvider).logout();
      ref.read(currentUserProvider.notifier).state = null;
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: CosmicTheme.backgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Cosmic Header Section
            SliverToBoxAdapter(
              child: _buildCosmicHeader(user),
            ),

            // White Content Section
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Quick Actions with cosmic elements
                    _buildQuickActions(),

                    // Recent Recipients
                    _buildRecentRecipients(),

                    // Popular Gifts Carousel
                    _buildGiftCarousel(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildCosmicHeader(dynamic user) {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        gradient: CosmicTheme.cosmicGradient,
      ),
      child: Stack(
        children: [
          // Floating cosmic elements
          _buildFloatingCosmicElements(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar with notifications and profile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo
                        Container(
                          width: 36,
                          height: 36,
                          child: Image.asset(
                            'assets/images/logos/logo-donatello-no-bg.png',
                            fit: BoxFit.contain,
                          ),
                        ),

                        // Profile and settings
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.notifications_outlined,
                                color: CosmicTheme.textPrimaryOnDark,
                                size: 26,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notifications coming soon')),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildSettingsButton(),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Welcome message
                    Text(
                      _getGreeting(),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: CosmicTheme.textSecondaryOnDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.firstName != null 
                        ? '${user.firstName}'
                        : 'Utente',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: CosmicTheme.textPrimaryOnDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Scopri il regalo perfetto con l\'aiuto dell\'intelligenza artificiale.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: CosmicTheme.textSecondaryOnDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCosmicElements() {
    return Stack(
      children: [
        // Top right floating orb
        Positioned(
          top: 60,
          right: 20,
          child: AnimatedBuilder(
            animation: _cosmicPulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _cosmicPulseAnimation.value,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccentOnDark.withOpacity(0.3),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: CosmicTheme.primaryAccentOnDark.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom left cosmic shape
        Positioned(
          bottom: 40,
          left: -10,
          child: AnimatedBuilder(
            animation: _starRotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _starRotationAnimation.value * 2 * 3.14159,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ),

        // Small floating dots
        Positioned(
          top: 120,
          left: 40,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: CosmicTheme.textSecondaryOnDark.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 180,
          right: 80,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: CosmicTheme.primaryAccentOnDark.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCosmicIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: CosmicTheme.textPrimaryOnDark,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: () => _showProfileMenu(),
      child: const Icon(
        Icons.settings_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buongiorno';
    if (hour < 17) return 'Buon pomeriggio';
    return 'Buonasera';
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            _buildMenuOption(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help section coming soon')),
                );
              },
            ),

            _buildMenuOption(
              icon: Icons.language,
              title: 'Scopri Donatello',
              onTap: () async {
                Navigator.pop(context);
                try {
                  final uri = Uri.parse('https://donatellolab.com');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Impossibile aprire il sito web')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Errore nell\'apertura del sito web')),
                    );
                  }
                }
              },
            ),

            const Divider(height: 32),

            _buildMenuOption(
              icon: Icons.logout,
              title: 'Sign Out',
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
              isDestructive: true,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? const Color(0xFFEF4444) : CosmicTheme.textPrimary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? const Color(0xFFEF4444) : CosmicTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Cosmic accent dot
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  gradient: CosmicTheme.accentGradientOnDark,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Azioni Rapide',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CosmicTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main action card with cosmic styling
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: CosmicTheme.buttonGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: CosmicTheme.primaryAccent.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/generate-gifts'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Icon pulito senza container - stelle gialle
                      const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFF59E0B), // Giallo del tema
                        size: 32,
                      ),
                      const SizedBox(width: 20),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Genera Idee Regalo',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lascia che l\'AI trovi il regalo perfetto',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Freccia pulita senza container
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecipients() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Cosmic accent dot
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  gradient: CosmicTheme.accentGradientOnDark,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Destinatari Recenti',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CosmicTheme.textPrimary,
                ),
              ),
              const Spacer(),

              // View all button with cosmic styling
              Container(
                decoration: BoxDecoration(
                  gradient: CosmicTheme.buttonGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/recipients'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Vedi Tutti',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _isLoadingRecipients 
            ? _buildRecipientsLoading()
            : _buildRecipientsList(_recipients),
        ],
      ),
    );
  }

  Widget _buildRecipientsLoading() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            margin: EdgeInsets.only(right: index < 2 ? 16 : 0),
            decoration: CosmicTheme.cardDecoration,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(CosmicTheme.primaryAccent),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipientsList(List<Recipient> recipients) {
    if (recipients.isEmpty) {
      return _buildEmptyRecipients();
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recipients.take(5).length,
        itemBuilder: (context, index) {
          final recipient = recipients[index];
          return _buildRecipientCard(recipient, index == recipients.take(5).length - 1);
        },
      ),
    );
  }

  Widget _buildEmptyRecipients() {
    return Container(
      height: 140,
      decoration: CosmicTheme.cardDecoration,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              color: CosmicTheme.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Nessun destinatario ancora',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CosmicTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => context.push('/recipients/add'),
              child: Text(
                'Aggiungi il primo destinatario',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CosmicTheme.primaryAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientCard(Recipient recipient, bool isLast) {
    return GestureDetector(
      onTap: () => context.push('/recipients/${recipient.id}'),
      child: Container(
        width: 100,
        margin: EdgeInsets.only(right: isLast ? 0 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: CosmicTheme.softShadow,
          border: Border.all(
            color: CosmicTheme.primaryAccent.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: CosmicTheme.buttonGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CosmicTheme.primaryAccent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  recipient.name.isNotEmpty 
                    ? recipient.name[0].toUpperCase()
                    : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recipient.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: CosmicTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (recipient.relation.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                recipient.relation,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: CosmicTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGiftCarousel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Cosmic accent dot
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  gradient: CosmicTheme.accentGradientOnDark,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Regali Popolari',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CosmicTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: _isLoadingPopularGifts 
              ? _buildCarouselLoading()
              : _buildPopularGiftsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselLoading() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 220,
          margin: const EdgeInsets.only(right: 20),
          decoration: CosmicTheme.cardDecoration,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(CosmicTheme.primaryAccent),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopularGiftsList() {
    if (_popularGifts.isEmpty) {
      return Container(
        height: 280,
        decoration: CosmicTheme.cardDecoration,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard,
                color: CosmicTheme.textSecondary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Nessun regalo popolare disponibile',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CosmicTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _popularGifts.length,
      itemBuilder: (context, index) {
        final gift = _popularGifts[index];
        return _buildPopularGiftItem(gift, index == _popularGifts.length - 1);
      },
    );
  }

  Widget _buildPopularGiftItem(PopularGift gift, bool isLast) {
    return GestureDetector(
      onTap: () async {
        if (gift.amazonLink != null && gift.amazonLink!.isNotEmpty) {
          try {
            final uri = Uri.parse(gift.amazonLink!);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Impossibile aprire il link')),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Errore nell\'apertura del link')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${gift.name} - €${gift.price.toStringAsFixed(2)}')),
            );
          }
        }
      },
      child: Container(
        width: 220,
        margin: EdgeInsets.only(right: isLast ? 0 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: gift.image != null && gift.image!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(gift.image!),
                fit: BoxFit.cover,
              )
            : null,
          color: gift.image == null || gift.image!.isEmpty 
            ? CosmicTheme.backgroundColor 
            : null,
          border: Border.all(
            color: CosmicTheme.primaryAccent.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: CosmicTheme.primaryAccent.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gift.name,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '€${gift.price.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (gift.category.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: CosmicTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: CosmicTheme.primaryAccent.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    gift.category,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}