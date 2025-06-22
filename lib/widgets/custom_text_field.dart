
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cosmic_theme.dart';

class CustomTextField extends StatefulWidget {
  final String hint;
  final String? hintText;
  final String? label;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const CustomTextField({
    Key? key,
    required this.hint,
    this.hintText,
    this.label,
    this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> 
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  AnimationController? _animationController;
  Animation<double>? _labelAnimation;
  Animation<Color?>? _colorAnimation;
  
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    // Inizializza l'AnimationController dopo che il widget è montato
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController = AnimationController(
          duration: const Duration(milliseconds: 200),
          vsync: this,
        );

        _labelAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _animationController!,
          curve: Curves.easeInOut,
        ));

        _colorAnimation = ColorTween(
          begin: Colors.grey.shade400,
          end: CosmicTheme.primaryAccent,
        ).animate(_animationController!);

        if (widget.controller != null) {
          widget.controller!.addListener(_onTextChange);
          _hasText = widget.controller!.text.isNotEmpty;
          if (_hasText) {
            _animationController!.value = 1.0;
          }
        }

        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
    if (widget.controller != null) {
      widget.controller!.removeListener(_onTextChange);
    }
    _animationController?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_animationController != null) {
      if (_isFocused || _hasText) {
        _animationController!.forward();
      } else {
        _animationController!.reverse();
      }
    }
  }

  void _onTextChange() {
    if (!mounted) return;
    
    final hasText = widget.controller!.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
      
      if (_animationController != null) {
        if (_hasText || _isFocused) {
          _animationController!.forward();
        } else {
          _animationController!.reverse();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se l'AnimationController non è ancora inizializzato, mostra una versione semplice
    if (_animationController == null || _labelAnimation == null || _colorAnimation == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isFocused 
              ? CosmicTheme.primaryAccent 
              : Colors.grey.shade300,
            width: _isFocused ? 2.0 : 1.0,
          ),
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.isPassword,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: widget.enabled ? Colors.black87 : Colors.grey,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: widget.hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade400,
            ),
            suffixIcon: widget.suffixIcon,
            prefixIcon: widget.prefixIcon,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused 
                ? CosmicTheme.primaryAccent 
                : Colors.grey.shade300,
              width: _isFocused ? 2.0 : 1.0,
            ),
          ),
          child: Stack(
            children: [
              // TextField principale
              Padding(
                padding: EdgeInsets.only(
                  top: _labelAnimation!.value * 8 + 12,
                  bottom: 12,
                  left: 16,
                  right: 16,
                ),
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.isPassword,
                  keyboardType: widget.keyboardType,
                  validator: widget.validator,
                  onChanged: widget.onChanged,
                  maxLines: widget.maxLines,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  onTap: widget.onTap,
                  textInputAction: widget.textInputAction,
                  onFieldSubmitted: widget.onSubmitted,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: widget.enabled ? Colors.black87 : Colors.grey,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: null,
                    suffixIcon: widget.suffixIcon,
                    prefixIcon: widget.prefixIcon,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              
              // Label flottante
              Positioned(
                left: 16,
                top: _labelAnimation!.value * 8 + (16 - _labelAnimation!.value * 8),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: _labelAnimation!.value * 4,
                  ),
                  decoration: BoxDecoration(
                    color: _labelAnimation!.value > 0.5 
                      ? Colors.white 
                      : Colors.transparent,
                  ),
                  child: Text(
                    widget.hint,
                    style: GoogleFonts.inter(
                      fontSize: 16 - _labelAnimation!.value * 4,
                      fontWeight: FontWeight.w500,
                      color: _colorAnimation!.value ?? Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
