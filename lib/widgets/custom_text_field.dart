import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatefulWidget {
  final String hint;
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
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const CustomTextField({
    Key? key,
    required this.hint,
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
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.enabled ? AppTheme.surfaceColor : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused 
                ? AppTheme.primaryColor 
                : (widget.enabled ? Colors.grey.shade300 : Colors.grey.shade200),
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused 
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onSubmitted,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: widget.enabled ? AppTheme.textPrimaryColor : AppTheme.textTertiaryColor,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: AppTheme.textTertiaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: widget.prefixIcon != null 
                ? Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: widget.prefixIcon,
                  )
                : null,
              suffixIcon: widget.suffixIcon != null 
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: widget.suffixIcon,
                  )
                : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.prefixIcon != null ? 0 : 20,
                vertical: widget.maxLines == 1 ? 16 : 20,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}