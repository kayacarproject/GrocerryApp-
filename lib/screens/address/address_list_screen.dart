import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/extensions.dart';
import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/async_value_view.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeletons.dart';
import 'widgets/address_card.dart';

/// Manages saved addresses. In [selectMode] (the location picker and
/// checkout), tapping an address makes it the delivery address and closes.
class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key, this.selectMode = false});

  final bool selectMode;

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    Address address,
    AddressAction action,
  ) async {
    final notifier = ref.read(addressesProvider.notifier);
    try {
      switch (action) {
        case AddressAction.edit:
          await context.push(AppRoutes.editAddress, extra: address);
        case AddressAction.makeDefault:
          await notifier.setDefault(address.id);
          if (context.mounted) context.showSnack('Default address updated');
        case AddressAction.delete:
          final confirmed = await showConfirmDialog(
            context,
            title: 'Delete address?',
            message: 'This will remove "${address.name}" from your saved addresses.',
            confirmLabel: 'Delete',
            destructive: true,
          );
          if (!confirmed) return;
          await notifier.delete(address.id);
          if (context.mounted) context.showSnack('Address deleted');
      }
    } catch (error) {
      if (context.mounted) context.showSnack(ApiException.messageOf(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    final selected = ref.watch(selectedAddressProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(selectMode ? 'Select delivery location' : 'My addresses'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(addressesProvider.future),
        child: AsyncValueView<List<Address>>(
          value: addresses,
          onRetry: () => ref.invalidate(addressesProvider),
          loading: const ListSkeleton(count: 3, item: TileSkeleton()),
          data: (list) => list.isEmpty
              ? EmptyStateView(
                  icon: Icons.location_off_outlined,
                  title: 'No saved addresses',
                  message: 'Add an address so we know where to deliver your groceries.',
                  actionLabel: 'Add address',
                  onAction: () => context.push(AppRoutes.addAddress),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    if (selectMode) ...[
                      Text('Saved addresses', style: AppTextStyles.title),
                      AppSpacing.gapMd,
                    ],
                    for (final address in list) ...[
                      AddressCard(
                        address: address,
                        selected: selectMode && address.id == selected?.id,
                        onTap: selectMode
                            ? () {
                                ref.read(selectedAddressIdProvider.notifier).select(address.id);
                                context.pop();
                              }
                            : () => context.push(AppRoutes.editAddress, extra: address),
                        onAction: selectMode
                            ? null
                            : (action) => _handleAction(context, ref, address, action),
                      ),
                      AppSpacing.gapMd,
                    ],
                    if (selectMode)
                      TextButton.icon(
                        onPressed: () => context.push(AppRoutes.addresses),
                        icon: const Icon(Icons.edit_location_alt_outlined),
                        label: const Text('Manage addresses'),
                      ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton(
            label: 'Add new address',
            icon: Icons.add_rounded,
            variant: AppButtonVariant.outline,
            onPressed: () => context.push(AppRoutes.addAddress),
          ),
        ),
      ),
    );
  }
}
