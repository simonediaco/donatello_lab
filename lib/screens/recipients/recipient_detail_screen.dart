import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/recipient.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';

class RecipientDetailScreen extends ConsumerStatefulWidget {
  final int recipientId;

  const RecipientDetailScreen({
    Key? key,
    required this.recipientId,
  }) : super(key: key);

  @override
  ConsumerState<RecipientDetailScreen> createState() => _RecipientDetailScreenState();
}

class _RecipientDetailScreenState extends ConsumerState<RecipientDetailScreen>
    with TickerProviderStateMixin {
  Recipient? _recipient;
  bool _isLoading = true;
  bool _isDeleting = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

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
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _loadRecipient();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipient() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final recipientData = await apiService.getRecipient(widget.recipientId);
      
      setState(() {
        _recipient = Recipient.fromJson(recipientData);
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      print("Error loading recipient: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error loading recipient'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteRecipient() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Recipient',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: Text(
          'Are you sure you want to delete ${_recipient?.name}? This action cannot be undone.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() => _isDeleting = true);
      
      try {
        final apiService = ref.read(apiServiceProvider);
        await apiService.deleteRecipient(widget.recipientId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Recipient deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          context.pop(true);
        }
      } catch (e) {
        setState(() => _isDeleting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error deleting recipient'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  void _editRecipient() async {
    if (_recipient != null) {
      final result = await context.push('/recipients/${widget.recipientId}/edit');
      if (result == true) {
        _loadRecipient();
      }
    }
  }

  void _generateGifts() {
    // TODO: Navigate to gift generation with this recipient
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Gift generation coming soon'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
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
              
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _recipient == null
                        ? _buildErrorState()
                        : _buildRecipientDetail(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.softShadow,
              ),
              child: Icon(
                Icons.arrow_back,
                color: AppTheme.textPrimaryColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _recipient?.name ?? 'Recipient',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          if (_recipient != null && !_isDeleting) ...[
            GestureDetector(
              onTap: _editRecipient,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _deleteRecipient,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delete,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text('Loading recipient...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recipient not found',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'The recipient you\'re looking for doesn\'t exist or has been deleted.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Go Back',
              onPressed: () => context.pop(),
              icon: Icons.arrow_back,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientDetail() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header
              _buildProfileHeader(),
              const SizedBox(height: 32),
              
              // Basic info
              _buildBasicInfoCard(),
              const SizedBox(height: 24),
              
              // Interests
              if (_recipient!.interests.isNotEmpty) ...[
                _buildInterestsCard(),
                const SizedBox(height: 24),
              ],
              
              // Dislikes
              if (_recipient!.dislikes?.isNotEmpty == true) ...[
                _buildDislikesCard(),
                const SizedBox(height: 24),
              ],
              
              // Notes
              if (_recipient!.notes?.isNotEmpty == true) ...[
                _buildNotesCard(),
                const SizedBox(height: 24),
              ],
              
              // Action buttons
              _buildActionButtons(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          // Avatar
          ScaleTransition(
            scale: _scaleAnimation,
            child: Hero(
              tag: 'recipient_avatar_${_recipient!.id}',
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _recipient!.name.isNotEmpty 
                      ? _recipient!.name[0].toUpperCase()
                      : '?',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Name and relationship
          Text(
            _recipient!.name,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _recipient!.relation,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildInfoRow('Gender', _recipient!.genderDisplay),
          
          if (_recipient!.age != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Age', '${_recipient!.age} years old'),
          ],
          
          if (_recipient!.birthDate != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Birth Date', _formatDate(_recipient!.birthDate!)),
          ],
        ],
      ),
    );
  }

  Widget _buildInterestsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite,
                  color: AppTheme.successColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Interests',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recipient!.interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getInterestEmoji(interest),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      interest,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDislikesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.thumb_down,
                  color: AppTheme.errorColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Dislikes',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recipient!.dislikes!.map((dislike) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('❌', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      dislike,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.elevatedCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.note_alt,
                  color: AppTheme.warningColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Personal Notes',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              _recipient!.notes!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary action - Generate gifts
        CustomButton(
          text: 'Generate Gift Ideas',
          onPressed: _generateGifts,
          icon: Icons.auto_awesome,
        ),
        
        const SizedBox(height: 16),
        
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _editRecipient,
                icon: const Icon(Icons.edit, size: 20),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share functionality coming soon'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                },
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getInterestEmoji(String interest) {
    switch (interest.toLowerCase()) {
      case 'music': return '🎵';
      case 'sports': return '⚽';
      case 'technology': return '💻';
      case 'art': return '🎨';
      case 'travel': return '✈️';
      case 'cooking': return '👨‍🍳';
      case 'reading': return '📚';
      case 'movies': return '🎬';
      case 'fashion': return '👗';
      case 'gaming': return '🎮';
      default: return '⭐';
    }
  }
}