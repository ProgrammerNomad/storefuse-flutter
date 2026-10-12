import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/models/json_helpers.dart';
import '../../core/widgets/address_fields.dart';
import '../../core/widgets/app_scaffold.dart';
import '../auth/auth_repository.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  late Future<JsonMap> _future;
  bool _saving = false;

  final _billFirst = TextEditingController();
  final _billLast = TextEditingController();
  final _billAddress1 = TextEditingController();
  final _billCity = TextEditingController();
  final _billPostcode = TextEditingController();
  final _billCountry = ValueNotifier<String>('IN');
  final _billState = TextEditingController();
  final _billPhone = TextEditingController();

  final _shipFirst = TextEditingController();
  final _shipLast = TextEditingController();
  final _shipAddress1 = TextEditingController();
  final _shipCity = TextEditingController();
  final _shipPostcode = TextEditingController();
  final _shipCountry = ValueNotifier<String>('IN');
  final _shipState = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    _applyAddress(data['billing'], billing: true);
    _applyAddress(data['shipping'], billing: false);
    return data;
  }

  void _applyAddress(dynamic raw, {required bool billing}) {
    final a = asJsonMap(raw) ?? {};
    if (billing) {
      _billFirst.text = a['first_name']?.toString() ?? '';
      _billLast.text = a['last_name']?.toString() ?? '';
      _billAddress1.text = a['address_1']?.toString() ?? '';
      _billCity.text = a['city']?.toString() ?? '';
      _billPostcode.text = a['postcode']?.toString() ?? '';
      _billCountry.value = a['country']?.toString() ?? 'IN';
      _billState.text = a['state']?.toString() ?? '';
      _billPhone.text = a['phone']?.toString() ?? '';
    } else {
      _shipFirst.text = a['first_name']?.toString() ?? '';
      _shipLast.text = a['last_name']?.toString() ?? '';
      _shipAddress1.text = a['address_1']?.toString() ?? '';
      _shipCity.text = a['city']?.toString() ?? '';
      _shipPostcode.text = a['postcode']?.toString() ?? '';
      _shipCountry.value = a['country']?.toString() ?? 'IN';
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
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateBilling(_billingBody());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Billing address saved')),
        );
      }
    } on StoreFuseApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveShipping() async {
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateShipping(_shippingBody());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shipping address saved')),
        );
      }
    } on StoreFuseApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
              Text('Billing', style: Theme.of(context).textTheme.titleMedium),
              TextField(
                controller: _billFirst,
                decoration: const InputDecoration(labelText: 'First name'),
              ),
              TextField(
                controller: _billLast,
                decoration: const InputDecoration(labelText: 'Last name'),
              ),
              TextField(
                controller: _billAddress1,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              AddressFields(
                countryController: _billCountry,
                postcodeController: _billPostcode,
                cityController: _billCity,
                stateController: _billState,
              ),
              TextField(
                controller: _billPhone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              FilledButton(
                onPressed: _saving ? null : _saveBilling,
                child: const Text('Save billing'),
              ),
              const SizedBox(height: 24),
              Text('Shipping', style: Theme.of(context).textTheme.titleMedium),
              TextField(
                controller: _shipFirst,
                decoration: const InputDecoration(labelText: 'First name'),
              ),
              TextField(
                controller: _shipLast,
                decoration: const InputDecoration(labelText: 'Last name'),
              ),
              TextField(
                controller: _shipAddress1,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              AddressFields(
                countryController: _shipCountry,
                postcodeController: _shipPostcode,
                cityController: _shipCity,
                stateController: _shipState,
              ),
              FilledButton(
                onPressed: _saving ? null : _saveShipping,
                child: const Text('Save shipping'),
              ),
            ],
          );
        },
      ),
    );
  }
}
