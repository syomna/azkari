import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Locale-consistent time picker used by the prayer-times and azkar settings.
///
/// The built-in `showTimePicker` input mode renders Arabic-Indic digits
/// (٠١٢٣٤٥٦٧٨٩) when the app locale is Arabic, but parses the typed value
/// with `int.tryParse`, which only understands Western digits. Depending on
/// the device keyboard this produces a mismatch between what is shown
/// (Arabic-Indic), what the user types (the keyboard's digits) and what is
/// actually accepted (Western only).
///
/// This sheet ignores the keyboard layout: it accepts both digit sets, always
/// displays Arabic-Indic digits and validates the same way on every device.
Future<TimeOfDay?> showArabicTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  required String title,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) =>
        _ArabicTimePickerSheet(initialTime: initialTime, title: title),
  );
}

class _ArabicTimePickerSheet extends StatefulWidget {
  const _ArabicTimePickerSheet({
    required this.initialTime,
    required this.title,
  });

  final TimeOfDay initialTime;
  final String title;

  @override
  State<_ArabicTimePickerSheet> createState() => _ArabicTimePickerSheetState();
}

class _ArabicTimePickerSheetState extends State<_ArabicTimePickerSheet> {
  static const Map<String, String> _arabicToLatin = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  static const Map<String, String> _latinToArabic = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };

  static String _toLatinDigits(String text) => text.replaceAllMapped(
        RegExp('[٠-٩]'),
        (m) => _arabicToLatin[m.group(0)!]!,
      );

  static String _toArabicDigits(String text) => text.replaceAllMapped(
        RegExp('[0-9]'),
        (m) => _latinToArabic[m.group(0)!]!,
      );

  static String _arabicTwo(int value) =>
      AppHelpers.getArabicNumber(value).padLeft(2, '٠');

  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late DayPeriod _period;
  bool _hourError = false;
  bool _minuteError = false;

  @override
  void initState() {
    super.initState();
    _period = widget.initialTime.period;
    _hourController = TextEditingController(
        text: _arabicTwo(widget.initialTime.hourOfPeriod));
    _minuteController =
        TextEditingController(text: _arabicTwo(widget.initialTime.minute));
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _save() {
    final hour = int.tryParse(_toLatinDigits(_hourController.text));
    final minute = int.tryParse(_toLatinDigits(_minuteController.text));
    final hourValid = hour != null && hour >= 1 && hour <= 12;
    final minuteValid = minute != null && minute >= 0 && minute <= 59;

    setState(() {
      _hourError = !hourValid;
      _minuteError = !minuteValid;
    });
    if (!hourValid || !minuteValid) return;

    var hour24 = hour;
    if (_period == DayPeriod.am) {
      if (hour24 == 12) hour24 = 0;
    } else if (hour24 != 12) {
      hour24 += 12;
    }
    Navigator.of(context).pop(TimeOfDay(hour: hour24, minute: minute));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Clamp text scaling so the input row stays stable while the
            // keyboard is open.
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1).clamp(0.8, 1.2),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                SizedBox(height: 18.h),
                Text(
                  'تعديل وقت ${widget.title}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 22.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInput(
                      controller: _hourController,
                      label: 'الساعة',
                      hasError: _hourError,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.mainColor,
                        ),
                      ),
                    ),
                    _buildInput(
                      controller: _minuteController,
                      label: 'الدقيقة',
                      hasError: _minuteError,
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPeriodButton('ص', DayPeriod.am),
                    SizedBox(width: 14.w),
                    _buildPeriodButton('م', DayPeriod.pm),
                  ],
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text('إلغاء', style: TextStyle(fontSize: 15.sp)),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.mainColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          'حفظ',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_hourError || _minuteError) ...[
                  SizedBox(height: 12.h),
                  Text(
                    'أدخل وقتاً صحيحاً (الساعة من ١ إلى ١٢ والدقيقة من ٠ إلى ٥٩)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.redAccent.shade200,
                    ),
                  ),
                ] else ...[
                  SizedBox(height: 24.h),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required bool hasError,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: 92.w,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.next,
            inputFormatters: const [_ArabicDigitFormatter()],
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppPalette.mainColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8.w, vertical: 14.h),
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.grey[100],
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.redAccent
                      : AppPalette.mainColor.withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(
                  color: hasError ? Colors.redAccent : AppPalette.mainColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String label, DayPeriod period) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _period == period;
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () => setState(() {
        _period = period;
        _hourError = false;
      }),
      child: Ink(
        padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected
              ? AppPalette.mainColor
              : (isDark ? Colors.white10 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _ArabicDigitFormatter extends TextInputFormatter {
  const _ArabicDigitFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final latin = _ArabicTimePickerSheetState._toLatinDigits(newValue.text);
    var digits = latin.replaceAll(RegExp('[^0-9]'), '');
    if (digits.length > 2) digits = digits.substring(0, 2);
    final value = _ArabicTimePickerSheetState._toArabicDigits(digits);
    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}
