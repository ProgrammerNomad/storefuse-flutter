/// Holds WP REST and WC Store API nonces from Bridge responses.
class NonceStore {
  String? wpNonce;
  String? wcNonce;
  String? cartToken;

  void updateFromHeaders(Map<String, List<String>> headers) {
    final wc = _firstHeader(headers, 'x-wc-nonce');
    if (wc != null) wcNonce = wc;
    final token = _firstHeader(headers, 'x-storefuse-cart-token');
    if (token != null) cartToken = token;
  }

  void updateFromJson(Map<String, dynamic>? json) {
    if (json == null) return;
    final wp = json['nonce'] as String?;
    final wc = json['cart_nonce'] as String?;
    if (wp != null && wp.isNotEmpty) wpNonce = wp;
    if (wc != null && wc.isNotEmpty) wcNonce = wc;
  }

  String? _firstHeader(Map<String, List<String>> headers, String name) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == name && entry.value.isNotEmpty) {
        return entry.value.first;
      }
    }
    return null;
  }
}
