import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isLoading;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      text,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              child: isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.black,
                    )
                  : Text(text),
            ),
    );
  }
}