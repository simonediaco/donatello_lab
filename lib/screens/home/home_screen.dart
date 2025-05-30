import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/recipient.dart';
import '../../theme/app_theme.dart';
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
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    _loadRecipients();
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

  @override
  void dispose() {
    _animationController.dispose();
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
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(user),
                  ),
                  
                  // Quick actions
                  SliverToBoxAdapter(
                    child: _buildQuickActions(),
                  ),
                  
                  // Recent recipients
                  SliverToBoxAdapter(
                    child: _buildRecentRecipients(),
                  ),
                  
                  // Features section
                  SliverToBoxAdapter(
                    child: _buildFeaturesSection(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildHeader(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // User greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.firstName != null 
                        ? '${user.firstName} ${user.lastName ?? ''}'.trim()
                        : 'Welcome!',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ],
                ),
              ),
              
              // Profile and settings
              Row(
                children: [
                  _buildIconButton(
                    icon: Icons.notifications_outlined,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications coming soon')),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildProfileButton(user),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Search bar
          _buildSearchBar(),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Icon(
          icon,
          color: AppTheme.textPrimaryColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildProfileButton(dynamic user) {
    return GestureDetector(
      onTap: () => _showProfileMenu(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: user?.firstName != null
          ? Center(
              child: Text(
                user.firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : const Icon(
              Icons.person_outline,
              color: Colors.white,
              size: 24,
            ),
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
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
              icon: Icons.person_outline,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
            
            _buildMenuOption(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon')),
                );
              },
            ),
            
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
        color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search recipients, gifts, or ideas...',
          hintStyle: TextStyle(
            color: AppTheme.textTertiaryColor,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.textTertiaryColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Search functionality coming soon')),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.auto_awesome,
                  title: 'Generate Ideas',
                  subtitle: 'Get AI-powered gift suggestions',
                  gradient: AppTheme.primaryGradient,
                  onTap: () => context.push('/generate-gifts'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.people_outline,
                  title: 'Add Recipient',
                  subtitle: 'Create a new gift recipient',
                  gradient: const LinearGradient(
                    colors: [AppTheme.successColor, Color(0xFF34D399)],
                  ),
                  onTap: () => context.push('/recipients/add'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.bookmark_outline,
                  title: 'Saved Gifts',
                  subtitle: 'View your saved gift ideas',
                  gradient: const LinearGradient(
                    colors: [AppTheme.warningColor, Color(0xFFFBBF24)],
                  ),
                  onTap: () => context.push('/saved-gifts'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.history,
                  title: 'History',
                  subtitle: 'Browse past searches',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  ),
                  onTap: () => context.push('/history'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Recipients',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              TextButton(
                onPressed: () => context.push('/recipients'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _isLoadingRecipients 
            ? _buildRecipientsLoading()
            : _buildRecipientsList(_recipients),
        ],
      ),
    );
  }

  Widget _buildRecipientsLoading() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            margin: EdgeInsets.only(right: index < 2 ? 16 : 0),
            decoration: AppTheme.cardDecoration,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipientsError() {
    return Container(
      height: 120,
      decoration: AppTheme.cardDecoration,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Error loading recipients',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientsList(List<Recipient> recipients) {
    if (recipients.isEmpty) {
      return _buildEmptyRecipients();
    }

    return SizedBox(
      height: 120,
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
      height: 120,
      decoration: AppTheme.cardDecoration,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              color: AppTheme.textTertiaryColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No recipients yet',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => context.push('/recipients/add'),
              child: const Text('Add your first recipient'),
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
        decoration: AppTheme.cardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recipient.name,
              style: Theme.of(context).textTheme.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (recipient.relation.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                recipient.relation,
                style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover More',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          
          _buildFeatureCard(
            icon: Icons.trending_up,
            title: 'Trending Gifts',
            subtitle: 'See what\'s popular right now',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trending gifts coming soon')),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildFeatureCard(
            icon: Icons.event,
            title: 'Upcoming Events',
            subtitle: 'Never miss an important date',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Events calendar coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textTertiaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'Home',
                isActive: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.people_outline,
                label: 'Recipients',
                onTap: () => context.push('/recipients'),
              ),
              _buildNavItem(
                icon: Icons.auto_awesome,
                label: 'Generate',
                                  onTap: () => context.push('/generate-gifts'),
              ),
              _buildNavItem(
                icon: Icons.bookmark_outline,
                label: 'Saved',
                onTap: () => context.push('/saved-gifts'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
            ? AppTheme.primaryColor.withOpacity(0.1) 
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primaryColor : AppTheme.textTertiaryColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primaryColor : AppTheme.textTertiaryColor,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}