
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../models/recipient.dart';
import '../../widgets/recipient_avatar.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

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

  void _navigateToAddRecipient() async {
    await context.push('/recipients/add');
    // Ricarica la lista quando si torna dalla pagina di aggiunta
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
      print("Errore nel caricamento dei destinatari: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'I tuoi destinatari',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _recipients.isEmpty
              ? _buildEmptyState()
              : _buildRecipientsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddRecipient,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      bottomNavigationBar: const CustomBottomNavigation(
        currentIndex: 1,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person_add_outlined,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Nessun destinatario ancora',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Aggiungi persone per cui vuoi trovare\nil regalo perfetto. Più dettagli fornisci,\nmigliori saranno i suggerimenti!',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToAddRecipient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Aggiungi il primo destinatario',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _recipients.length,
      itemBuilder: (context, index) {
        final recipient = _recipients[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  recipient.name[0].toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            title: Text(
              recipient.name,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  recipient.relation,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (recipient.interests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: recipient.interests.take(3).map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          interest,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.5),
            ),
            onTap: () async {
              final result = await context.push('/recipients/${recipient.id}');
              // Se il destinatario è stato eliminato, ricarica la lista
              if (result == true) {
                _loadRecipients();
              }
            },
          ),
        );
      },
    );
  }
}
