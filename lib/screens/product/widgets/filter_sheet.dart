import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/product_query.dart';
import '../../../providers/catalog_providers.dart';
import '../../../widgets/common/app_button.dart';

Future<ProductFilter?> showFilterSheet(
  BuildContext context, {
  required String categoryId,
  required ProductFilter current,
}) => showModalBottomSheet<ProductFilter>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _FilterSheet(categoryId: categoryId, initial: current),
);

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.categoryId, required this.initial});

  final String categoryId;
  final ProductFilter initial;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late ProductFilter _draft = widget.initial;

  static const _ratings = [4.0, 3.5, 3.0];
  static const _discounts = [10, 25, 40];

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(filterOptionsProvider(widget.categoryId));
    final opts = options.valueOrNull ?? const FilterOptions();
    final hasPriceRange = opts.maxPrice > opts.minPrice;
    final range = RangeValues(
      (_draft.minPrice ?? opts.minPrice).clamp(opts.minPrice, opts.maxPrice),
      (_draft.maxPrice ?? opts.maxPrice).clamp(opts.minPrice, opts.maxPrice),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: AppSpacing.screen,
            child: Row(
              children: [
                Expanded(child: Text('Filters', style: AppTextStyles.h2)),
                TextButton(
                  onPressed: () => setState(() => _draft = ProductFilter.none),
                  child: const Text('Clear all'),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              children: [
                if (hasPriceRange) ...[
                  _Title(
                    'Price',
                    trailing:
                        '${Formatters.currency(range.start)} – ${Formatters.currency(range.end)}',
                  ),
                  RangeSlider(
                    values: range,
                    min: opts.minPrice,
                    max: opts.maxPrice,
                    divisions: 20,
                    labels: RangeLabels(
                      Formatters.currency(range.start.round()),
                      Formatters.currency(range.end.round()),
                    ),
                    onChanged: (v) => setState(() {
                      _draft = _draft.copyWith(
                        minPrice: () => v.start <= opts.minPrice ? null : v.start.roundToDouble(),
                        maxPrice: () => v.end >= opts.maxPrice ? null : v.end.roundToDouble(),
                      );
                    }),
                  ),
                  AppSpacing.gapMd,
                ],
                if (opts.brands.isNotEmpty) ...[
                  const _Title('Brand'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final brand in opts.brands)
                        // The API filters by one brand at a time.
                        ChoiceChip(
                          label: Text(brand),
                          selected: _draft.brands.contains(brand),
                          onSelected: (on) => setState(
                            () => _draft = _draft.copyWith(brands: on ? {brand} : {}),
                          ),
                        ),
                    ],
                  ),
                  AppSpacing.gapXl,
                ],
                const _Title('Customer rating'),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final r in _ratings)
                      ChoiceChip(
                        label: Text('${r.toStringAsFixed(1)}★ & above'),
                        selected: _draft.minRating == r,
                        onSelected: (on) => setState(
                          () => _draft = _draft.copyWith(minRating: () => on ? r : null),
                        ),
                      ),
                  ],
                ),
                AppSpacing.gapXl,
                const _Title('Discount'),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final d in _discounts)
                      ChoiceChip(
                        label: Text('$d% or more'),
                        selected: _draft.minDiscount == d,
                        onSelected: (on) => setState(
                          () => _draft = _draft.copyWith(minDiscount: () => on ? d : null),
                        ),
                      ),
                  ],
                ),
                AppSpacing.gapXl,
                const _Title('Availability'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Show in-stock items only', style: AppTextStyles.body),
                  value: _draft.inStockOnly,
                  onChanged: (v) => setState(() => _draft = _draft.copyWith(inStockOnly: v)),
                ),
              ],
            ),
          ),
          const Divider(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                label: _draft.activeCount == 0
                    ? 'Show results'
                    : 'Apply ${_draft.activeCount} filter${_draft.activeCount == 1 ? '' : 's'}',
                onPressed: () => Navigator.of(context).pop(_draft),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(text, style: AppTextStyles.title)),
          if (trailing != null)
            Text(trailing!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}
