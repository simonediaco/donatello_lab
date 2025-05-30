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
  List<Gift> _filteredGifts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _filterOptions = ['All', 'Recent', 'Low Price', 'High Price'];

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
        _filteredGifts = gifts;
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      print("Error loading saved gifts: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterGifts(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Gift> allGifts = [];
    _giftsByRecipient.values.forEach((gifts) => allGifts.addAll(gifts));
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      allGifts = allGifts.where((gift) =>
          gift.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (gift.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (gift.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();
    }
    
    // Apply sort filter
    switch (_selectedFilter) {
      case 'Recent':
        // Assuming gifts have IDs in chronological order
        allGifts.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        break;
      case 'Low Price':
        allGifts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'High Price':
        allGifts.sort((a, b) => b.price.compareTo(a.price));
        break;
    }
    
    setState(() {
      _filteredGifts = allGifts;
    });
  }

  Future<void> _refreshGifts() async {
    await _loadSavedGifts();
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url == 'None') return;
    
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
          'Remove Gift',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: Text(
          'Are you sure you want to remove "${gift.name}" from your saved gifts?',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && gift.id != null) {
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.deleteSavedGift(gift.id!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gift removed successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        _loadSavedGifts();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing gift: ${e.toString()}'),
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
              
              // Filters
              if (!_isLoading && _filteredGifts.isNotEmpty) _buildFilters(),
              
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _filteredGifts.isEmpty
                        ? _buildEmptyState()
                        : _buildGiftsList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved Gifts',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_filteredGifts.length} gifts saved',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (_filteredGifts.isNotEmpty)
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
                        Icons.bookmark,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_filteredGifts.length}',
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
          
          const SizedBox(height: 24),
          
          // Search bar
          if (!_isLoading && _filteredGifts.isNotEmpty) _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: TextField(
        controller: _searchController,
        onChanged: _filterGifts,
        decoration: InputDecoration(
          hintText: 'Search saved gifts...',
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
                    _filterGifts('');
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
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort by',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                
                return Container(
                  margin: EdgeInsets.only(right: index < _filterOptions.length - 1 ? 12 : 0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                        _applyFilters();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                        ),
                        boxShadow: isSelected ? AppTheme.softShadow : null,
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
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
          'Loading saved gifts...',
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
                  Icons.bookmarks_outlined,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                _searchQuery.isNotEmpty ? 'No matching gifts' : 'No saved gifts yet',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                _searchQuery.isNotEmpty 
                  ? 'Try adjusting your search terms or filters'
                  : 'Start generating gift ideas and save your favorites to see them here.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              if (_searchQuery.isEmpty) ...[
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
                        'Generate Your First Gifts',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use our AI to create personalized gift suggestions, then save your favorites.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/generate-gifts'),
                          icon: const Icon(Icons.auto_awesome, size: 20),
                          label: const Text('Generate Gift Ideas'),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGiftsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshGifts,
          color: AppTheme.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _filteredGifts.length,
            itemBuilder: (context, index) {
              return _buildGiftCard(_filteredGifts[index], index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGiftCard(Gift gift, int index) {
    final recipient = gift.recipient != null ? _recipients[gift.recipient] : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showGiftDetails(gift),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with recipient info
                if (recipient != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'For ${recipient.name}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: AppTheme.textTertiaryColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share, size: 20, color: AppTheme.textPrimaryColor),
                                const SizedBox(width: 12),
                                const Text('Share'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                                const SizedBox(width: 12),
                                Text('Remove', style: TextStyle(color: AppTheme.errorColor)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteGift(gift);
                          } else if (value == 'share') {
                            _shareGift(gift);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Gift details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gift image placeholder
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.3),
                            AppTheme.primaryLight.withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.card_giftcard,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Gift info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gift.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 4),
                          
                          if (gift.category?.isNotEmpty == true) ...[
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
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          
                          // Price and match
                          Row(
                            children: [
                              if (gift.price > 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '€${gift.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: AppTheme.successColor,
                                      fontSize: 14,
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
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
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
                  ],
                ),
                
                // Description
                if (gift.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  Text(
                    gift.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                // Action buttons
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (gift.amazonLink != null && gift.amazonLink != 'None') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchUrl(gift.amazonLink),
                          icon: Icon(Icons.shopping_cart, size: 16),
                          label: const Text('Buy Now'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showGiftDetails(gift),
                        icon: Icon(Icons.visibility, size: 16),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
          ),
        ),
      ),
    );
  }

  void _showGiftDetails(Gift gift) {
    final recipient = gift.recipient != null ? _recipients[gift.recipient] : null;
    
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
              
              // Recipient info
              if (recipient != null) ...[
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          recipient.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gift for',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          recipient.name,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              
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
                  'Description',
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
                  'Category',
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
                  if (gift.amazonLink != null && gift.amazonLink != 'None') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _launchUrl(gift.amazonLink);
                        },
                        icon: Icon(Icons.shopping_cart, size: 20),
                        label: const Text('Buy on Amazon'),
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
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _shareGift(gift);
                          },
                          icon: Icon(Icons.share, size: 20),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteGift(gift);
                          },
                          icon: Icon(Icons.delete, size: 20),
                          label: const Text('Remove'),
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
            ],
          ),
        ),
      ),
    );
  }

  void _shareGift(Gift gift) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}