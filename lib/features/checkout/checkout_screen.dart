import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/json_helpers.dart';
import '../../core/providers/providers.dart';
import '../../core/ui/show_store_error.dart' show SnackBarHelper;
import '../../core/widgets/app_scaffold.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/price_text.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/guest_login_prompt.dart';
import '../../core/widgets/loading_button.dart';

import '../bootstrap/app_ui_config.dart';
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
          : headless &&
                _config?['native_fields_supported'] != false &&
                _config?['requires_login'] != true
          ? _HeadlessCheckoutForm(config: _config ?? {})
          : _RedirectCheckout(
              label: _config?['checkout_redirect_label']?.toString(),
            ),
    );
  }
}

class _RedirectCheckout extends ConsumerWidget {
  const _RedirectCheckout({this.label});
  final String? label;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Complete your purchase securely with the store’s available payment options.',
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
                  final url =
                      data['redirect_url'] as String? ??
                      data['checkout_url'] as String? ??
                      data['url'] as String?;
                  if (url == null || url.isEmpty) {
                    throw StoreFuseApiException(
                      message: 'No checkout URL returned.',
                    );
                  }
                  if (!context.mounted) return;
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => CheckoutWebViewScreen(
                        initialUrl: data['handoff_url']?.toString() ?? url,
                        handoffToken: data['handoff_token']?.toString(),
                        paymentOrigins: (data['payment_origins'] as List? ?? [])
                            .cast<String>(),
                      ),
                    ),
                  );
                } on StoreFuseApiException catch (e) {
                  if (!context.mounted) return;
                  SnackBarHelper.showException(context, e);
                }
              },
              child: Text(label ?? 'Continue to checkout'),
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
  ConsumerState<_HeadlessCheckoutForm> createState() =>
      _HeadlessCheckoutFormState();
}

class _HeadlessCheckoutFormState extends ConsumerState<_HeadlessCheckoutForm> {
  final _formKey = GlobalKey<FormState>();
  final _billing = <String, String>{};
  final _shipping = <String, String>{};
  final _selectedShipping = <int, String>{};
  List<JsonMap> _methods = [];
  List<JsonMap> _allPaymentMethods = [];
  List<JsonMap> _packages = [];
  JsonMap? _quote;
  String? _payment;
  String _notes = '';
  bool _different = false;
  bool _terms = false;
  bool _busy = true;
  String? _error;
  String? _quotedAddress;
  String? _quoteToken;
  JsonMap? _pendingBody;
  bool get _needsShipping => widget.config['has_shipping'] == true;
  bool get _needsTerms {
    if (widget.config['terms_checkbox_enabled'] == true) return true;
    return parseInt(widget.config['terms_and_conditions_page_id']) > 0;
  }

