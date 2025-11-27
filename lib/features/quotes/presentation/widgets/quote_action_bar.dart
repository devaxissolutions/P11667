import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';

class QuoteActionBar extends ConsumerWidget {
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback? onShuffle;

  const QuoteActionBar({
    super.key,
    required this.isFavorite,
    required this.onFavorite,
    required this.onShare,
    this.onShuffle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? AppColors.error : AppColors.textSecondary,
          onTap: onFavorite,
        ),
        const SizedBox(width: 24),
        _ActionButton(
          icon: Icons.share_outlined,
          color: AppColors.textSecondary,
          onTap: onShare,
        ),
        if (onShuffle != null) ...[
          const SizedBox(width: 24),
          _ActionButton(
            icon: Icons.shuffle,
            color: AppColors.textSecondary,
            onTap: onShuffle!,
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        padding: const EdgeInsets.all(16),
        shape: const CircleBorder(side: BorderSide(color: AppColors.divider)),
      ),
    );
  }
}
