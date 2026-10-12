import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/bootstrap/bootstrap_provider.dart';
import '../api/api_exception.dart';
import '../models/json_helpers.dart';
import '../providers/providers.dart';

class AddressFields extends ConsumerStatefulWidget {
  const AddressFields({
    super.key,
    required this.countryController,
    required this.postcodeController,
    required this.cityController,
    required this.stateController,
  });

  final ValueNotifier<String> countryController;
  final TextEditingController postcodeController;
  final TextEditingController cityController;
  final TextEditingController stateController;

  @override
  ConsumerState<AddressFields> createState() => _AddressFieldsState();
}

class _AddressFieldsState extends ConsumerState<AddressFields> {
  List<JsonMap> _countries = [];
  bool _loadingCountries = false;
  bool _lookingUp = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final modules = ref.read(bootstrapProvider).valueOrNull?.modules ?? {};
    if (modules['utils'] != true) return;
    setState(() => _loadingCountries = true);
    try {
      final client = await ref.read(apiClientProvider.future);
      final list = asJsonList((await client.getCountries()).data['countries']);
      if (mounted) setState(() => _countries = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingCountries = false);
    }
  }

  Future<void> _lookupPincode() async {
    final pin = widget.postcodeController.text.trim();
    if (pin.isEmpty) return;
    final modules = ref.read(bootstrapProvider).valueOrNull?.modules ?? {};
    if (modules['utils'] != true) return;

    setState(() => _lookingUp = true);
    try {
      final client = await ref.read(apiClientProvider.future);
      final data = (await client.lookupPincode(pin)).data;
      if (data['city'] != null) {
        widget.cityController.text = data['city'].toString();
      }
      if (data['state'] != null) {
        widget.stateController.text = data['state'].toString();
      }
      if (!mounted) return;
      if (data['is_serviceable'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This pincode may not be serviceable.')),
        );
      }
    } on StoreFuseApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = ref.watch(bootstrapProvider).valueOrNull?.modules ?? {};
    final utilsEnabled = modules['utils'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (utilsEnabled && _loadingCountries)
          const LinearProgressIndicator()
        else if (utilsEnabled && _countries.isNotEmpty)
          ValueListenableBuilder<String>(
            valueListenable: widget.countryController,
            builder: (context, selected, _) {
              final codes = _countries.map((c) => c['code']?.toString() ?? '').where((c) => c.isNotEmpty);
              final value = codes.contains(selected)
                  ? selected
                  : _countries.first['code']?.toString();
              return DropdownButtonFormField<String>(
                value: value,
                decoration: const InputDecoration(labelText: 'Country'),
                items: _countries
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['code']?.toString(),
                        child: Text(c['name']?.toString() ?? c['code']?.toString() ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) widget.countryController.value = v;
                },
              );
            },
          )
        else
          ValueListenableBuilder<String>(
            valueListenable: widget.countryController,
            builder: (context, value, _) {
              return TextFormField(
                initialValue: value,
                decoration: const InputDecoration(labelText: 'Country (ISO code)'),
                onChanged: (v) => widget.countryController.value = v.trim(),
              );
            },
          ),
        TextField(
          controller: widget.postcodeController,
          decoration: InputDecoration(
            labelText: 'Postcode / PIN',
            suffixIcon: utilsEnabled
                ? IconButton(
                    icon: _lookingUp
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    onPressed: _lookingUp ? null : _lookupPincode,
                  )
                : null,
          ),
        ),
        TextField(
          controller: widget.cityController,
          decoration: const InputDecoration(labelText: 'City'),
        ),
        TextField(
          controller: widget.stateController,
          decoration: const InputDecoration(labelText: 'State'),
        ),
      ],
    );
  }
}
