
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _lastSearchKey = 'last_gift_search';

  // Salva l'ultima ricerca
  static Future<void> saveLastSearch({
    required String recipientName,
    int? recipientAge,
    required List<dynamic> gifts,
    int? existingRecipientId,
    Map<String, dynamic>? wizardData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final searchData = {
      'recipientName': recipientName,
      'recipientAge': recipientAge,
      'gifts': gifts,
      'existingRecipientId': existingRecipientId,
      'wizardData': wizardData,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_lastSearchKey, jsonEncode(searchData));
  }

  // Recupera l'ultima ricerca
  static Future<Map<String, dynamic>?> getLastSearch() async {
    final prefs = await SharedPreferences.getInstance();
    final searchJson = prefs.getString(_lastSearchKey);
    
    if (searchJson == null) return null;
    
    try {
      return jsonDecode(searchJson);
    } catch (e) {
      // Se c'è un errore nel parsing, rimuovi i dati corrotti
      await clearLastSearch();
      return null;
    }
  }

  // Rimuove l'ultima ricerca
  static Future<void> clearLastSearch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSearchKey);
  }

  // Controlla se esiste un'ultima ricerca
  static Future<bool> hasLastSearch() async {
    final lastSearch = await getLastSearch();
    return lastSearch != null;
  }

  // Ottiene un riassunto dell'ultima ricerca per la UI
  static Future<String?> getLastSearchSummary() async {
    final lastSearch = await getLastSearch();
    if (lastSearch == null) return null;

    final recipientName = lastSearch['recipientName'] as String? ?? 'Destinatario';
    final giftsCount = (lastSearch['gifts'] as List?)?.length ?? 0;
    
    return 'Ricerca per $recipientName ($giftsCount regali)';
  }
}