  String? get _termsUrl {
    final url = widget.config['terms_url']?.toString();
    if (url != null && url.startsWith('http')) return url;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final client = await ref.read(apiClientProvider.future);
      final me = (await client.authMe()).data;
      for (final entry in (asJsonMap(me['billing']) ?? {}).entries) {
        _billing[entry.key] = entry.value?.toString() ?? '';
      }
      for (final entry in (asJsonMap(me['shipping']) ?? {}).entries) {
        _shipping[entry.key] = entry.value?.toString() ?? '';
      }
      _billing['country'] = _billing['country']?.isNotEmpty == true
          ? _billing['country']!
          : widget.config['default_country']?.toString() ?? '';
      _shipping['country'] = _shipping['country']?.isNotEmpty == true
          ? _shipping['country']!
          : _billing['country']!;
      _allPaymentMethods = asJsonList(
        (await client.getPaymentMethods()).data['methods'],
      );
      _methods = _filterHeadlessMethods(_allPaymentMethods);
      _payment = _methods.firstOrNull?['id']?.toString();
      final pending = await client.pendingCheckout();
      if (pending != null) {
        final body = asJsonMap(pending['body']) ?? {};
        _pendingBody = body;
        _billing.addAll(
          (asJsonMap(body['billing']) ?? {}).map(
            (k, v) => MapEntry(k, v.toString()),
          ),
        );
        _shipping.addAll(
          (asJsonMap(body['shipping']) ?? {}).map(
            (k, v) => MapEntry(k, v.toString()),
          ),
        );
        _different = body['ship_to_different_address'] == true;
        _payment = body['payment_method']?.toString() ?? _payment;
        _notes = body['order_notes']?.toString() ?? '';
        _terms = body['terms'] == true;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<JsonMap> _filterHeadlessMethods(List<JsonMap> methods) {
    final allowed = asStringList(widget.config['headless_gateways']).toSet();
    if (allowed.isEmpty) return methods;
    return methods.where((m) => allowed.contains(m['id']?.toString())).toList();
  }

  List<JsonMap> _unsupportedHeadlessMethods(List<JsonMap> all) {
    final allowed = _filterHeadlessMethods(all);
    final allowedIds = allowed.map((m) => m['id']).toSet();
    return all.where((m) => !allowedIds.contains(m['id'])).toList();
  }

  JsonMap _body() => {
    'quote_token': _quoteToken,
    'billing': _billing,
    'shipping': _different ? _shipping : _billing,
    'ship_to_different_address': _different,
    'payment_method': _payment,
    'shipping_method': [
      for (final package in _packages)
        _selectedShipping[parseInt(package['index'])] ?? '',
    ],
    'order_notes': _notes,
    'terms': _terms,
  };

  String _addressSignature() => jsonEncode([_billing, _shipping, _different]);

  void _changed() {
    setState(() {
      _quote = null;
      _quotedAddress = null;
    });
  }

  Future<void> _calculate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = await ref.read(apiClientProvider.future);
      final data = (await client.checkoutQuote(_body())).data;
      _packages = asJsonList(data['packages']);
      _selectedShipping.clear();
      for (final package in _packages) {
        final methods = asJsonList(package['methods']);
        final chosen =
            methods.where((m) => m['is_selected'] == true).firstOrNull ??
            methods.firstOrNull;
        if (chosen != null) {
          _selectedShipping[parseInt(package['index'])] = chosen['id']
              .toString();
        }
      }
      _quote = asJsonMap(data['cart']);
      _quoteToken = data['quote_token']?.toString();
      _quotedAddress = _addressSignature();
      _allPaymentMethods = asJsonList(
        (await client.getPaymentMethods()).data['methods'],
      );
      _methods = _filterHeadlessMethods(_allPaymentMethods);
      if (!_methods.any((m) => m['id'] == _payment)) {
        _payment = _methods.firstOrNull?['id']?.toString();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recover() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = await ref.read(apiClientProvider.future);
      final data = (await client.checkoutHeadless(_pendingBody!)).data;
      final key = await client.resolveCheckoutOrderKey(data);
      if (key == null) {
        throw StateError(
          'Order recovery is pending. Contact the store before placing another order.',
        );
      }
      await ref.read(cartProvider.notifier).refresh();
      if (mounted) context.go('/orders/confirm/$key');
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _placeOrder() async {
    if (_pendingBody != null) {
      await _recover();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if ((_needsTerms && !_terms) || _payment == null) {
      setState(
        () => _error = 'Select a payment method and accept the store terms.',
      );
      return;
    }
    if (_quotedAddress != _addressSignature() ||
        _quote == null ||
        (_needsShipping &&
            (_packages.isEmpty ||
                _selectedShipping.length != _packages.length))) {
      setState(
        () => _error =
            'Review delivery options and the updated total before placing your order.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = await ref.read(apiClientProvider.future);
      final data = (await client.checkoutHeadless(_body())).data;
      final key = await client.resolveCheckoutOrderKey(data);
      if (key == null) {
        throw StateError(
          'Order recovery is pending. Check your orders before retrying.',
        );
      }
      await ref.read(cartProvider.notifier).refresh();
      if (mounted) context.go('/orders/confirm/$key');
    } catch (e) {
      _error = e.toString();
      final client = await ref.read(apiClientProvider.future);
      _pendingBody = asJsonMap((await client.pendingCheckout())?['body']);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Widget> _addressFields(String kind, Map<String, String> values) {
    final fields = asJsonList(widget.config['${kind}_fields']);
    final countries =
        asJsonMap(
          widget.config[kind == 'shipping'
              ? 'shipping_countries'
              : 'allowed_countries'],
        ) ??
        {};
    final stateMap =
        asJsonMap(
          widget.config[kind == 'shipping' ? 'shipping_states' : 'states'],
        ) ??
        {};
    final country = values['country'] ?? '';
    final states = asJsonMap(stateMap[country]) ?? {};
    final locale =
        asJsonMap(asJsonMap(widget.config['country_locale'])?[country]) ?? {};
    return fields.map((original) {
      final name = original['name']?.toString() ?? '';
      final field = {...original, ...?asJsonMap(locale[name])};
      if (field['hidden'] == true) return const SizedBox.shrink();
      final required = field['required'] == true;
      final options = name == 'country'
          ? countries
          : name == 'state'
          ? states
          : asJsonMap(field['options']) ?? {};
      final label = '${field['label'] ?? name}${required ? ' *' : ''}';
      String? validate(String? value) =>
          required && (value == null || value.trim().isEmpty)
          ? 'Required'
          : null;
      if (options.isNotEmpty) {
        return DropdownButtonFormField<String>(
          key: ValueKey('$kind-$name-$country-${values[name]}'),
          initialValue: options.containsKey(values[name]) ? values[name] : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          validator: validate,
          items: options.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value.toString()),
                ),
              )
              .toList(),
          onChanged: (value) {
            values[name] = value ?? '';
            if (name == 'country') values['state'] = '';
            _changed();
          },
        );
      }
      return TextFormField(
        key: ValueKey('$kind-$name-$country'),
        initialValue: values[name] ?? '',
        decoration: InputDecoration(labelText: label),
        validator: validate,
        keyboardType: name == 'email'
            ? TextInputType.emailAddress
            : name == 'phone'
            ? TextInputType.phone
            : TextInputType.streetAddress,
        textInputAction: TextInputAction.next,
        onChanged: (value) {
          values[name] = value.trim();
          _changed();
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totals = asJsonMap(_quote?['totals']) ?? {};
    final checkoutUi = ref.watch(appUiConfigProvider).checkoutScreen;
    return AbsorbPointer(
      absorbing: _busy,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (checkoutUi.showGuestPrompt)
              const GuestLoginPromptBanner(
                message: 'Sign in to use your saved addresses and speed up checkout.',
              ),
            if (_pendingBody != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'An earlier checkout did not finish confirming. Recover that order before making another purchase.',
                      ),
                      FilledButton(
                        onPressed: _recover,
                        child: const Text('Recover previous order'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Text(
              'Billing address',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ..._addressFields('billing', _billing),
            if (_needsShipping)
              SwitchListTile(
                title: const Text('Deliver to a different address'),
                value: _different,
                onChanged: (value) {
                  _different = value;
                  _changed();
                },
              ),
            if (_needsShipping && _different)
              ..._addressFields('shipping', _shipping),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _calculate,
              child: const Text('Review delivery and total'),
            ),
            for (final package in _packages) ...[
              Text('Shipment ${parseInt(package['index']) + 1}'),
              if (asJsonList(package['methods']).isEmpty)
                const Text('Delivery is unavailable for this address.'),
              for (final method in asJsonList(package['methods']))
                ListTile(
                  title: Text(method['label']?.toString() ?? ''),
                  subtitle: PriceText(price: asJsonMap(method['cost'])),
                  leading: Icon(
                    _selectedShipping[parseInt(package['index'])] ==
                            method['id']
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  onTap: () async {
                    _selectedShipping[parseInt(package['index'])] = method['id']
                        .toString();
                    await _calculate();
                  },
                ),
            ],
            if (_quote != null) ...[
              for (final key in [
                'subtotal',
                'shipping',
                'discount',
                'tax',
                'total',
              ])
                if (totals[key] != null)
                  ListTile(
                    title: Text(key.replaceAll('_', ' ')),
                    trailing: PriceText(price: asJsonMap(totals[key])),
                  ),
            ],
            if (_methods.isEmpty && _pendingBody == null)
              _RedirectCheckout(
                label: widget.config['checkout_redirect_label']?.toString(),
              ),
            for (final method in _methods)
              ListTile(
                title: Text(method['title']?.toString() ?? ''),
                leading: Icon(
                  _payment == method['id']
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                onTap: () => setState(() => _payment = method['id'].toString()),
              ),
            for (final method in _unsupportedHeadlessMethods(_allPaymentMethods))
              ListTile(
                enabled: false,
                title: Text(method['title']?.toString() ?? ''),
                subtitle: const Text(
                  'Complete this payment on the store website checkout.',
                ),
                leading: const Icon(Icons.lock_outline),
              ),
            if (widget.config['order_notes_enabled'] == true)
              TextFormField(
                initialValue: _notes,
                decoration: const InputDecoration(
                  labelText: 'Order notes (optional)',
                ),
                onChanged: (v) => _notes = v,
              ),
            if (_needsTerms)
              CheckboxListTile(
                value: _terms,
                onChanged: (v) => setState(() => _terms = v ?? false),
                title: _termsUrl == null
                    ? const Text('I agree to the terms and conditions')
                    : Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('I agree to the '),
                          InkWell(
                            onTap: () => launchUrl(
                              Uri.parse(_termsUrl!),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Text(
                              'terms and conditions',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                            ),
                          ),
                        ],
                      ),
              ),
            for (final entry in {
              if (_termsUrl == null)
                'Terms and conditions': widget.config['terms_url'],
              'Privacy policy': widget.config['privacy_url'],
            }.entries)
              if (entry.value is String &&
                  entry.value.toString().startsWith('http'))
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(entry.value.toString()),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(entry.key),
                ),
            LoadingButton(
              label: 'Place order',
              loading: _busy,
              onPressed: _placeOrder,
            ),
          ],
        ),
      ),
    );
  }
}
