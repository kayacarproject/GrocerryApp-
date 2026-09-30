import 'package:flutter/material.dart';

import '../../widgets/common/empty_state_view.dart';

/// Placeholder for tabs whose feature is not released yet.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyStateView(
        icon: icon,
        title: 'Coming Soon',
        message: "We're working on it. Stay tuned!",
      ),
    );
  }
}
