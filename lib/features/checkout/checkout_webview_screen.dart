import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CheckoutWebViewScreen extends StatefulWidget {
  const CheckoutWebViewScreen({super.key, required this.initialUrl});

  final String initialUrl;

  @override
  State<CheckoutWebViewScreen> createState() => _CheckoutWebViewScreenState();
}

class _CheckoutWebViewScreenState extends State<CheckoutWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => _maybeComplete(url),
          onUrlChange: (change) {
            if (change.url != null) _maybeComplete(change.url!);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  void _maybeComplete(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final key = uri.queryParameters['key'];
    if (key != null && key.isNotEmpty && uri.path.contains('order-received')) {
      if (mounted) {
        context.go('/orders/confirm/$key');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
