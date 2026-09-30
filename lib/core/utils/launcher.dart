import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'extensions.dart';

/// Opens the dialer or mail app, with a friendly message if unavailable.
abstract final class Launcher {
  static Future<void> call(BuildContext context, String phone) =>
      _open(context, Uri(scheme: 'tel', path: phone), 'Unable to open the dialer');

  static Future<void> email(BuildContext context, String address, {String? subject}) => _open(
    context,
    Uri(
      scheme: 'mailto',
      path: address,
      query: subject == null ? null : 'subject=${Uri.encodeComponent(subject)}',
    ),
    'No email app found',
  );

  static Future<void> _open(BuildContext context, Uri uri, String failure) async {
    bool opened;
    try {
      opened = await launchUrl(uri);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) context.showSnack(failure, isError: true);
  }
}
