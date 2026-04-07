import 'package:cross/core/theme/app_colors.dart';
import 'package:cross/features/social/widgets/avatar_url_utils.dart';
import 'package:cross/features/social/widgets/follow_action_button.dart';
import 'package:flutter/material.dart';

class SocialUserTile extends StatelessWidget {
  const SocialUserTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
    required this.actionLabel,
    required this.actionActive,
    required this.onAction,
    this.onTap,
    this.isActionLoading = false,
    this.trailing,
  });

  final String name;
  final String subtitle;
  final String avatarUrl;
  final String actionLabel;
  final bool actionActive;
  final VoidCallback? onAction;
  final VoidCallback? onTap;
  final bool isActionLoading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final canUseNetworkAvatar = isValidNetworkAvatarUrl(avatarUrl);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surfaceElevated,
              backgroundImage: canUseNetworkAvatar ? NetworkImage(avatarUrl.trim()) : null,
              child: !canUseNetworkAvatar
                  ? const Icon(Icons.person, color: AppColors.iconSecondary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 8),
            ],
            FollowActionButton(
              label: actionLabel,
              active: actionActive,
              isLoading: isActionLoading,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }
}
