
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cosmic_theme.dart';

class FloatingLabelTextField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  
  // Floating label background customization
  final Color? labelBackgroundColor;
  final double labelBackgroundOpacity;
  final double labelBorderRadius;

  const FloatingLabelTextField({
    Key? key,
    required this.label,
    this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.labelBackgroundColor,
    this.labelBackgroundOpacity = 1.0,
    this.labelBorderRadius = 6.0,
  }) : super(key: key);

  @override
  State<FloatingLabelTextField> createState() => _FloatingLabelTextFieldState();
}

class _FloatingLabelTextFieldState extends State<FloatingLabelTextField>
    with TickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _labelAnimation;
  late Animation<Color?> _borderColorAnimation;
  late Animation<Color?> _labelColorAnimation;

  bool get _hasText => widget.controller?.text.isNotEmpty ?? false;
  bool get _shouldFloatLabel => _focusNode.hasFocus || _hasText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _labelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _borderColorAnimation = ColorTween(
      begin: Colors.grey.shade300,
      end: CosmicTheme.primaryAccent,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _labelColorAnimation = ColorTween(
      begin: CosmicTheme.textSecondary,
      end: CosmicTheme.primaryAccent,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Listen to controller changes
    widget.controller?.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus || _hasText) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() {});
  }

  void _onTextChange() {
    if (_hasText && !_animationController.isCompleted) {
      _animationController.forward();
    } else if (!_hasText && !_focusNode.hasFocus) {
      _animationController.reverse();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Text Field
                  TextFormField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        obscureText: widget.isPassword,
                        keyboardType: widget.keyboardType,
                        validator: widget.validator,
                        onChanged: widget.onChanged,
                        enabled: widget.enabled,
                        readOnly: widget.readOnly,
                        textInputAction: widget.textInputAction,
                        onFieldSubmitted: widget.onSubmitted,
                        onTap: widget.readOnly && widget.onTap != null ? widget.onTap : null,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: widget.enabled 
                              ? CosmicTheme.textPrimary 
                              : CosmicTheme.textSecondary,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: _shouldFloatLabel ? null : widget.label,
                          hintStyle: GoogleFonts.inter(
                            color: CosmicTheme.textSecondary.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: widget.prefixIcon,
                          suffixIcon: widget.suffixIcon,
                          filled: true,
                          fillColor: widget.enabled 
                              ? Colors.white 
                              : Colors.grey.shade50,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: widget.prefixIcon != null ? 12 : 24,
                            vertical: 22,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: _borderColorAnimation.value ?? Colors.grey.shade300,
                              width: _focusNode.hasFocus ? 2.5 : 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: CosmicTheme.primaryAccent,
                              width: 2.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: Colors.red.shade400,
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: Colors.red.shade400,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                      
                      // Animated Floating Label  
                      if (_shouldFloatLabel)
                        Positioned(
                          left: 24,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (widget.labelBackgroundColor ?? Colors.white)
                                  .withOpacity(widget.labelBackgroundOpacity),
                              borderRadius: BorderRadius.circular(widget.labelBorderRadius),
                            ),
                            child: Text(
                              widget.label,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _labelColorAnimation.value ?? CosmicTheme.primaryAccent,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      
                      // Invisible tap area for readonly fields
                      if (widget.readOnly && widget.onTap != null)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: widget.onTap,
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                    ],
                  ),
            ],
          ),
        );
      },
    );
  }
}
