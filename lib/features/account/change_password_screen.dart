import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/providers/providers.dart';
import '../../core/ui/show_store_error.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/loading_button.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  var _obscure = true;
  var _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final client = await ref.read(apiClientProvider.future);
      await client.bootstrapNonces();
      await client.changePassword({
        'current_password': _current.text,
        'new_password': _newPassword.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Password updated')));
        Navigator.pop(context);
      }
    } on StoreFuseApiException catch (e) {
      if (mounted) showStoreError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Change password',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _current,
              decoration: const InputDecoration(labelText: 'Current password'),
              obscureText: _obscure,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _newPassword,
              decoration: const InputDecoration(labelText: 'New password'),
              obscureText: _obscure,
              validator: (v) =>
                  v == null || v.length < 6 ? 'At least 6 characters' : null,
            ),
            TextFormField(
              controller: _confirm,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
              obscureText: _obscure,
              validator: (v) {
                if (v != _newPassword.text) return 'Passwords do not match';
                return null;
              },
            ),
            SwitchListTile(
              title: const Text('Show passwords'),
              value: !_obscure,
              onChanged: (v) => setState(() => _obscure = !v),
            ),
            const SizedBox(height: 16),
            LoadingButton(
              label: 'Update password',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
