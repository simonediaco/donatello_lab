import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/recipient.dart';
import '../../widgets/recipient_avatar.dart';
import '../../theme/app_theme.dart';

class RecipientsListScreen extends ConsumerStatefulWidget {
  const RecipientsListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RecipientsListScreen> createState() => _RecipientsListScreenState();
}

class _RecipientsListScreenState extends ConsumerState<RecipientsListScreen> {
  List<Recipient> _recipients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final recipientsData = await apiService.getRecipients();
      
      setState(() {
        _recipients = recipientsData
            .map((data) => Recipient.fromJson(data))
            .toList();
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
        title: const Text('Recipients'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _recipients.length,
              itemBuilder: (context, index) {
                final recipient = _recipients[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: RecipientAvatar(
                      name: recipient.name,
                      size: 60,
                    ),
                    title: Text(
                      recipient.name,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    subtitle: Text(
                      recipient.relation,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.subtitleColor,
                          ),
                    ),
                    onTap: () {
                      // TODO: Navigate to recipient detail
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/recipients/add'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}