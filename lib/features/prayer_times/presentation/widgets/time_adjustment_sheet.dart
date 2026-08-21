import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TimeAdjustmentSheet extends StatefulWidget {
  final String prayerName;
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onChanged;

  const TimeAdjustmentSheet({
    super.key,
    required this.prayerName,
    required this.initialTime,
    required this.onChanged,
  });

  @override
  State<TimeAdjustmentSheet> createState() => _TimeAdjustmentSheetState();
}

class _TimeAdjustmentSheetState extends State<TimeAdjustmentSheet> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
  }

  void _updateTime(int h, int m) {
    setState(() {
      _hour = (h + 24) % 24;
      _minute = (m + 60) % 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayHour = _hour > 12 ? _hour - 12 : (_hour == 0 ? 12 : _hour);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${AppStrings.adjustPrayerTime} ${widget.prayerName}',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 25.h),

          _buildAdjuster(
            AppStrings.hourLabel,
            displayHour.toString().padLeft(2, '0'),
            onAdd: () => _updateTime(_hour + 1, _minute),
            onRemove: () => _updateTime(_hour - 1, _minute),
          ),

          SizedBox(height: 20.h),

          _buildAdjuster(
            AppStrings.minuteLabel,
            _minute.toString().padLeft(2, '0'),
            onAdd: () => _updateTime(_hour, _minute + 1),
            onRemove: () => _updateTime(_hour, _minute - 1),
          ),

          SizedBox(height: 15.h),
          _buildAmPmToggle(),

          SizedBox(height: 30.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: () {
                widget.onChanged(TimeOfDay(hour: _hour, minute: _minute));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.mainColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r)),
              ),
              child: const Text(AppStrings.saveAdjustment,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjuster(String label, String value,
      {required VoidCallback onAdd, required VoidCallback onRemove}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
        Row(
          children: [
            _roundButton(Icons.remove, onRemove),
            Container(
              width: 80.w,
              alignment: Alignment.center,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: AppPalette.mainColor)),
            ),
            _roundButton(Icons.add, onAdd),
          ],
        ),
      ],
    );
  }

  Widget _buildAmPmToggle() {
    final isPm = _hour >= 12;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _amPmButton(AppStrings.amSuffix, !isPm),
        SizedBox(width: 12.w),
        _amPmButton(AppStrings.pmSuffix, isPm),
      ],
    );
  }

  Widget _amPmButton(String label, bool selected) {
    return GestureDetector(
      onTap: () {
        if (label == AppStrings.pmSuffix && !selected) {
          _updateTime(_hour + 12, _minute);
        } else if (label == AppStrings.amSuffix && !selected) {
          _updateTime(_hour - 12, _minute);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppPalette.mainColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Colors.grey.shade600)),
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: AppPalette.mainColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppPalette.mainColor, size: 24.sp),
      ),
    );
  }
}
