import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

class RefreshIcon extends StatelessWidget {
  const RefreshIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50), color: AppPalette.mainColor),
        child: const Icon(
          Icons.refresh,
          size: 30,
          color: Colors.white,
        ));
  }
}
