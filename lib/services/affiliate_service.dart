import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/affiliate_webview.dart';

class AffiliateService {
  static Future<void> openAffiliateLink({
    required BuildContext context,
    required String url,
    String? title,
    bool forceExternalBrowser = false,
  }) async {
    if (url.isEmpty || url == 'None') {
      return;
    }

    try {
      // Force external browser only when explicitly requested
      if (forceExternalBrowser) {
        await _openInExternalBrowser(url);
      } 
      // On web platform, show a simplified WebView or open external
      else if (kIsWeb) {
        // Try WebView first, but it will show a simplified view
        await _openInWebView(context, url, title);
      } 
      else {
        // Mobile platforms - use native WebView
        await _openInWebView(context, url, title);
      }
    } catch (e) {
      // Fallback to external browser if WebView fails
      await _openInExternalBrowser(url);
    }
  }

  static Future<void> _openInWebView(
    BuildContext context,
    String url,
    String? title,
  ) async {
    await Future.microtask(() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AffiliateWebViewScreen(
            url: url,
            title: title ?? 'Prodotto Affiliato',
          ),
        ),
      );
    });
  }

  static Future<void> _openInExternalBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Cannot launch URL: $url');
    }
  }

  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty || url == 'None') {
      return false;
    }

    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}