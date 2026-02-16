import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RefreshIcon extends StatelessWidget {
  const RefreshIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            color: AppPalette.mainColor),
        child: const Icon(
          CupertinoIcons.refresh,
          size: 20,
          color: Colors.white,
        ));
  }
}
