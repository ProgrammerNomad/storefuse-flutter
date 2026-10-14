import 'package:flutter/material.dart';

import '../../core/models/json_helpers.dart';

/// Resolves a variable product variation from selected attribute options.
class ProductVariationSelector extends StatefulWidget {
  const ProductVariationSelector({
    super.key,
    required this.product,
    required this.onChanged,
  });

  final JsonMap product;
  final void Function(int? variationId, JsonMap? variation, bool inStock)
  onChanged;

  @override
  State<ProductVariationSelector> createState() =>
      _ProductVariationSelectorState();
}

class _ProductVariationSelectorState extends State<ProductVariationSelector> {
  final Map<String, String> _selected = {};

  @override
  void initState() {
    super.initState();
    _notify();
  }

  List<JsonMap> get _attributes => asJsonList(widget.product['attributes']);

  List<JsonMap> get _variations => asJsonList(widget.product['variations']);

  bool get _isVariable =>
      widget.product['type']?.toString() == 'variable' &&
      _variations.isNotEmpty;

  List<String> _optionLabels(JsonMap attr) {
    final raw = attr['options'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  void _notify() {
    if (!_isVariable) {
      widget.onChanged(null, null, productInStock(widget.product));
      return;
    }
    JsonMap? match;
    for (final v in _variations) {
      final attrs = v['attributes'];
      if (attrs is! Map) continue;
      var ok = true;
      for (final entry in _selected.entries) {
        final key = entry.key;
        final val = entry.value;
        final variationVal =
            attrs[key]?.toString() ?? attrs['attribute_$key']?.toString();
        if (variationVal == null || variationVal.isEmpty) continue;
        if (variationVal.toLowerCase() != val.toLowerCase()) {
          ok = false;
          break;
        }
      }
      if (ok && _selected.isNotEmpty) {
        match = v;
        break;
      }
    }
    if (match == null) {
      widget.onChanged(null, null, false);
      return;
    }
    final id = parseInt(match['id']);
    final inStock =
        match['stock_status']?.toString() == 'instock' ||
        match['stock_status']?.toString() == 'onbackorder';
    widget.onChanged(id, match, inStock);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVariable) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final attr in _attributes) ...[
          Text(
            attr['name']?.toString() ?? 'Option',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opt in _optionLabels(attr))
                ChoiceChip(
                  label: Text(opt),
                  selected:
                      _selected[attr['slug']?.toString() ??
                          attr['name']?.toString() ??
                          ''] ==
                      opt,
                  onSelected: (_) {
                    final key =
                        attr['slug']?.toString() ??
                        attr['name']?.toString() ??
                        '';
                    setState(() => _selected[key] = opt);
                    _notify();
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
