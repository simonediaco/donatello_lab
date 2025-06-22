
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cosmic_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final String? loadingText;
  final IconData? icon;
  final bool fullWidth;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.loadingText,
    this.icon,
    this.fullWidth = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return _buildOutlinedButton();
    } else {
      return _buildFilledButton();
    }
  }

  Widget _buildFilledButton() {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          gradient: isLoading 
            ? LinearGradient(
                colors: [
                  Colors.grey.shade400,
                  Colors.grey.shade500,
                ],
              )
            : CosmicTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isLoading ? [] : [
            BoxShadow(
              color: CosmicTheme.primaryAccent.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      loadingText ?? 'Loading...',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 18,
                        color: Colors.white,
                      ),
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

  Widget _buildOutlinedButton() {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isLoading 
              ? Colors.grey.shade400 
              : CosmicTheme.primaryAccent,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loadingText ?? 'Loading...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 18,
                      color: CosmicTheme.primaryAccent,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CosmicTheme.primaryAccent,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
