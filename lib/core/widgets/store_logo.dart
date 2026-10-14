import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class StoreLogo extends StatelessWidget {
  const StoreLogo({
    super.key,
    required this.logoUrl,
    this.height = 32,
    this.fallback,
  });

  final String? logoUrl;
  final double height;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null || logoUrl!.isEmpty) {
      return fallback ?? const SizedBox.shrink();
    }
    return CachedNetworkImage(
      imageUrl: logoUrl!,
      height: height,
      fit: BoxFit.contain,
      errorWidget: (_, _, _) => fallback ?? const SizedBox.shrink(),
    );
  }
}
