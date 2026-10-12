import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/json_helpers.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/address_fields.dart';
import '../../core/widgets/error_view.dart';
import '../bootstrap/bootstrap_provider.dart';
import 'checkout_webview_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  JsonMap? _config;
  StoreFuseApiException? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = await ref.read(apiClientProvider.future);
      _config = (await client.getCheckoutConfig()).data;
    } on StoreFuseApiException catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headless =
        ref.watch(bootstrapProvider).valueOrNull?.headlessCheckout ?? false;

    return AppScaffold(
      title: 'Checkout',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView.fromException(_error!, onRetry: _load)
              : headless
                  ? _HeadlessCheckoutForm(config: _config ?? {})
                  : _RedirectCheckout(),
    );
  }
}

class _RedirectCheckout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This store uses WooCommerce redirect checkout. '
              'You will complete payment in a secure WebView.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                try {
                  final client = await ref.read(apiClientProvider.future);
                  if (client.nonces.wcNonce == null) {
                    await client.bootstrapNonces();
                  }
                  final data = (await client.checkoutRedirectUrl()).data;
                  final url = data['url'] as String? ?? data['checkout_url'] as String?;
                  if (url == null || url.isEmpty) {
                    throw StoreFuseApiException(message: 'No checkout URL returned.');
                  }
                  if (!context.mounted) return;
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => CheckoutWebViewScreen(initialUrl: url),
                    ),
                  );
                } on StoreFuseApiException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                }
              },
              child: const Text('Continue to checkout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeadlessCheckoutForm extends ConsumerStatefulWidget {
  const _HeadlessCheckoutForm({required this.config});

  final JsonMap config;

  @override
  ConsumerState<_HeadlessCheckoutForm> createState() => _HeadlessCheckoutFormState();
}

class _HeadlessCheckoutFormState extends ConsumerState<_HeadlessCheckoutForm> {
  final _email = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _address1 = TextEditingController();
  final _city = TextEditingController();
  final _postcode = TextEditingController();
  final _state = TextEditingController();
  final _country = ValueNotifier<String>('IN');
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _address1.dispose();
    _city.dispose();
    _postcode.dispose();
    _state.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() => _submitting = true);
    try {
      final client = await ref.read(apiClientProvider.future);
      if (client.nonces.wcNonce == null) {
        await client.bootstrapNonces();
      }
      final result = (await client.checkoutHeadless({
        'billing': {
          'email': _email.text.trim(),
          'first_name': _firstName.text.trim(),
          'last_name': _lastName.text.trim(),
          'address_1': _address1.text.trim(),
          'city': _city.text.trim(),
          'postcode': _postcode.text.trim(),
          'state': _state.text.trim(),
          'country': _country.value.trim().isEmpty ? 'IN' : _country.value.trim(),
        },
        'payment_method': 'cod',
      })).data;
      final key = result['order_key']?.toString() ?? result['key']?.toString();
      if (key != null && context.mounted) {
        context.go('/orders/confirm/$key');
      }
    } on StoreFuseApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: _firstName, decoration: const InputDecoration(labelText: 'First name')),
        TextField(controller: _lastName, decoration: const InputDecoration(labelText: 'Last name')),
        TextField(controller: _address1, decoration: const InputDecoration(labelText: 'Address')),
        AddressFields(
          countryController: _country,
          postcodeController: _postcode,
          cityController: _city,
          stateController: _state,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _submitting ? null : _placeOrder,
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Place order'),
        ),
      ],
    );
  }
}
