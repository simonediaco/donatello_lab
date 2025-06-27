import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Donatello/l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../models/recipient.dart';
import '../../models/gift.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../theme/cosmic_theme.dart';

class RecipientsListScreen extends ConsumerStatefulWidget {
  const RecipientsListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RecipientsListScreen> createState() => _RecipientsListScreenState();
}

class _RecipientsListScreenState extends ConsumerState<RecipientsListScreen>
    with TickerProviderStateMixin {
  List<Recipient> _recipients = [];
  List<Recipient> _filteredRecipients = [];
  Map<int, List<Gift>> _giftsByRecipient = {};
  Set<int> _expandedRecipients = {};
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

    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToAddRecipient() async {
    await context.push('/recipients/add');
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);

      // Load recipients
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

      if (mounted) {
        setState(() {
          _recipients = recipients;
          _filteredRecipients = recipients;
          _giftsByRecipient = giftsByRecipient;
          _isLoading = false;
        });
      }

      _animationController.forward();
    } catch (e) {
      print("Error loading data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _toggleRecipient(int recipientId) {
    final gifts = _giftsByRecipient[recipientId] ?? [];

    // Se non ci sono regali, non fare nulla
    if (gifts.isEmpty) return;

    setState(() {
      if (_expandedRecipients.contains(recipientId)) {
        _expandedRecipients.remove(recipientId);
      } else {
        _expandedRecipients.add(recipientId);
      }
    });
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.removeGift,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CosmicTheme.textPrimary,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.confirmRemoveGift,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: CosmicTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CosmicTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppLocalizations.of(context)!.remove,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
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
            content: Text(
              AppLocalizations.of(context)!.giftRemovedSuccessfully,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorRemoving,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with cosmic background
            Container(
              decoration: const BoxDecoration(
                gradient: CosmicTheme.cosmicGradient,
              ),
              child: _buildHeader(),
            ),

            // Content with normal background
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: _isLoading
                    ? _buildLoadingState()
                    : _recipients.isEmpty
                        ? _buildEmptyState()
                        : _buildRecipientsList(),
              ),
            ),
          ],
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
                    AppLocalizations.of(context)!.recipients,
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: CosmicTheme.textPrimaryOnDark,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_recipients.length} ${_recipients.length == 1 ? AppLocalizations.of(context)!.personInYourCircle : AppLocalizations.of(context)!.peopleInYourCircle}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: CosmicTheme.textSecondaryOnDark,
                    ),
                  ),
                ],
              ),
              if (_recipients.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: CosmicTheme.primaryAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_recipients.length}',
                    style: GoogleFonts.inter(
                      color: CosmicTheme.primaryAccent,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterRecipients,
        style: GoogleFonts.inter(
          fontSize: 16,
          color: CosmicTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchRecipients,
          hintStyle: GoogleFonts.inter(
            color: CosmicTheme.textTertiary,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: CosmicTheme.textTertiary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: CosmicTheme.textTertiary,
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          color: CosmicTheme.primaryAccent,
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.loadingRecipients,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: CosmicTheme.textSecondary,
          ),
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
                  color: CosmicTheme.primaryAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.people_outline,
                  size: 60,
                  color: CosmicTheme.primaryAccent,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                AppLocalizations.of(context)!.noRecipients,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: CosmicTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                AppLocalizations.of(context)!.noRecipientsDescription,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: CosmicTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Call to action
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: CosmicTheme.yellow,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.tip,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CosmicTheme.yellow,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.recipientTip,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CosmicTheme.textSecondary,
                      ),
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
          onRefresh: _refreshData,
          color: CosmicTheme.primaryAccent,
          child: _filteredRecipients.isEmpty
              ? _buildNoResultsState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
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
              color: CosmicTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noResults,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CosmicTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.modifySearchTerms,
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

  Widget _buildRecipientCard(Recipient recipient, int index) {
    final gifts = _giftsByRecipient[recipient.id] ?? [];
    final isExpanded = _expandedRecipients.contains(recipient.id);
    final hasGifts = gifts.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header clickable per accordion
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              if (hasGifts) {
                _toggleRecipient(recipient.id!);
              } else {
                final result = await context.push('/recipients/${recipient.id}');
                if (result == true) {
                  _loadData();
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Avatar - clickable per dettagli
                  GestureDetector(
                    onTap: () async {
                      final result = await context.push('/recipients/${recipient.id}');
                      if (result == true) {
                        _loadData();
                      }
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: CosmicTheme.buttonGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          recipient.name.isNotEmpty 
                            ? recipient.name[0].toUpperCase()
                            : '?',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Content - clickable per dettagli
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await context.push('/recipients/${recipient.id}');
                        if (result == true) {
                          _loadData();
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and age
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  recipient.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: CosmicTheme.textPrimary,
                                  ),
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
                                    color: CosmicTheme.primaryAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${recipient.age}y',
                                    style: GoogleFonts.inter(
                                      color: CosmicTheme.primaryAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Relationship and gifts count
                          Row(
                            children: [
                              Text(
                                recipient.relation,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: CosmicTheme.primaryAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (hasGifts) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CosmicTheme.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.favorite,
                                        color: CosmicTheme.red,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${gifts.length}',
                                        style: GoogleFonts.inter(
                                          color: CosmicTheme.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
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
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          interest,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: CosmicTheme.textSecondary,
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
                              '+${recipient.interests.length - 3} ${AppLocalizations.of(context)!.more}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: CosmicTheme.textTertiary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Actions section
                  if (hasGifts)
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: CosmicTheme.textTertiary,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Expanded content with gifts - smooth animation
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: isExpanded && hasGifts
              ? AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isExpanded ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.savedGifts} (${gifts.length})',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: CosmicTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () async {
                                final result = await context.push('/recipients/${recipient.id}');
                                if (result == true) {
                                  _loadData();
                                }
                              },
                              icon: Icon(
                                Icons.visibility,
                                size: 16,
                                color: CosmicTheme.primaryAccent,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.seeDetails,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: CosmicTheme.primaryAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...gifts.asMap().entries.map((entry) {
                          final giftIndex = entry.key;
                          final gift = entry.value;
                          return Column(
                            children: [
                              _buildGiftCard(gift),
                              if (giftIndex < gifts.length - 1) const SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],)
    );
  }

  Widget _buildGiftCard(Gift gift) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gift icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CosmicTheme.primaryAccent.withOpacity(0.3),
                      CosmicTheme.primaryAccent.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.card_giftcard,
                  color: CosmicTheme.primaryAccent,
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
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CosmicTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Price and match
                    Row(
                      children: [
                        if (gift.price > 0) ...[
                          Text(
                            '€${gift.price.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        if (gift.match != null && gift.match! > 0) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.stars,
                                color: CosmicTheme.yellow,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${gift.match}%',
                                style: GoogleFonts.inter(
                                  color: CosmicTheme.yellow,
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

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (gift.amazonLink != null && gift.amazonLink != 'None' && gift.amazonLink!.isNotEmpty)
                    IconButton(
                      onPressed: () => _launchUrl(gift.amazonLink),
                      icon: Icon(
                        Icons.shopping_cart,
                        color: CosmicTheme.yellow,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                  const SizedBox(width: 4),

                  IconButton(
                    onPressed: () => _deleteGift(gift),
                    icon: Icon(
                      Icons.delete,
                      color: CosmicTheme.red,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          // Description
          if (gift.description?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              gift.description!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CosmicTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: CosmicTheme.buttonGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CosmicTheme.primaryAccent.withOpacity(0.3),
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