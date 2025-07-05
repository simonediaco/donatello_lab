
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/cosmic_theme.dart';
import 'gift_disclaimers.dart';

class AffiliateWebViewScreen extends StatefulWidget {
  final String url;
  final String? title;

  const AffiliateWebViewScreen({
    Key? key,
    required this.url,
    this.title,
  }) : super(key: key);

  @override
  State<AffiliateWebViewScreen> createState() => _AffiliateWebViewScreenState();
}

class _AffiliateWebViewScreenState extends State<AffiliateWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _pageTitle = '';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // On web, skip WebView initialization and go directly to browser
      _isLoading = false;
    } else {
      // Initialize WebView for mobile platforms
      Future.microtask(() => _initializeWebView());
    }
  }

  void _initializeWebView() {
    if (!mounted) return;
    
    try {
      // Validate URL first
      final uri = Uri.tryParse(widget.url);
      if (uri == null || !uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
        return;
      }      
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              _onPageStarted();
            },
            onPageFinished: (url) {
              _onPageFinished();
            },
            onWebResourceError: (error) => _onWebResourceError(error),
            onNavigationRequest: (request) {
              // Allow all navigation for affiliate links
              return NavigationDecision.navigate;
            },
            onHttpError: (error) {
              print('HTTP Error: ${error.response?.statusCode}');
            },
          ),
        )
        // Add Android-specific settings
        ..enableZoom(true);
      
      // Load URL after controller setup
      _controller!.loadRequest(uri);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _onPageStarted() {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
  }

  void _onPageFinished() {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _loadPageTitle();
    }
  }

  void _onWebResourceError(WebResourceError error) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      
      // On Android, if we get a critical error, automatically fallback to browser
      if (Platform.isAndroid && _shouldAutoFallback(error)) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _openInBrowser();
          }
        });
      }
    }
  }

  bool _shouldAutoFallback(WebResourceError error) {
    // Common error codes that indicate the site blocks WebView
    final criticalErrors = [
      -2, // ERR_INTERNET_DISCONNECTED
      -6, // ERR_CONNECTION_REFUSED  
      -8, // ERR_TIMEOUT
      -10, // ERR_ACCESS_DENIED
      -14, // ERR_UNKNOWN_URL_SCHEME
      -15, // ERR_INVALID_URL
    ];
    
    return criticalErrors.contains(error.errorCode) ||
           error.description.toLowerCase().contains('access') ||
           error.description.toLowerCase().contains('blocked') ||
           error.description.toLowerCase().contains('refused');
  }

  Future<void> _loadPageTitle() async {
    if (_controller == null) return;
    
    try {
      final title = await _controller!.getTitle();
      if (title != null && mounted) {
        setState(() {
          _pageTitle = title;
        });
      }
    } catch (e) {
      // Ignore title loading errors
    }
  }

  Future<void> _openInBrowser() async {
    try {
      String urlToOpen = widget.url;
      
      if (_controller != null) {
        try {
          final currentUrl = await _controller!.currentUrl();
          if (currentUrl != null && currentUrl.isNotEmpty) {
            urlToOpen = currentUrl;
          }
        } catch (e) {
          // Use original URL if current URL is not available
        }
      }
      
      // Mostra il disclaimer prima di aprire il browser esterno
      await showDialog(
        context: context,
        builder: (context) => ExternalLinkDisclaimerModal(
          url: urlToOpen,
          onConfirm: () => _launchExternalUrl(urlToOpen),
        ),
      );
    } catch (e) {
      _showErrorMessage('Errore nell\'apertura del link');
    }
  }

  Future<void> _shareProduct() async {
    try {
      String urlToShare = widget.url;
      String titleToShare = _getDisplayTitle();
      
      if (_controller != null) {
        try {
          final currentUrl = await _controller!.currentUrl();
          if (currentUrl != null && currentUrl.isNotEmpty) {
            urlToShare = currentUrl;
          }
        } catch (e) {
          // Use original URL if current URL is not available
        }
      }
      
      // Condividi con un messaggio ottimizzato per app di messaggistica
      String shareText = 'Ciao! Ho trovato questo prodotto che potrebbe interessarti: $titleToShare\n\n$urlToShare';
      
      await Share.share(
        shareText,
        subject: 'Ti consiglio questo prodotto: $titleToShare',
      );
    } catch (e) {
      _showErrorMessage('Errore nella condivisione del link');
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        // Su Android, usa LaunchMode.externalNonBrowserApplication per forzare l'apertura nel browser
        if (Platform.isAndroid) {
          await launchUrl(
            uri, 
            mode: LaunchMode.externalNonBrowserApplication,
            webOnlyWindowName: '_blank',
          );
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        _showErrorMessage('Impossibile aprire il link nel browser');
      }
    } catch (e) {
      _showErrorMessage('Errore nell\'apertura del link');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    
    if (_controller != null) {
      _controller!.loadRequest(Uri.parse(widget.url));
    } else {
      // Re-initialize controller if it's null
      _initializeWebView();
    }
  }

  String _getDisplayTitle() {
    if (widget.title?.isNotEmpty == true) {
      return widget.title!;
    }
    if (_pageTitle.isNotEmpty) {
      return _pageTitle;
    }
    return 'Prodotto Affiliato';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _getDisplayTitle(),
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: CosmicTheme.textPrimary,
          fontSize: 18,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: CosmicTheme.textPrimary,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.share,
            color: CosmicTheme.primaryAccent,
          ),
          onPressed: _shareProduct,
          tooltip: 'Condividi prodotto',
        ),
        IconButton(
          icon: Icon(
            Icons.launch,
            color: CosmicTheme.primaryAccent,
          ),
          onPressed: _openInBrowser,
          tooltip: 'Apri nel browser esterno',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorView();
    }

    // On web platform, show web-specific view
    if (kIsWeb) {
      return _buildWebView();
    }

    if (_controller == null) {
      return _buildLoadingView();
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_isLoading) _buildLoadingView(),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                CosmicTheme.primaryAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Caricamento prodotto...',
              style: GoogleFonts.inter(
                color: CosmicTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    // For web platform, show a message to open in browser
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.open_in_browser,
                size: 64,
                color: CosmicTheme.primaryAccent,
              ),
              const SizedBox(height: 24),
              Text(
                'Visualizza prodotto',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CosmicTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Su web, i prodotti affiliati vengono aperti direttamente nel browser per una migliore esperienza di acquisto.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: CosmicTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _openInBrowser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CosmicTheme.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Apri nel browser',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: CosmicTheme.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                'Errore nel caricamento',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: CosmicTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Non è stato possibile caricare la pagina del prodotto. Questo può succedere se il sito blocca l\'accesso tramite app mobile.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: CosmicTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CosmicTheme.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Riprova',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _shareProduct,
                    child: Text(
                      'Condividi',
                      style: GoogleFonts.inter(
                        color: CosmicTheme.primaryAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _openInBrowser,
                    child: Text(
                      'Apri nel browser',
                      style: GoogleFonts.inter(
                        color: CosmicTheme.primaryAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
