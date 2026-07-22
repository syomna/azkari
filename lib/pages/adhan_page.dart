import 'dart:async';

import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';

class AdhanPage extends StatefulWidget {
  final String prayerKey;

  const AdhanPage({super.key, required this.prayerKey});

  @override
  State<AdhanPage> createState() => _AdhanPageState();
}

class _AdhanPageState extends State<AdhanPage>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _player;
  late final AnimationController _pulseController;
  StreamSubscription? _playerSubscription;
  bool _isPlaying = false;
  bool _disposed = false;

  static const Map<String, String> _prayerNamesAr = {
    'fajr': 'صلاة الفجر',
    'dhuhr': 'صلاة الظهر',
    'asr': 'صلاة العصر',
    'maghrib': 'صلاة المغرب',
    'isha': 'صلاة العشاء',
  };

  String get _prayerName => _prayerNamesAr[widget.prayerKey] ?? 'الصلاة';

  @override
  void initState() {
    super.initState();

    // Keep screen on
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _player.setAsset('assets/audio/full_adhan.mp3');
      _playerSubscription = _player.playerStateStream.listen((state) {
        if (_disposed) return;
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _isPlaying = false);
        }
      });
      await _player.play();
      if (!_disposed && mounted) setState(() => _isPlaying = true);
    } catch (e) {
      // If audio fails, the page still shows — user can dismiss
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _playerSubscription?.cancel();
    _player.dispose();
    _pulseController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _dismiss() {
    _player.stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _dismiss();
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0D3B1E),
                Color(0xFF145A32),
                Color(0xFF1A6B3C),
                Color(0xFF0D3B1E),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                // Pulsing glow
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final glowOpacity =
                        0.15 + (_pulseController.value * 0.2);
                    return Container(
                      width: 180.w,
                      height: 180.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppPalette.mainColor
                                .withValues(alpha: glowOpacity),
                            blurRadius: 60 + (_pulseController.value * 30),
                            spreadRadius: 10 + (_pulseController.value * 10),
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 180.w,
                    height: 180.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'ﷲ',
                        style: TextStyle(
                          fontSize: 64.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30.h),
                // "Allahu Akbar"
                Text(
                  'الله أكبر',
                  style: TextStyle(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 12.h),
                // Prayer name
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    _prayerName,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Playing indicator
                if (_isPlaying)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volume_up_rounded,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 18.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'جاري الأذان...',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                const Spacer(flex: 3),
                // Dismiss button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: OutlinedButton(
                      onPressed: _dismiss,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(
                        'إغلاق',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
