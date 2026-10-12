import 'package:flutter/material.dart';

import '../models/json_helpers.dart';

class PriceText extends StatelessWidget {
  const PriceText({super.key, required this.price, this.style});

  final JsonMap? price;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      priceFormatted(price),
      style: style ?? Theme.of(context).textTheme.titleMedium,
    );
  }
}
