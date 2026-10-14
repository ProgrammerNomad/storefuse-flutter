import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/widgets/confirm_dialog.dart';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final client = await ref.read(apiClientProvider.future);
      final result = await client.accountDeletionStatus();
      final status = result.data['status']?.toString() ?? 'none';
      if (mounted && status != 'none') {
        setState(
          () => _message =
              'Deletion request: ${status.replaceAll('request-', '').replaceAll('-', ' ')}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Unable to load request status. $e');
      }
    }
  }

  Future<void> _request() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Request account deletion?',
      message:
          'The store administrator will remove your customer account and process your personal data request. Required order records may be retained under the store privacy policy.',
      confirmLabel: 'Request deletion',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      final client = await ref.read(apiClientProvider.future);
      final result = await client.requestAccountDeletion();
      if (mounted) {
        setState(
          () => _message =
              result.data['message']?.toString() ?? 'Request received.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy and account deletion')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'You can request deletion from here. The store processes requests through its privacy tools. Deleting the app alone does not delete your account.',
        ),
        const SizedBox(height: 24),
        if (_message != null) Text(_message!),
        FilledButton(
          onPressed: _busy ? null : _request,
          child: Text(_busy ? 'Sending request…' : 'Request account deletion'),
        ),
      ],
    ),
  );
}
