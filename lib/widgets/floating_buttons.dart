
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cosmic_theme.dart';

class FloatingButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final String? loadingText;
  final IconData? icon;

  const FloatingButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.loadingText,
    this.icon,
  }) : super(key: key);

  @override
  State<FloatingButton> createState() => _FloatingButtonState();
}

class _FloatingButtonState extends State<FloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOutlined) {
      return _buildOutlinedButton();
    } else {
      return _buildGradientButton();
    }
  }

  Widget _buildGradientButton() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isLoading ? 1.0 : _pulseAnimation.value,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.isLoading 
                  ? LinearGradient(
                      colors: [
                        Colors.grey.shade400,
                        Colors.grey.shade500,
                      ],
                    )
                  : CosmicTheme.buttonGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: widget.isLoading ? [] : [
                  BoxShadow(
                    color: CosmicTheme.primaryAccent.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: _pulseAnimation.value - 1.0,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: widget.isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.loadingText ?? 'Loading...',
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
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
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
          ),
        );
      },
    );
  }

  Widget _buildOutlinedButton() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isLoading ? 1.0 : _scaleAnimation.value,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: widget.isLoading ? null : widget.onPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: widget.isLoading 
                    ? Colors.grey.shade400 
                    : CosmicTheme.primaryAccent,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey.shade400,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.loadingText ?? 'Loading...',
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
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: 20,
                            color: CosmicTheme.primaryAccent,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CosmicTheme.primaryAccent,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
