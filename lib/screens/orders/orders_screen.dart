import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/router/app_routes.dart';
import '../../models/order.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/common/async_value_view.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeletons.dart';
import '../../widgets/order/order_card.dart';

enum _OrderFilter {
  all('All'),
  active('Active'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const _OrderFilter(this.label);
  final String label;

  bool matches(Order order) => switch (this) {
    _OrderFilter.all => true,
    _OrderFilter.active => order.status.isActive,
    _OrderFilter.delivered => order.status == OrderStatus.delivered,
    _OrderFilter.cancelled => order.status == OrderStatus.cancelled,
  };
}

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  _OrderFilter _filter = _OrderFilter.all;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My orders'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              children: [
                for (final f in _OrderFilter.values) ...[
                  ChoiceChip(
                    label: Text(f.label),
                    selected: _filter == f,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                  AppSpacing.gapSm,
                ],
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ordersProvider.future),
        child: AsyncValueView<List<Order>>(
          value: orders,
          onRetry: () => ref.invalidate(ordersProvider),
          loading: const ListSkeleton(count: 3),
          data: (all) {
            final list = all.where(_filter.matches).toList();
            if (list.isEmpty) {
              return EmptyStateView(
                icon: Icons.receipt_long_outlined,
                title: _filter == _OrderFilter.all ? 'No orders yet' : 'No ${_filter.label.toLowerCase()} orders',
                message: _filter == _OrderFilter.all
                    ? 'Your orders will show up here once you place one.'
                    : 'Try a different filter to see your other orders.',
                actionLabel: _filter == _OrderFilter.all ? 'Start Shopping' : null,
                onAction: _filter == _OrderFilter.all ? () => context.go(AppRoutes.home) : null,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: list.length,
              separatorBuilder: (_, _) => AppSpacing.gapMd,
              itemBuilder: (_, i) => OrderCard(order: list[i]),
            );
          },
        ),
      ),
    );
  }
}
