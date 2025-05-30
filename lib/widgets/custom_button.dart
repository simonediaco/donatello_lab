import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultPadding = padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(16);

    if (isOutlined) {
      return _buildOutlinedButton(context, defaultPadding, defaultBorderRadius);
    } else {
      return _buildElevatedButton(context, defaultPadding, defaultBorderRadius);
    }
  }

  Widget _buildElevatedButton(BuildContext context, EdgeInsetsGeometry padding, BorderRadius borderRadius) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isLoading 
          ? LinearGradient(
              colors: [Colors.grey.shade400, Colors.grey.shade500],
            )
          : (backgroundColor != null 
              ? null 
              : AppTheme.primaryGradient),
        color: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: isLoading ? null : [
          BoxShadow(
            color: (backgroundColor ?? AppTheme.primaryColor).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: foregroundColor ?? Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        child: isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      foregroundColor ?? Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor ?? Colors.white,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor ?? Colors.white,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, EdgeInsetsGeometry padding, BorderRadius borderRadius) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor ?? AppTheme.primaryColor,
          side: BorderSide(
            color: isLoading 
              ? Colors.grey.shade400 
              : (backgroundColor ?? AppTheme.primaryColor),
            width: 1.5,
          ),
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          backgroundColor: Colors.transparent,
        ),
        child: isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor ?? AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}