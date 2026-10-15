import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StoreFuseMark extends StatelessWidget {
  const StoreFuseMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'StoreFuse',
      image: true,
      child: SvgPicture.asset(
        'assets/branding/storefuse-mark.svg',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class StoreFuseBrandLockup extends StatelessWidget {
  const StoreFuseBrandLockup({
    super.key,
    required this.name,
    this.markSize = 32,
    this.textStyle,
  });

  final String name;
  final double markSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StoreFuseMark(size: markSize),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle ?? Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}
