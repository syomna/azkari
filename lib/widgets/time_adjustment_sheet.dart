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
      // Logic لضمان إن الساعات والدقائق تلف بشكل صحيح
      _hour = (h + 24) % 24;
      _minute = (m + 60) % 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final period = _hour >= 12 ? 'م' : 'ص';
    final displayHour = _hour > 12 ? _hour - 12 : (_hour == 0 ? 12 : _hour);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('تعديل وقت صلاة ${widget.prayerName}',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 25.h),

          // تعديل الساعات
          _buildAdjuster(
            'الساعة',
            displayHour.toString().padLeft(2, '0'),
            onAdd: () => _updateTime(_hour + 1, _minute),
            onRemove: () => _updateTime(_hour - 1, _minute),
          ),

          SizedBox(height: 20.h),

          // تعديل الدقائق
          _buildAdjuster(
            'الدقيقة',
            _minute.toString().padLeft(2, '0'),
            onAdd: () => _updateTime(_hour, _minute + 1),
            onRemove: () => _updateTime(_hour, _minute - 1),
          ),

          // SizedBox(height: 15.h),
          // Text(period,
          //     style: TextStyle(
          //         fontSize: 16.sp,
          //         fontWeight: FontWeight.bold,
          //         color: AppPalette.mainColor)),

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
              child: const Text('حفظ التعديل',
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
