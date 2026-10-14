import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

Widget cachedThumbnail({
  required String? url,
  required double size,
  BorderRadius borderRadius = BorderRadius.zero,
}) {
  if (url == null || url.isEmpty) {
    return Icon(Icons.image_outlined, size: size * 0.6);
  }
  return ClipRRect(
    borderRadius: borderRadius,
    child: CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) =>
          Icon(Icons.broken_image_outlined, size: size * 0.6),
    ),
  );
}
