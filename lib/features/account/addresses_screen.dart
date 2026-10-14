import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/json_helpers.dart';
import '../../core/widgets/address_fields.dart';
import '../../core/widgets/app_scaffold.dart';
import '../auth/auth_repository.dart';
import '../bootstrap/bootstrap_provider.dart';
import '../catalog/storefront_providers.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  final _billingFormKey = GlobalKey<FormState>();
  final _shippingFormKey = GlobalKey<FormState>();
  late Future<JsonMap> _future;
  bool _saving = false;

  final _billFirst = TextEditingController();
  final _billLast = TextEditingController();
  final _billAddress1 = TextEditingController();
  final _billCity = TextEditingController();
  final _billPostcode = TextEditingController();
  final _billCountry = ValueNotifier<String>('');
  final _billState = TextEditingController();
  final _billPhone = TextEditingController();

  final _shipFirst = TextEditingController();
  final _shipLast = TextEditingController();
  final _shipAddress1 = TextEditingController();
  final _shipCity = TextEditingController();
  final _shipPostcode = TextEditingController();
  final _shipCountry = ValueNotifier<String>('');
  final _shipState = TextEditingController();

  String _defaultCountryCode() {
    final store = asJsonMap(
      ref.read(bootstrapProvider).valueOrNull?.settingsData?['store'],
    );
    final code = store?['default_country']?.toString();
    return code != null && code.isNotEmpty ? code : '';
  }

  @override
  void initState() {
    super.initState();
    final fallback = _defaultCountryCode();
    _billCountry.value = fallback;
    _shipCountry.value = fallback;
    _future = _load();
  }

  @override
  void dispose() {
    _billFirst.dispose();
    _billLast.dispose();
    _billAddress1.dispose();
    _billCity.dispose();
    _billPostcode.dispose();
    _billCountry.dispose();
    _billState.dispose();
    _billPhone.dispose();
    _shipFirst.dispose();
    _shipLast.dispose();
    _shipAddress1.dispose();
    _shipCity.dispose();
    _shipPostcode.dispose();
    _shipCountry.dispose();
    _shipState.dispose();
    super.dispose();
  }

  Future<JsonMap> _load() async {
    final data = await ref.read(authRepositoryProvider).addresses();
    final fallbackCountry =
        await ref.read(checkoutDefaultCountryProvider.future);
    _applyAddress(
      data['billing'],
      billing: true,
      fallbackCountry: fallbackCountry,
    );
    _applyAddress(
      data['shipping'],
      billing: false,
      fallbackCountry: fallbackCountry,
    );
    return data;
  }

  void _applyAddress(
    dynamic raw, {
    required bool billing,
    required String fallbackCountry,
  }) {
    final a = asJsonMap(raw) ?? {};
    if (billing) {
      _billFirst.text = a['first_name']?.toString() ?? '';
      _billLast.text = a['last_name']?.toString() ?? '';
      _billAddress1.text = a['address_1']?.toString() ?? '';
      _billCity.text = a['city']?.toString() ?? '';
      _billPostcode.text = a['postcode']?.toString() ?? '';
      _billCountry.value =
          a['country']?.toString() ?? fallbackCountry;
      _billState.text = a['state']?.toString() ?? '';
      _billPhone.text = a['phone']?.toString() ?? '';
    } else {
      _shipFirst.text = a['first_name']?.toString() ?? '';
      _shipLast.text = a['last_name']?.toString() ?? '';
      _shipAddress1.text = a['address_1']?.toString() ?? '';
      _shipCity.text = a['city']?.toString() ?? '';
      _shipPostcode.text = a['postcode']?.toString() ?? '';
      _shipCountry.value =
          a['country']?.toString() ?? fallbackCountry;
      _shipState.text = a['state']?.toString() ?? '';
    }
  }

  JsonMap _billingBody() => {
    'first_name': _billFirst.text.trim(),
    'last_name': _billLast.text.trim(),
    'address_1': _billAddress1.text.trim(),
    'city': _billCity.text.trim(),
    'postcode': _billPostcode.text.trim(),
    'country': _billCountry.value.trim(),
    'state': _billState.text.trim(),
    'phone': _billPhone.text.trim(),
  };

  JsonMap _shippingBody() => {
    'first_name': _shipFirst.text.trim(),
    'last_name': _shipLast.text.trim(),
    'address_1': _shipAddress1.text.trim(),
    'city': _shipCity.text.trim(),
    'postcode': _shipPostcode.text.trim(),
    'country': _shipCountry.value.trim(),
    'state': _shipState.text.trim(),
  };

  Future<void> _saveBilling() async {
    if (!_billingFormKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateBilling(_billingBody());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Billing address saved')));
      }
    } on StoreFuseApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveShipping() async {
    if (!_shippingFormKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateShipping(_shippingBody());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Shipping address saved')));
      }
    } on StoreFuseApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Addresses',
      body: FutureBuilder<JsonMap>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Form(
                key: _billingFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Billing', style: Theme.of(context).textTheme.titleMedium),
                    TextFormField(
                      controller: _billFirst,
                      decoration: const InputDecoration(labelText: 'First name *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'First name is required' : null,
                    ),
                    TextFormField(
                      controller: _billLast,
                      decoration: const InputDecoration(labelText: 'Last name *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Last name is required' : null,
                    ),
                    TextFormField(
                      controller: _billAddress1,
                      decoration: const InputDecoration(labelText: 'Address *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                    ),
                    AddressFields(
                      countryController: _billCountry,
                      postcodeController: _billPostcode,
                      cityController: _billCity,
                      stateController: _billState,
                    ),
                    TextFormField(
                      controller: _billPhone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _saving ? null : _saveBilling,
                      child: const Text('Save billing'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: _shippingFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Shipping', style: Theme.of(context).textTheme.titleMedium),
                    TextFormField(
                      controller: _shipFirst,
                      decoration: const InputDecoration(labelText: 'First name *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'First name is required' : null,
                    ),
                    TextFormField(
                      controller: _shipLast,
                      decoration: const InputDecoration(labelText: 'Last name *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Last name is required' : null,
                    ),
                    TextFormField(
                      controller: _shipAddress1,
                      decoration: const InputDecoration(labelText: 'Address *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                    ),
                    AddressFields(
                      countryController: _shipCountry,
                      postcodeController: _shipPostcode,
                      cityController: _shipCity,
                      stateController: _shipState,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _saving ? null : _saveShipping,
                      child: const Text('Save shipping'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
