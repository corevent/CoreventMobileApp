/// Identifies the stored avatar without its temporary access signature.
///
/// Keep this comparison in tests only: the app must load the complete URL,
/// including its signed query parameters.
({String scheme, String authority, String path})? avatarObjectIdentity(
  String? url,
) {
  if (url == null || url.trim().isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.host.isEmpty ||
      uri.path.isEmpty ||
      uri.path == '/') {
    return null;
  }
  return (scheme: uri.scheme, authority: uri.authority, path: uri.path);
}
