import 'dart:ui';

import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/quran/presentation/widgets/audio_controllers.dart';
import 'package:azkar_app/features/quran/presentation/widgets/audio_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/quran.dart' as quran;

class AudioPlayerCard extends StatelessWidget {
  const AudioPlayerCard({super.key, required this.surahNumber});
  final int surahNumber;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String url = quran.getAudioURLBySurah(surahNumber);
    return Container(
      key: const ValueKey('floating_audio_player'),
      height: 155.h,
      margin: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: AppPalette.mainColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: EdgeInsets.all(15.h),
            child: Column(
              children: [
                AudioSlider(surahNumber: surahNumber),
                AudioControllers(surahNumber: surahNumber, url: url),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
