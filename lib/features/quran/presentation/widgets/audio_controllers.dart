
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/quran/presentation/widgets/infinate_download_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;


class AudioControllers extends StatelessWidget {
  const AudioControllers({super.key, required this.surahNumber, required this.url});
final int surahNumber;
final String url;
  @override
  Widget build(BuildContext context) {
        final provider = Provider.of<QuranProvider>(context);

    return Row(
      children: [
        GestureDetector(
          onTap: () => provider.toggleAudio(surahNumber, url),
          child: Container(
            width: 50.h,
            height: 50.h,
            decoration: const BoxDecoration(
                color: AppPalette.mainColor, shape: BoxShape.circle),
            child: (provider.isDownloading &&
                    provider.currentPlayingSurah == surahNumber)
                ? const Padding(
                    padding: EdgeInsets.all(15),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Icon(
                    (provider.isActuallyPlaying &&
                            provider.currentPlayingSurah == surahNumber)
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30.h),
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('سورة ${quran.getSurahNameArabic(surahNumber)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: AppPalette.mainColor)),
              Text(
                provider.isDownloading
                    ? 'جاري التحميل...'
                    : 'اضغط للاستماع للقارئ',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
        FutureBuilder<bool>(
          future: provider.checkSurahDownloadedUseCase(surahNumber),
          builder: (context, snapshot) {
            if (provider.isDownloading) {
              return const InfiniteDownloadIcon();
            }
            return Icon(
              (snapshot.data ?? false)
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.cloud_download,
              color: (snapshot.data ?? false)
                  ? AppPalette.mainColor
                  : Colors.grey.withValues(alpha: 0.5),
            );
          },
        ),
      ],
    );
  }
}