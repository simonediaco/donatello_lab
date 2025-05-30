import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/recipient.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../theme/app_theme.dart';

class RecipientsListScreen extends ConsumerStatefulWidget {
  const RecipientsListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RecipientsListScreen> createState() => _RecipientsListScreenState();
}

class _RecipientsListScreenState extends ConsumerState<RecipientsListScreen>
    with TickerProviderStateMixin {
  List<Recipient> _recipients = [];
  List<Recipient> _filteredRecipients = [];
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

    _loadRecipients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToAddRecipient() async {
    await context.push('/recipients/add');
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = ref.read(apiServiceProvider);
      final recipientsData = await apiService.getRecipients();
      
      setState(() {
        _recipients = recipientsData
            .map((data) => Recipient.fromJson(data))
            .toList();
        _filteredRecipients = _recipients;
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      print("Error loading recipients: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterRecipients(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredRecipients = _recipients;
      } else {
        _filteredRecipients = _recipients
            .where((recipient) =>
                recipient.name.toLowerCase().contains(query.toLowerCase()) ||
                recipient.relation.toLowerCase().contains(query.toLowerCase()) ||
                recipient.interests.any((interest) =>
                    interest.toLowerCase().contains(query.toLowerCase())))
            .toList();
      }
    });
  }

  Future<void> _refreshRecipients() async {
    await _loadRecipients();
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
              // Header with search
              _buildHeader(),
              
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _recipients.isEmpty
                        ? _buildEmptyState()
                        : _buildRecipientsList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: 1),
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
                    'Recipients',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_recipients.length} people in your circle',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (_recipients.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_recipients.length}',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Search bar
          if (_recipients.isNotEmpty) _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: TextField(
        controller: _searchController,
        onChanged: _filterRecipients,
        decoration: InputDecoration(
          hintText: 'Search recipients...',
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
                    _filterRecipients('');
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

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Loading recipients...',
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
                  Icons.people_outline,
                  size: 60,
                  color: AppTheme.primaryColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'No recipients yet',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Add people you want to find the perfect gift for. The more details you provide, the better our suggestions will be!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Call to action
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.elevatedCardDecoration,
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.warningColor,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pro Tip',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Include interests, favorite colors, and what they don\'t like for more personalized gift suggestions.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
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

  Widget _buildRecipientsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshRecipients,
          color: AppTheme.primaryColor,
          child: _filteredRecipients.isEmpty
              ? _buildNoResultsState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _filteredRecipients.length,
                  itemBuilder: (context, index) {
                    return _buildRecipientCard(_filteredRecipients[index], index);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textTertiaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientCard(Recipient recipient, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final result = await context.push('/recipients/${recipient.id}');
            if (result == true) {
              _loadRecipients();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar
                Hero(
                  tag: 'recipient_avatar_${recipient.id}',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Center(
                      child: Text(
                        recipient.name.isNotEmpty 
                          ? recipient.name[0].toUpperCase()
                          : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and age
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              recipient.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (recipient.age != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${recipient.age}y',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Relationship
                      Text(
                        recipient.relation,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Interests chips
                      if (recipient.interests.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: recipient.interests
                              .take(3)
                              .map((interest) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      interest,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      
                      // Show more interests indicator
                      if (recipient.interests.length > 3) ...[
                        const SizedBox(height: 4),
                        Text(
                          '+${recipient.interests.length - 3} more',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textTertiaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textTertiaryColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _navigateToAddRecipient,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}