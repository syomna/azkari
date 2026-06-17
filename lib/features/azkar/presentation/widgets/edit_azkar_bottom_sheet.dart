import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class EditAzkarBottomSheet extends StatefulWidget {
  final String category;
  final List<ZekrEntity> currentAzkar;
  const EditAzkarBottomSheet(
      {super.key, required this.category, required this.currentAzkar});

  @override
  State<EditAzkarBottomSheet> createState() => _EditAzkarBottomSheetState();
}

class _EditAzkarBottomSheetState extends State<EditAzkarBottomSheet> {
  TextEditingController titleController = TextEditingController();
  List<TextEditingController> zikrControllers = [];
  List<TextEditingController> countControllers = [];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.category);
    zikrControllers = widget.currentAzkar.isNotEmpty
        ? widget.currentAzkar
            .map((e) => TextEditingController(text: e.zekr))
            .toList()
        : [TextEditingController()];
    countControllers = widget.currentAzkar.isNotEmpty
        ? widget.currentAzkar
            .map((e) => TextEditingController(text: e.count.toString()))
            .toList()
        : [TextEditingController(text: '1')];
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AzkarProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20.w,
            right: 20.w,
            top: 20.h,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'تعديل الأذكار المخصصة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: titleController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'عنوان الأذكار',
                    hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey),
                    filled: true,
                    fillColor: isDark ? Colors.black12 : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'النصوص والأدعية',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setModalState(() {
                          zikrControllers.add(TextEditingController());
                          countControllers
                              .add(TextEditingController(text: '1'));
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('إضافة نص آخر'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppPalette.mainColor),
                    ),
                  ],
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 220.h),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: zikrControllers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(top: 4.h, bottom: 12.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (zikrControllers.length > 1)
                              Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: IconButton(
                                  onPressed: () {
                                    setModalState(() {
                                      zikrControllers[index].dispose();
                                      countControllers[index].dispose();
                                      zikrControllers.removeAt(index);
                                      countControllers.removeAt(index);
                                    });
                                  },
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                ),
                              ),
                            SizedBox(
                              width: 60.w,
                              child: TextField(
                                controller: countControllers[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13.sp),
                                decoration: InputDecoration(
                                  hintText: '1',
                                  labelText: 'المرات',
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  labelStyle: TextStyle(
                                      fontSize: 11.sp,
                                      color: AppPalette.mainColor),
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 14.h, horizontal: 4.w),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.black12
                                      : Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: TextField(
                                controller: zikrControllers[index],
                                maxLines: 2,
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 13.sp),
                                decoration: InputDecoration(
                                  hintText: 'نص الذكر رقم ${index + 1}...',
                                  hintStyle: TextStyle(
                                      fontSize: 12.sp, color: Colors.grey),
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 14.h, horizontal: 12.w),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.black12
                                      : Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: () async {
                    final newTitle = titleController.text.trim();
                    final List<Map<String, dynamic>> structuredAzkar = [];

                    for (int i = 0; i < zikrControllers.length; i++) {
                      final text = zikrControllers[i].text.trim();
                      final countVal =
                          int.tryParse(countControllers[i].text.trim()) ?? 1;
                      if (text.isNotEmpty) {
                        structuredAzkar.add({
                          'text': text,
                          'count': countVal,
                        });
                      }
                    }

                    if (newTitle.isNotEmpty && structuredAzkar.isNotEmpty) {
                      // 1️⃣ معرفة ما إذا كان الاسم القديم موجود في المفضلة قبل حذفه
                      final bool isOriginallyFavorited =
                          provider.favCategories.contains(widget.category);

                      // 2️⃣ حذف الفئة القديمة مع تفعيل خيار الاحتفاظ بها في قائمة الـ Favorites مؤقتاً
                      await provider.deleteCustomCategory(widget.category,
                          keepInFavorites: true);

                      // 3️⃣ حفظ الفئة بالبيانات الجديدة (أو الاسم الجديد)
                      await provider.saveCustomAzkarCategory(
                        categoryTitle: newTitle,
                        azkarItems: structuredAzkar,
                      );

                      if (isOriginallyFavorited) {
                        if (widget.category != newTitle) {
                          provider.favCategories.remove(widget.category);
                        }
                        if (!provider.favCategories.contains(newTitle)) {
                          provider.favCategories.add(newTitle);
                        }
                        await provider.sharedPreferences.setStringList(
                            'fav_categories', provider.favCategories);
                        provider.loadFavorites();
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                        AppHelpers.showToast('تم تعديل وحفظ الأذكار بنجاح',
                            status: ToastStatus.success);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.mainColor,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text(
                    'تعديل وحفظ',
                    style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    );
  }
}
