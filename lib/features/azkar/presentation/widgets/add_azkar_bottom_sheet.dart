import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AddAzkarBottomSheet extends StatefulWidget {
  const AddAzkarBottomSheet({super.key, required this.onChangeFilter});

  final VoidCallback onChangeFilter;

  @override
  State<AddAzkarBottomSheet> createState() => _AddAzkarBottomSheetState();
}

class _AddAzkarBottomSheetState extends State<AddAzkarBottomSheet> {
  final TextEditingController titleController = TextEditingController();

  List<TextEditingController> zikrControllers = [TextEditingController()];
  List<TextEditingController> countControllers = [
    TextEditingController(text: '1')
  ];
  bool _isSaving = false;

  @override
  void dispose() {
    titleController.dispose();
    for (final c in zikrControllers) {
      c.dispose();
    }
    for (final c in countControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  AppStrings.newAzkarTitle,
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
                    hintText: AppStrings.azkarExampleHint,
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
                      AppStrings.prayersAndDuaas,
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
                      label: const Text(AppStrings.addAnotherText),
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
                        padding: EdgeInsets.only(bottom: 12.h),
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
                                  labelText: AppStrings.repeatCount,
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
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final title = titleController.text.trim();

                          final List<Map<String, dynamic>> structuredAzkar = [];
                          for (int i = 0; i < zikrControllers.length; i++) {
                            final text = zikrControllers[i].text.trim();
                            final countVal =
                                int.tryParse(countControllers[i].text.trim()) ??
                                    1;
                            if (text.isNotEmpty) {
                              structuredAzkar.add({
                                'text': text,
                                'count': countVal,
                              });
                            }
                          }

                          if (title.isEmpty || structuredAzkar.isEmpty) {
                            if (context.mounted) {
                              AppHelpers.showToast(AppStrings.fillAllFields,
                                  status: ToastStatus.error);
                            }
                            return;
                          }

                          setState(() => _isSaving = true);

                          try {
                            await context
                                .read<AzkarProvider>()
                                .saveCustomAzkarCategory(
                                  categoryTitle: title,
                                  azkarItems: structuredAzkar,
                                );

                            if (context.mounted) {
                              Navigator.pop(context);
                              widget.onChangeFilter();
                            }
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.mainColor,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 14.sp,
                          width: 14.sp,
                          child: const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          AppStrings.saveAll,
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
