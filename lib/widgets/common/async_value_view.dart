import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_view.dart';

/// Standard loading / error / data switch for [AsyncValue]s.
/// Keeps showing existing data during pull-to-refresh.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    required this.loading,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: value.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: false,
        data: (d) => KeyedSubtree(key: const ValueKey('data'), child: data(d)),
        loading: () =>
            KeyedSubtree(key: const ValueKey('loading'), child: loading),
        error: (error, _) => KeyedSubtree(
          key: const ValueKey('error'),
          child: ErrorView(error: error, onRetry: onRetry),
        ),
      ),
    );
  }
}
