import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/providers/providers.dart';
import '../cart/cart_provider.dart';

class CheckoutWebViewScreen extends ConsumerStatefulWidget {
  const CheckoutWebViewScreen({
    super.key,
    required this.initialUrl,
    this.handoffToken,
    this.paymentOrigins = const [],
  });
  final String initialUrl;
  final String? handoffToken;
  final List<String> paymentOrigins;

  @override
  ConsumerState<CheckoutWebViewScreen> createState() =>
      _CheckoutWebViewScreenState();
}

class _CheckoutWebViewScreenState extends ConsumerState<CheckoutWebViewScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _error;
  bool _verifying = false;
  bool _orderVerified = false;

  Uri _localUrl(Uri uri) {
    final env = ref.read(appEnvProvider);
    final base = Uri.parse(env.bridgeBaseUrl);
    const local = {'localhost', '127.0.0.1', '10.0.2.2'};
    if (!env.isProd && local.contains(uri.host) && local.contains(base.host)) {
      return uri.replace(
        host: base.host,
        port: base.hasPort ? base.port : null,
      );
    }
    return uri;
  }

  bool _storeOrigin(Uri uri) =>
      uri.origin == Uri.parse(ref.read(appEnvProvider).bridgeBaseUrl).origin;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(
                () => _error =
                    'Checkout could not load. Return to checkout to retry.',
              );
            }
          },
          onNavigationRequest: (request) async {
            final original = Uri.tryParse(request.url);
            if (original == null ||
                !{'http', 'https'}.contains(original.scheme)) {
              if (mounted) {
                setState(
                  () => _error =
                      'This payment link needs a supported payment adapter.',
                );
              }
              return NavigationDecision.prevent;
            }
            final uri = _localUrl(original);
            final allowed =
                _storeOrigin(uri) ||
                (uri.scheme == 'https' &&
                    widget.paymentOrigins.contains(uri.origin));
            if (!allowed) {
              if (mounted) {
                setState(
                  () => _error =
                      'The store has not enabled this payment destination.',
                );
              }
              return NavigationDecision.prevent;
            }
            if (await _maybeComplete(uri)) return NavigationDecision.prevent;
            if (original != uri && request.isMainFrame) {
              await _controller.loadRequest(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) {
            _maybeComplete(_localUrl(Uri.parse(url)));
          },
        ),
      );
    _load();
  }

  Future<void> _load() async {
    try {
      final uri = _localUrl(Uri.parse(widget.initialUrl));
      if (!_storeOrigin(uri) && !widget.paymentOrigins.contains(uri.origin)) {
        throw StateError('Unapproved checkout destination.');
      }
      if (widget.handoffToken != null) {
        await WebViewCookieManager().clearCookies();
        await _controller.loadRequest(
          uri,
          method: LoadRequestMethod.post,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: Uint8List.fromList(
            utf8.encode(
              'token=${Uri.encodeQueryComponent(widget.handoffToken!)}',
            ),
          ),
        );
      } else {
        await _controller.loadRequest(uri);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Unable to open checkout. Please return and try again.',
        );
      }
    }
  }

  Future<bool> _maybeComplete(Uri uri) async {
    final key = uri.queryParameters['key'];
    if (!_storeOrigin(uri) ||
        !uri.pathSegments.contains('order-received') ||
        key == null ||
        !RegExp(r'^wc_order_[a-zA-Z0-9]+$').hasMatch(key)) {
      return false;
    }
    if (_verifying) return true;
    _verifying = true;
    try {
      final client = await ref.read(apiClientProvider.future);
      await client.getOrderByKey(
        key,
      ); // Verify ownership and server order state.
      await ref.read(cartProvider.notifier).refresh();
      _orderVerified = true;
      if (mounted) context.go('/orders/confirm/$key');
    } catch (_) {
      _verifying = false;
      if (mounted) {
        setState(
          () => _error =
              'We could not verify the order yet. Check your orders before trying again.',
        );
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && mounted) {
        Navigator.of(context).pop(_orderVerified);
      }
    },
    child: Scaffold(
    appBar: AppBar(title: const Text('Secure checkout')),
    body: Column(
      children: [
        if (_progress < 100 || _verifying)
          LinearProgressIndicator(value: _verifying ? null : _progress / 100),
        if (_error != null)
          Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
        Expanded(child: WebViewWidget(controller: _controller)),
      ],
    ),
  ),
  );
}
