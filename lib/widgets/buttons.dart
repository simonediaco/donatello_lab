
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cosmic_theme.dart';

/// Primary button with gradient background
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    // MODIFICA QUI: Cambia il valore per l'altezza del pulsante (es. 40, 44, 48)
    this.height = 44,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: CosmicTheme.buttonGradient,
          // MODIFICA QUI: Aumenta il valore per più arrotondamento (es. 25, 30)
          borderRadius: BorderRadius.circular(25),
          // MODIFICA QUI: Rimuovi o riduci l'ombra per un effetto più piatto
          // boxShadow: CosmicTheme.lightShadow, // <- Commentato per effetto piatto
          boxShadow: [], // <- Nessuna ombra per effetto completamente piatto
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            // MODIFICA QUI: Deve corrispondere al borderRadius del Container sopra
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            // MODIFICA QUI: Riduce l'elevazione per un effetto più piatto
            elevation: 0, // <- Completamente piatto
            // MODIFICA QUI: Riduce il padding per evitare che il testo venga tagliato
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Secondary button with outlined style
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final Color? borderColor;
  final Color? textColor;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    // MODIFICA QUI: Stessa altezza del PrimaryButton per coerenza
    this.height = 44,
    this.borderColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? CosmicTheme.primaryAccent;
    final effectiveTextColor = textColor ?? CosmicTheme.primaryAccent;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(
            color: effectiveBorderColor,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            // MODIFICA QUI: Stesso border radius del PrimaryButton (25)
            borderRadius: BorderRadius.circular(25),
          ),
          // MODIFICA QUI: Stesso padding del PrimaryButton per coerenza
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          // MODIFICA QUI: Rimuove l'elevazione per effetto piatto
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: effectiveTextColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: effectiveTextColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Text button for less prominent actions
class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;

  const CustomTextButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.textColor,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w500,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor ?? CosmicTheme.primaryAccent,
        ),
      ),
    );
  }
}

/// Small icon button
class IconButtonCustom extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final double iconSize;

  const IconButtonCustom({
    Key? key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.size = 40,
    this.iconSize = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: iconColor ?? CosmicTheme.textPrimary,
          size: iconSize,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

/// Floating action button custom
class FloatingActionButtonCustom extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool mini;

  const FloatingActionButtonCustom({
    Key? key,
    required this.icon,
    this.onPressed,
    this.mini = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: CosmicTheme.buttonGradient,
        borderRadius: BorderRadius.circular(mini ? 16 : 20),
        boxShadow: CosmicTheme.lightShadow,
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        mini: mini,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Icon(
          icon,
          color: Colors.white,
          size: mini ? 20 : 24,
        ),
      ),
    );
  }
}

/// Grey button for secondary actions
class GreyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const GreyButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 44,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        ),
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Danger button for destructive actions
class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const DangerButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
