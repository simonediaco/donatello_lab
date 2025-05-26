import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/gift.dart';
import '../theme/app_theme.dart';

class GiftCard extends StatelessWidget {
  final Gift gift;
  final VoidCallback? onSave;
  final VoidCallback? onTap;

  const GiftCard({
    Key? key,
    required this.gift,
    this.onSave,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gift.name,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gift.description ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.subtitleColor,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '€${gift.price.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (onSave != null) ...[
                          const Spacer(),
                          IconButton(
                            onPressed: onSave,
                            icon: const Icon(Icons.bookmark_border),
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (gift.image != null)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(gift.image!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}