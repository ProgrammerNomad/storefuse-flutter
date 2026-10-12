import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/json_helpers.dart';
import '../../core/api/storefuse_client.dart';
import '../../core/providers/providers.dart';
import '../../core/ui/show_store_error.dart' show SnackBarHelper;
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/address_fields.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_button.dart';
import '../auth/auth_session_provider.dart';
import '../bootstrap/bootstrap_provider.dart';
import '../cart/cart_provider.dart';
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
                  final url = data['redirect_url'] as String? ??
                      data['checkout_url'] as String? ??
                      data['url'] as String?;
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
                  SnackBarHelper.showException(context, e);
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
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _address1 = TextEditingController();
  final _city = TextEditingController();
  final _postcode = TextEditingController();
  final _state = TextEditingController();
  final _notes = TextEditingController();
  final _country = ValueNotifier<String>('');
  final _shipFirstName = TextEditingController();
  final _shipLastName = TextEditingController();
  final _shipAddress1 = TextEditingController();
  final _shipCity = TextEditingController();
  final _shipPostcode = TextEditingController();
  final _shipState = TextEditingController();
  final _shipCountry = ValueNotifier<String>('');
  bool _sameAsBilling = true;
  bool _acceptedTerms = false;
  bool _submitting = false;
  bool _loadingMethods = true;
  String? _idempotencyKey;

  List<JsonMap> _paymentMethods = const [];
  List<JsonMap> _shippingMethods = const [];
  String? _paymentMethodId;
  String? _shippingMethodId;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final defaultCountry = widget.config['default_country']?.toString();
      if (defaultCountry != null && defaultCountry.isNotEmpty) {
        _country.value = defaultCountry;
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _address1.dispose();
    _city.dispose();
    _postcode.dispose();
    _state.dispose();
    _notes.dispose();
    _country.dispose();
    _shipFirstName.dispose();
    _shipLastName.dispose();
    _shipAddress1.dispose();
    _shipCity.dispose();
    _shipPostcode.dispose();
    _shipState.dispose();
    _shipCountry.dispose();
    super.dispose();
  }

  JsonMap _billingPayload() {
    final country = _country.value.trim();
    return {
      'email': _email.text.trim(),
      'first_name': _firstName.text.trim(),
      'last_name': _lastName.text.trim(),
      'address_1': _address1.text.trim(),
      'city': _city.text.trim(),
      'postcode': _postcode.text.trim(),
      'state': _state.text.trim(),
      'country': country.isEmpty ? 'IN' : country,
    };
  }

  JsonMap _shippingPayload() {
    if (_sameAsBilling) return _billingPayload();
    final country = _shipCountry.value.trim();
    return {
      'first_name': _shipFirstName.text.trim(),
      'last_name': _shipLastName.text.trim(),
      'address_1': _shipAddress1.text.trim(),
      'city': _shipCity.text.trim(),
      'postcode': _shipPostcode.text.trim(),
      'state': _shipState.text.trim(),
      'country': country.isEmpty ? _billingPayload()['country'] : country,
    };
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _loadingMethods = true);
    try {
      final client = await ref.read(apiClientProvider.future);
      final data = (await client.getPaymentMethods()).data;
      final methods = asJsonList(data['methods'] ?? data['payment_methods'] ?? data['items']);
      setState(() {
        _paymentMethods = methods;
        _paymentMethodId = methods.isNotEmpty
            ? methods.first['id']?.toString()
            : null;
        _loadingMethods = false;
      });
    } on StoreFuseApiException catch (e) {
      if (mounted) SnackBarHelper.showException(context, e);
      setState(() => _loadingMethods = false);
    }
  }

  Future<void> _loadShippingMethods() async {
    try {
      final client = await ref.read(apiClientProvider.future);
      if (client.nonces.wcNonce == null) {
        await client.bootstrapNonces();
      }
      final billing = _billingPayload();
      final data = (await client.getShippingMethods(address: billing)).data;
      final methods = shippingMethodsFromCheckoutData(data);
      setState(() {
        _shippingMethods = methods;
        _shippingMethodId = methods.isNotEmpty
            ? methods.first['id']?.toString()
            : null;
      });
    } on StoreFuseApiException catch (e) {
      if (mounted) SnackBarHelper.showException(context, e);
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      SnackBarHelper.showMessage(context, 'Please accept the terms to continue.');
      return;
    }
    if (_paymentMethodId == null || _paymentMethodId!.isEmpty) {
      SnackBarHelper.showMessage(context, 'Select a payment method.');
      return;
    }
    if (_shippingMethods.isNotEmpty &&
        (_shippingMethodId == null || _shippingMethodId!.isEmpty)) {
      SnackBarHelper.showMessage(context, 'Select a shipping method.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final client = await ref.read(apiClientProvider.future);
      if (client.nonces.wcNonce == null) {
        await client.bootstrapNonces();
      }
      final billing = _billingPayload();
      final shipping = _shippingPayload();
      _idempotencyKey ??= StoreFuseApiClient.generateIdempotencyKey();
      final result = (await client.checkoutHeadless(
        {
          'billing': billing,
          'shipping': shipping,
          'ship_to_different_address': !_sameAsBilling,
          'payment_method': _paymentMethodId,
          if (_shippingMethodId != null) 'shipping_method': [_shippingMethodId],
          if (_notes.text.trim().isNotEmpty) ...{
            'order_notes': _notes.text.trim(),
            'order_comments': _notes.text.trim(),
          },
        },
        idempotencyKey: _idempotencyKey,
      )).data;

      final payment = asJsonMap(result['payment_result']);
      final paymentType = payment?['type']?.toString();
      final paymentUrl = payment?['redirect_url']?.toString();
      if (paymentType == 'redirect' &&
          paymentUrl != null &&
          paymentUrl.isNotEmpty &&
          context.mounted) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => CheckoutWebViewScreen(initialUrl: paymentUrl),
          ),
        );
      }

      final key = result['order_key']?.toString() ?? result['key']?.toString();
      if (key != null && context.mounted) {
        context.go('/orders/confirm/$key');
      }
    } on StoreFuseApiException catch (e) {
      SnackBarHelper.showException(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);
    final cart = ref.watch(cartProvider).data;
    final lines = asJsonList(cart?['items']);

    if (_loadingMethods) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!loggedIn)
            Card(
              child: ListTile(
                title: const Text('Have an account?'),
                subtitle: const Text('Sign in for faster checkout'),
                trailing: TextButton(
                  onPressed: () => context.push('/auth/login'),
                  child: const Text('Sign in'),
                ),
              ),
            ),
          if (lines.isNotEmpty) ...[
            Text('Order summary', style: Theme.of(context).textTheme.titleMedium),
            ...lines.map((line) {
              return ListTile(
                dense: true,
                title: Text(line['name']?.toString() ?? 'Item'),
                subtitle: Text('Qty ${line['quantity'] ?? 1}'),
                trailing: Text(
                  asJsonMap(line['totals'])?['formatted']?.toString() ??
                      priceFormatted(asJsonMap(line['price'])),
                ),
              );
            }),
            if (cart?['totals'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Total: ${asJsonMap(cart!['totals'])?['total']?['formatted'] ?? ''}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            const Divider(),
          ],
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return 'Email is required';
              if (!t.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          TextFormField(
            controller: _firstName,
            decoration: const InputDecoration(labelText: 'First name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          TextFormField(
            controller: _lastName,
            decoration: const InputDecoration(labelText: 'Last name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          TextFormField(
            controller: _address1,
            decoration: const InputDecoration(labelText: 'Address'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          AddressFields(
            countryController: _country,
            postcodeController: _postcode,
            cityController: _city,
            stateController: _state,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loadShippingMethods,
              child: const Text('Load shipping options'),
            ),
          ),
          SwitchListTile(
            value: _sameAsBilling,
            onChanged: (v) => setState(() => _sameAsBilling = v),
            title: const Text('Shipping same as billing'),
          ),
          if (!_sameAsBilling) ...[
            Text('Shipping address', style: Theme.of(context).textTheme.titleSmall),
            TextFormField(
              controller: _shipFirstName,
              decoration: const InputDecoration(labelText: 'Shipping first name'),
              validator: (v) =>
                  !_sameAsBilling && (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _shipLastName,
              decoration: const InputDecoration(labelText: 'Shipping last name'),
              validator: (v) =>
                  !_sameAsBilling && (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _shipAddress1,
              decoration: const InputDecoration(labelText: 'Shipping address'),
              validator: (v) =>
                  !_sameAsBilling && (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            AddressFields(
              countryController: _shipCountry,
              postcodeController: _shipPostcode,
              cityController: _shipCity,
              stateController: _shipState,
            ),
          ],
          if (_paymentMethods.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Payment method', style: Theme.of(context).textTheme.titleSmall),
            ..._paymentMethods.map((m) {
              final id = m['id']?.toString() ?? '';
              return RadioListTile<String>(
                value: id,
                groupValue: _paymentMethodId,
                onChanged: (v) => setState(() => _paymentMethodId = v),
                title: Text(m['title']?.toString() ?? m['label']?.toString() ?? id),
              );
            }),
          ],
          if (_shippingMethods.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Shipping method', style: Theme.of(context).textTheme.titleSmall),
            ..._shippingMethods.map((m) {
              final id = m['id']?.toString() ?? '';
              return RadioListTile<String>(
                value: id,
                groupValue: _shippingMethodId,
                onChanged: (v) => setState(() => _shippingMethodId = v),
                title: Text(m['label']?.toString() ?? m['title']?.toString() ?? id),
                subtitle: m['cost'] != null ? Text(m['cost'].toString()) : null,
              );
            }),
          ],
          TextFormField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Order notes (optional)'),
            maxLines: 2,
          ),
          CheckboxListTile(
            value: _acceptedTerms,
            onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
            title: const Text('I agree to the terms and conditions'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          LoadingButton(
            label: 'Place order',
            loading: _submitting,
            onPressed: _placeOrder,
          ),
        ],
      ),
    );
  }
}
