import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum UploadTrackTab {
  trackInfo,
  advanced,
}

class TrackTabSwitcher extends StatelessWidget {
  final UploadTrackTab currentTab;
  final VoidCallback onTrackInfoTap;
  final VoidCallback onAdvancedTap;

  const TrackTabSwitcher({
    super.key,
    required this.currentTab,
    required this.onTrackInfoTap,
    required this.onAdvancedTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              context: context,
              title: 'Track Info',
              selected: currentTab == UploadTrackTab.trackInfo,
              onTap: onTrackInfoTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _tabButton(
              context: context,
              title: 'Advanced',
              selected: currentTab == UploadTrackTab.advanced,
              onTap: onAdvancedTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required BuildContext context,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: selected
              ? Border.all(color: AppColors.border)
              : Border.all(color: Colors.transparent),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
        ),
      ),
    );
  }
}