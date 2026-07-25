import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/widget_guide/widgets/circle_icon_button.dart';
import 'package:azkar_app/features/widget_guide/widgets/guide_page_indicator.dart';
import 'package:azkar_app/features/widget_guide/widgets/widget_guide_step_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/widget_guide_steps.dart';
import '../models/widget_guide_step.dart';

class WidgetGuidePage extends StatefulWidget {
  const WidgetGuidePage({
    this.openedFromSettings = false,
    super.key,
  });

  final bool openedFromSettings;

  static const seenPreferenceKey = 'has_seen_home_widget_guide_v1';

  static Future<void> open(
    BuildContext context, {
    bool openedFromSettings = false,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WidgetGuidePage(
          openedFromSettings: openedFromSettings,
        ),
      ),
    );
  }

  @override
  State<WidgetGuidePage> createState() => _WidgetGuidePageState();
}

class _WidgetGuidePageState extends State<WidgetGuidePage> {
  late final PageController _pageController;
  late final List<WidgetGuideStep> _steps;

  int _currentIndex = 0;
  bool _isSaving = false;

  bool get _isFirstPage => _currentIndex == 0;

  bool get _isLastPage => _currentIndex == _steps.length - 1;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    _steps = getWidgetGuideSteps();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_isSaving) return;

    if (_isLastPage) {
      await _finish();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _previous() async {
    if (_isFirstPage) {
      await _closeGuide();
      return;
    }

    await _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);

    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.setBool(
        WidgetGuidePage.seenPreferenceKey,
        true,
      );

      if (!mounted) return;

      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _closeGuide() async {
    if (!widget.openedFromSettings) {
      final preferences = await SharedPreferences.getInstance();

      await preferences.setBool(
        WidgetGuidePage.seenPreferenceKey,
        true,
      );
    }

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _steps.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return WidgetGuideStepView(
                      step: _steps[index],
                      index: index,
                    );
                  },
                ),
              ),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final mutedTextColor =
        isDarkMode ? AppPalette.darkMutedText : AppPalette.lightMutedText;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        16.w,
        8.h,
        16.w,
        4.h,
      ),
      child: SizedBox(
        height: 48.h,
        child: Row(
          children: [
            CircleIconButton(
              icon: Icons.close_rounded,
              onPressed: _closeGuide,
            ),
            Expanded(
              child: Text(
                'إضافة ويدجت أذكاري',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(
              width: 44.w,
              child: Center(
                child: Text(
                  '${_currentIndex + 1}/${_steps.length}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: mutedTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final mutedTextColor =
        isDarkMode ? AppPalette.darkMutedText : AppPalette.lightMutedText;

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.fromSTEB(
        22.w,
        12.h,
        22.w,
        18.h,
      ),
      color: theme.scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GuidePageIndicator(
            currentIndex: _currentIndex,
            count: _steps.length,
          ),
          SizedBox(height: 18.h),
          SizedBox(
            width: double.infinity,
            height: 45.h,
            child: FilledButton(
              onPressed: _isSaving ? null : _next,
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.mainColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppPalette.mainColor.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSaving
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        width: 22.r,
                        height: 22.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        key: ValueKey(_isLastPage),
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLastPage
                                ? 'تم، فهمت'
                                : _isFirstPage
                                    ? 'عرض طريقة الإضافة'
                                    : 'التالي',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (!_isLastPage) ...[
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 20.sp,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          SizedBox(
            height: 42.h,
            child: TextButton(
              onPressed: _previous,
              style: TextButton.styleFrom(
                foregroundColor: mutedTextColor,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
              ),
              child: Text(
                _isFirstPage ? 'لاحقًا' : 'السابق',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
