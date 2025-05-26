import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecipientAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;

  const RecipientAvatar({
    Key? key,
    this.imageUrl,
    required this.name,
    this.size = 80,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor.withOpacity(0.3),
      ),
      child: imageUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildInitials(),
                errorWidget: (context, url, error) => _buildInitials(),
              ),
            )
          : _buildInitials(),
    );
  }

  Widget _buildInitials() {
    final initials = name.split(' ').map((word) => word.isNotEmpty ? word[0] : '').join('').toUpperCase();
    return Center(
      child: Text(
        initials.length > 2 ? initials.substring(0, 2) : initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}