import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/quran/presentation/providers/quran_provider.dart';
import 'package:azkar_app/features/quran/presentation/utils/quran_audio_source.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// شريط استماع مضغوط أسفل القارئ: زر تشغيل، اسم السورة، حالة التحميل،
/// مؤشر تقدم رفيع، وزر إغلاق. ضغيرة الحجم حتى لا تزاحم نص المصحف.
class AudioPlayerCard extends StatefulWidget {
  const AudioPlayerCard({
    super.key,
    required this.surahNumber,
    this.onClose,
  });

  final int surahNumber;
  final VoidCallback? onClose;

  @override
  State<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<AudioPlayerCard> {
  late Future<bool> _isDownloadedFuture;

  @override
  void initState() {
    super.initState();
    _isDownloadedFuture = _checkDownloaded();
    _loadKnownDuration();
  }

  Future<bool> _checkDownloaded() {
    final provider = Provider.of<QuranProvider>(context, listen: false);
    return provider.checkSurahDownloadedUseCase(widget.surahNumber);
  }

  // المدة الكاملة للسورة المنزّلة تُقرأ من الملف نفسه قبل التشغيل، حتى
  // يظهر الشريط "0:00 / المدة الكاملة" بدل "0:00 / 0:00" عند فتحه.
  Duration? _knownDuration;

  Future<void> _loadKnownDuration() async {
    final provider = Provider.of<QuranProvider>(context, listen: false);
    final Duration? duration = await provider.surahDurationIfDownloaded(
      widget.surahNumber,
      QuranAudioSource.urlForSurah(widget.surahNumber),
    );
    if (!mounted) return;
    setState(() => _knownDuration = duration);
  }

  void _refreshDownloadStatus() {
    if (!mounted) return;
    setState(() {
      _isDownloadedFuture = _checkDownloaded();
    });
    _loadKnownDuration();
  }

  @override
  void didUpdateWidget(covariant AudioPlayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber) {
      // عند تبديل السورة من خارج الكارت (تقليب صفحات القارئ) يجب تحديث
      // حالة التحميل للسورة الجديدة فوراً مع مدة الملف الجديد.
      _isDownloadedFuture = _checkDownloaded();
      _knownDuration = null;
      _loadKnownDuration();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuranProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String url = QuranAudioSource.urlForSurah(widget.surahNumber);
    final bool isSameSurah = provider.currentPlayingSurah == widget.surahNumber;

    return Container(
      key: const ValueKey('floating_audio_player'),
      // الشريط معلّق بـ Stack+Align (قيود مرنة بلا حد أقصى)، وColumn الداخل
      // كانت بـ MainAxisSize.max فامتدّت لتعبئ كل الشاشة عند إزالة الارتفاع
      // الثابت. العمود الآن بـ MainAxisSize.min فيصير حجم البطاقة = حجم
      // محتواها تماماً: لا يتمدّد للشاشة، ولا يتجاوزه نصٌّ عند تكبير الخط
      // (على اللوحي ينمو الـ .sp مع العرض أسرع من الـ .h مع الارتفاع).
      constraints: BoxConstraints(minHeight: 76.h),
      margin: EdgeInsets.symmetric(horizontal: 14.w),
      padding: EdgeInsets.only(left: 12.w, right: 6.w),
      decoration: BoxDecoration(
        color: isDark
            ? AppPalette.darkCardSurface.withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppPalette.mainColor.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPlayButton(provider, url),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'سورة ${QuranAudioSource.surahName(widget.surahNumber)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppPalette.amiriFontFamily,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppPalette.mainColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    _buildStatusIcon(provider),
                  ],
                ),
                _buildSlimSlider(provider, isSameSurah),
              ],
            ),
          ),
          IconButton(
            tooltip: 'إغلاق',
            visualDensity: VisualDensity.compact,
            icon: const Icon(CupertinoIcons.xmark, size: 20),
            color: isDark ? Colors.white70 : Colors.black54,
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(QuranProvider provider, String url) {
    final bool isThisSurah = provider.currentPlayingSurah == widget.surahNumber;

    return GestureDetector(
      onTap: () async {
        await provider.toggleAudio(widget.surahNumber, url);
        _refreshDownloadStatus();
      },
      child: Container(
        width: 46.h,
        height: 46.h,
        decoration: const BoxDecoration(
          color: AppPalette.mainColor,
          shape: BoxShape.circle,
        ),
        // السورة غير المنزّلة يجب تنزيلها كاملة قبل أن تعمل أزرار التشغيل،
        // فالمؤشر هنا يعني "جاري التنزيل".
        child: provider.isDownloading && isThisSurah
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(
                provider.isActuallyPlaying && isThisSurah
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28.h,
              ),
      ),
    );
  }

  Widget _buildStatusIcon(QuranProvider provider) {
    final bool isThisSurah = provider.currentPlayingSurah == widget.surahNumber;

    if (provider.isDownloading && isThisSurah) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return FutureBuilder<bool>(
      future: _isDownloadedFuture,
      builder: (context, snapshot) {
        final bool downloaded = snapshot.data ?? false;
        return Icon(
          downloaded
              ? CupertinoIcons.check_mark_circled_solid
              : CupertinoIcons.cloud_download,
          size: 18,
          color: downloaded
              ? AppPalette.mainColor
              : Colors.grey.withValues(alpha: 0.5),
        );
      },
    );
  }

  Widget _buildSlimSlider(QuranProvider provider, bool isSameSurah) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // المدة تُعرف فقط بعد انتهاء just_audio من التحميل، ولا يمرّ أي حدث
    // موضع قبل بدء التشغيل؛ لذلك نسمع durationStream أيضاً حتى لا يبقى
    // العدّاد عند "0:00 / 0:00" بعد أن صارت المدة معروفة.
    return StreamBuilder<Duration?>(
      stream: isSameSurah ? provider.player.durationStream : null,
      builder: (context, durationSnapshot) {
        return StreamBuilder<Duration?>(
          stream: provider.positionStream,
          builder: (context, positionSnapshot) {
            final Duration position = isSameSurah
                ? (positionSnapshot.data ?? Duration.zero)
                : Duration.zero;
            final Duration duration = isSameSurah
                ? (durationSnapshot.data ?? _knownDuration ?? Duration.zero)
                : (_knownDuration ?? Duration.zero);

            // عند الإيقاف أو تبديل السورة تبقى قيمة الموضع الأخيرة في الـ
            // stream بينما تصير المدة صفراً، فيصبح max = 1 وتُفشل قيمة الموضع
            // شرط Slider الداخلي. لذلك نحدّ قيمة الموضع ضمن [0, max] دائماً.
            final double maxMillis = duration.inMilliseconds > 0
                ? duration.inMilliseconds.toDouble()
                : 1.0;
            final double valueMillis =
                position.inMilliseconds.toDouble().clamp(0.0, maxMillis);

            return Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.h,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 5),
                      activeTrackColor: AppPalette.mainColor,
                      inactiveTrackColor:
                          AppPalette.mainColor.withValues(alpha: 0.2),
                      thumbColor: AppPalette.mainColor,
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 10),
                    ),
                    child: Slider(
                      value: valueMillis,
                      max: maxMillis,
                      onChanged: isSameSurah
                          ? (v) => provider.seek(
                                Duration(milliseconds: v.toInt()),
                              )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_formatTime(position)} / ${_formatTime(duration)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _formatTime(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes % 60;
    final int seconds = duration.inSeconds % 60;
    String two(int value) => value.toString().padLeft(2, '0');
    final body = hours > 0
        ? '$hours:${two(minutes)}:${two(seconds)}'
        : '$minutes:${two(seconds)}';
    return AppHelpers.arabicDigits(body);
  }
}
