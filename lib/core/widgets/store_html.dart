import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class StoreHtml extends StatelessWidget {
  const StoreHtml({super.key, required this.html, this.textStyle});

  final String html;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    if (html.trim().isEmpty) return const SizedBox.shrink();
    return HtmlWidget(
      html,
      textStyle: textStyle ?? Theme.of(context).textTheme.bodyMedium,
    );
  }
}
