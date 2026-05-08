import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AudioSlider extends StatelessWidget {
  const AudioSlider({super.key, required this.surahNumber});
  final int surahNumber;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuranProvider>(context);

    return StreamBuilder<Duration?>(
      stream: provider.positionStream,
      builder: (context, snapshot) {
        final bool isSameSurah = provider.currentPlayingSurah == surahNumber;
        final position =
            isSameSurah ? (snapshot.data ?? Duration.zero) : Duration.zero;
        final duration = isSameSurah
            ? (provider.player.duration ?? Duration.zero)
            : Duration.zero;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4.h,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.r),
                activeTrackColor: AppPalette.mainColor,
                inactiveTrackColor: AppPalette.mainColor.withValues(alpha: 0.2),
                thumbColor: AppPalette.mainColor,
              ),
              child: Slider(
                value: position.inMilliseconds.toDouble(),
                max: duration.inMilliseconds.toDouble() > 0
                    ? duration.inMilliseconds.toDouble()
                    : 1.0,
                onChanged: isSameSurah
                    ? (v) => provider.seek(Duration(milliseconds: v.toInt()))
                    : null,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position),
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
                  Text(_formatDuration(duration),
                      style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }
}
