import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DisplayAzkar extends StatefulWidget {
  const DisplayAzkar({
    super.key,
    required this.zikrEntity,
    this.showCategoryHeader = false,
  });

  final ZekrEntity zikrEntity;
  final bool showCategoryHeader;
  @override
  State<DisplayAzkar> createState() => _DisplayAzkarState();
}

class _DisplayAzkarState extends State<DisplayAzkar> {
  int zekrCount = 1;

  @override
  void initState() {
    if (widget.zikrEntity.count.isNotEmpty) {
      zekrCount = int.parse(widget.zikrEntity.count);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = AppPalette.mainColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showCategoryHeader)
          Container(
            margin: EdgeInsets.only(bottom: 10.h),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r), color: mainColor),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                widget.zikrEntity.category,
                style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        Stack(
          children: [
            Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    border: Border.all(color: mainColor), // Using kMainColor
                    borderRadius: BorderRadius.circular(8.r)),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: GestureDetector(
                    onTap: _decrementCount,
                    onLongPress: () {
                      AppHelpers.copyText(widget
                          .zikrEntity.zekr); // Copy directly from zikrEntity
                    },
                    child: Text(
                      widget
                          .zikrEntity.zekr, // Display directly from zikrEntity
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
            // Count Display: Still conditional based on zikrEntity.count
            if (widget.zikrEntity.count.isNotEmpty)
              Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    height: 30.h,
                    width: 40.w,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        color: mainColor), // Using kMainColor
                    child: Center(
                        child: Text(
                      '$zekrCount', // Display directly from zikrEntity
                      style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    )),
                  )),
          ],
        ),
      ],
    );
  }

  void _decrementCount() {
    if (zekrCount > 0) {
      setState(() {
        zekrCount--;
      });
      if (zekrCount == 0) {
        // You might want a slightly different message or behavior when count reaches zero
        AppHelpers.showToast('أكملت الذكر!');
      }
    }
  }
}
