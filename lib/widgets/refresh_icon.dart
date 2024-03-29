import 'package:azkar_app/utils/theme.dart';
import 'package:flutter/material.dart';

class RefreshIcon extends StatelessWidget {
  const RefreshIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50), color: mainColor),
        child: const Icon(
          Icons.refresh,
          size: 30,
          color: Colors.white,
        ));
  }
}
