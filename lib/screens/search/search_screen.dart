import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/search_provider.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/product/product_list_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _controller = TextEditingController(text: ref.read(searchProvider).query);
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _searchFor(String term) {
    _controller.value = TextEditingValue(
      text: term,
      selection: TextSelection.collapsed(offset: term.length),
    );
    _focusNode.unfocus();
    ref.read(searchProvider.notifier).submit(term);
  }

  void _clear() {
    _controller.clear();
    ref.read(searchProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(searchProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: AppSpacing.lg,
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            ref.read(searchProvider.notifier).onQueryChanged(value);
            setState(() {}); // Toggle the clear button.
          },
          onSubmitted: _searchFor,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: AppStrings.searchHint,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _clear,
                  ),
            fillColor: AppColors.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: _focusNode.unfocus,
        behavior: HitTestBehavior.translucent,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: search.hasQuery
              ? _Results(key: const ValueKey('results'), state: search)
              : _Suggestions(key: const ValueKey('suggestions'), onSelect: _searchFor),
        ),
      ),
    );
  }
}

class _Suggestions extends ConsumerWidget {
  const _Suggestions({super.key, required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(searchProvider.select((s) => s.recent));
    final popular = ref.watch(popularSearchesProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            children: [
              Expanded(child: Text('Recent searches', style: AppTextStyles.title)),
              TextButton(
                onPressed: ref.read(searchProvider.notifier).clearRecent,
                child: const Text('Clear all'),
              ),
            ],
          ),
          for (final term in recent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded),
              title: Text(term, style: AppTextStyles.body),
              onTap: () => onSelect(term),
              trailing: IconButton(
                tooltip: 'Remove $term from recent searches',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => ref.read(searchProvider.notifier).removeRecent(term),
              ),
            ),
          AppSpacing.gapLg,
        ],
        Text('Popular searches', style: AppTextStyles.title),
        AppSpacing.gapMd,
        popular.when(
          loading: () => const Skeleton(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SkeletonBox(width: 70, height: 36, radius: AppRadius.pill),
                SkeletonBox(width: 90, height: 36, radius: AppRadius.pill),
                SkeletonBox(width: 60, height: 36, radius: AppRadius.pill),
                SkeletonBox(width: 80, height: 36, radius: AppRadius.pill),
              ],
            ),
          ),
          error: (error, _) => ErrorView(
            error: error,
            compact: true,
            onRetry: () => ref.invalidate(popularSearchesProvider),
          ),
          data: (terms) => Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final term in terms)
                ActionChip(
                  avatar: const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.primary),
                  label: Text(term),
                  onPressed: () => onSelect(term),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({super.key, required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    return state.results.when(
      skipLoadingOnReload: false,
      loading: () => const ListSkeleton(count: 5, item: TileSkeleton()),
      error: (error, _) => ErrorView(error: error),
      data: (products) {
        if (products.isEmpty) {
          return EmptyStateView(
            icon: Icons.search_off_rounded,
            title: 'No products found',
            message: 'We couldn\'t find anything for "${state.query.trim()}". '
                'Try a different spelling or a more general term.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 110),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: products.length + 1,
          separatorBuilder: (_, _) => AppSpacing.gapMd,
          itemBuilder: (_, i) => i == 0
              ? Semantics(
                  liveRegion: true,
                  child: Text(
                    '${products.length} result${products.length == 1 ? '' : 's'} for "${state.query.trim()}"',
                    style: AppTextStyles.bodySmall,
                  ),
                )
              : ProductListTile(product: products[i - 1]),
        );
      },
    );
  }
}
