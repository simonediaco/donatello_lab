
class AppConstants {
  // WebView related constants
  static const String defaultWebViewTitle = 'Prodotto Affiliato';
  static const String webViewLoadingMessage = 'Caricamento prodotto...';
  static const String webViewErrorTitle = 'Errore nel caricamento';
  static const String webViewErrorMessage = 
      'Non è stato possibile caricare la pagina del prodotto. '
      'Controlla la connessione internet e riprova.';
  
  // Affiliate link validation
  static const List<String> invalidUrlValues = ['None', '', 'null'];
  
  // Error messages
  static const String cannotOpenBrowserError = 'Impossibile aprire il link nel browser';
  static const String linkOpenError = 'Errore nell\'apertura del link';
  
  // Button texts
  static const String retryButtonText = 'Riprova';
  static const String openInBrowserText = 'Apri nel browser';
  
  // Tooltips
  static const String openInBrowserTooltip = 'Apri nel browser';
}
