import 'package:flutter/material.dart';

class OrderTrackingTimeline extends StatelessWidget {
  const OrderTrackingTimeline({
    super.key,
    required this.status,
    this.dateCreated,
    this.trackingInfo,
  });

  final String status;
  final String? dateCreated;
  final Map<String, dynamic>? trackingInfo;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final isCancelled = s == 'cancelled' || s == 'failed';
    final isRefunded = s == 'refunded';

    if (isCancelled || isRefunded) {
      final theme = Theme.of(context);
      final isErr = isCancelled;
      final bg = isErr
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.4)
          : theme.colorScheme.secondaryContainer.withValues(alpha: 0.4);
      final fg = isErr
          ? theme.colorScheme.error
          : theme.colorScheme.onSecondaryContainer;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fg.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              isErr ? Icons.cancel_outlined : Icons.assignment_return_outlined,
              color: fg,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isErr ? 'Order Cancelled' : 'Order Refunded',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isErr
                        ? 'This order has been cancelled.'
                        : 'A refund has been processed for this order.',
                    style: theme.textTheme.bodySmall?.copyWith(color: fg),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Normal stages: Placed -> Processing -> Shipped -> Delivered
    // Pending: stage 0
    // Processing / On-hold: stage 1
    // Completed: stage 3
    int currentStep = 0;
    if (s == 'completed') {
      currentStep = 3;
    } else if (s == 'processing' || s == 'on-hold') {
      currentStep = trackingInfo != null && trackingInfo!.isNotEmpty ? 2 : 1;
    }

    final steps = [
      _TimelineStep(
        title: 'Placed',
        subtitle: dateCreated ?? 'Order received',
        icon: Icons.receipt_outlined,
      ),
      const _TimelineStep(
        title: 'Processing',
        subtitle: 'Preparing items',
        icon: Icons.inventory_2_outlined,
      ),
      _TimelineStep(
        title: 'Shipped',
        subtitle: trackingInfo?['carrier']?.toString() ?? 'On the way',
        icon: Icons.local_shipping_outlined,
      ),
      const _TimelineStep(
        title: 'Delivered',
        subtitle: 'Package received',
        icon: Icons.check_circle_outline,
      ),
    ];

    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      // Step node circle
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= currentStep
                              ? primary
                              : Theme.of(context).disabledColor.withValues(alpha: 0.2),
                        ),
                        child: Icon(
                          i < currentStep ? Icons.check : steps[i].icon,
                          size: 16,
                          color: i <= currentStep
                              ? Colors.white
                              : Theme.of(context).disabledColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[i].title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: i <= currentStep
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: i <= currentStep
                              ? primary
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 24,
                    height: 2,
                    margin: const EdgeInsets.only(top: 15),
                    color: i < currentStep
                        ? primary
                        : Theme.of(context).disabledColor.withValues(alpha: 0.3),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
