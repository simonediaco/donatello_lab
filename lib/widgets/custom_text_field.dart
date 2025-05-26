import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const CustomTextField({
    Key? key,
    required this.hint,
    this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
      ),
    );
  }
}