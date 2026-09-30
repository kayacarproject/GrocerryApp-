import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/address.dart';
import '../../../widgets/common/app_card.dart';

extension AddressLabelIcon on AddressLabel {
  IconData get icon => switch (this) {
    AddressLabel.home => Icons.home_rounded,
    AddressLabel.work => Icons.work_rounded,
    AddressLabel.other => Icons.location_on_rounded,
  };
}

enum AddressAction { edit, makeDefault, delete }

class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    this.selected = false,
    this.onTap,
    this.onAction,
  });

  final Address address;
  final bool selected;
  final VoidCallback? onTap;
  final ValueChanged<AddressAction>? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: AppCard(
        onTap: onTap,
        borderColor: selected ? AppColors.primary : AppColors.border,
        color: selected ? AppColors.primaryLight : AppColors.surface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: selected ? AppColors.surface : AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(address.label.icon, color: AppColors.primary, size: 20),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.name, style: AppTextStyles.title),
                      if (address.isDefault) ...[
                        AppSpacing.gapSm,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: AppRadius.xsAll,
                          ),
                          child: Text(
                            'DEFAULT',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF92400E),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  AppSpacing.gapXs,
                  Text(address.displayAddress, style: AppTextStyles.bodySmall),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('Phone: ${address.phone}', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            if (onAction != null)
              PopupMenuButton<AddressAction>(
                tooltip: 'Address options',
                onSelected: onAction,
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: AddressAction.edit, child: Text('Edit')),
                  if (!address.isDefault)
                    const PopupMenuItem(
                      value: AddressAction.makeDefault,
                      child: Text('Set as default'),
                    ),
                  const PopupMenuItem(
                    value: AddressAction.delete,
                    child: Text('Delete', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              )
            else if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
