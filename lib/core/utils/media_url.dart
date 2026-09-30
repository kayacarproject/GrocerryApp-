import '../config/app_config.dart';

/// The backend currently builds upload URLs from its own local address
/// (e.g. `http://localhost:3456/storage/...`), which a phone cannot reach.
/// Rewrites such URLs onto the public API origin.
abstract final class MediaUrl {
  static const _localHosts = {'localhost', '127.0.0.1', '10.0.2.2', '0.0.0.0'};

  static String resolve(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !_localHosts.contains(uri.host)) return url;
    final origin = Uri.parse(AppConfig.apiOrigin);
    return uri
        .replace(scheme: origin.scheme, host: origin.host, port: origin.port)
        .toString();
  }
}
