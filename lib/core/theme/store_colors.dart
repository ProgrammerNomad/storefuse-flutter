import 'package:flutter/material.dart';

const defaultStoreSeedColor = Color(0xFFE85D04);

/// Parses `#RRGGBB` or `RRGGBB` from Bridge settings; falls back on invalid input.
Color parseStoreSeedColor(String? hex, {Color fallback = defaultStoreSeedColor}) {
  if (hex == null || hex.isEmpty) return fallback;
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return fallback;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}
