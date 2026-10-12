import 'package:flutter/material.dart';

import '../../core/widgets/app_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'About',
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Text('StoreFuse mobile client v1.0.0+1'),
      ),
    );
  }
}
