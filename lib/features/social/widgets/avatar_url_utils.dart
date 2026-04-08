bool isValidNetworkAvatarUrl(String? value) {
  if (value == null) return false;

  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return false;

  final hasHttpScheme = uri.scheme == 'http' || uri.scheme == 'https';
  return hasHttpScheme && uri.host.isNotEmpty;
}
