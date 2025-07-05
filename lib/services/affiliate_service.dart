import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/affiliate_webview.dart';
import '../widgets/gift_disclaimers.dart';

class AffiliateService {
  static Future<void> openAffiliateLink({
    required BuildContext context,
    required String url,
    String? title,
    bool forceExternalBrowser = false,
    bool showDisclaimer = true, // Di default mostra il disclaimer
  }) async {
    if (url.isEmpty || url == 'None') {
      return;
    }

    try {
      // Check if it's a problematic Amazon link on Android
      bool isProblematicAmazonLink = Platform.isAndroid && 
          url.toLowerCase().contains('amazon') && 
          (url.contains('/s?') || url.contains('/search') || url.contains('tag=') || url.contains('/dp/'));

      // Force external browser for problematic links or when explicitly requested
      if (forceExternalBrowser || isProblematicAmazonLink) {
        // Per i link Amazon problematici su Android, rispetta comunque il parametro showDisclaimer
        await _openInExternalBrowser(url, context, showDisclaimer);
      } 
      // On web platform, show a simplified WebView or open external
      else if (kIsWeb) {
        await _openInWebView(context, url, title);
      } 
      else {
        // Mobile platforms - use native WebView
        await _openInWebView(context, url, title);
      }
    } catch (e) {
      print('AffiliateService error: $e');
      // Final fallback to external browser if everything fails
      try {
        await _openInExternalBrowser(url, context);
      } catch (fallbackError) {
        print('Fallback error: $fallbackError');
      }
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

  static Future<void> _openInExternalBrowser(String url, [BuildContext? context, bool showDisclaimer = true]) async {
    // Se abbiamo un context E dobbiamo mostrare il disclaimer
    if (context != null && showDisclaimer) {
      await _showExternalLinkDisclaimer(context, url);
    } else {
      // Apri direttamente senza disclaimer
      await _launchExternalUrl(url);
    }
  }

  static Future<void> _showExternalLinkDisclaimer(BuildContext context, String url) async {
    await showDialog(
      context: context,
      builder: (context) => ExternalLinkDisclaimerModal(
        url: url,
        onConfirm: () => _launchExternalUrl(url),
      ),
    );
  }

  static Future<void> _launchExternalUrl(String url) async {
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