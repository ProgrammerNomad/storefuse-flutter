import 'package:flutter/material.dart';

class SaleBadge extends StatelessWidget {
  const SaleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Sale',
        style: TextStyle(color: Theme.of(context).colorScheme.onError, fontSize: 11),
      ),
    );
  }
}
