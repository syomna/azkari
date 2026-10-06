import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/domain/dua_categories.dart';
import 'package:azkar_app/features/azkar/domain/entities/zekr_entity.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/features/azkar/presentation/providers/favorites_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// ورقة إضافة وتعديل موضوع مخصص (ذكر أو دعاء) في واجهة واحدة.
///
/// وضع الإضافة عندما يكون [initialCategory] فارغاً، ووضع التعديل عندما يكون
/// معبّأً مع [currentAzkar]. الفرق بين الوضعين في تسميات الحقول، وفي التحقق من
/// العنوان (الإضافة فقط تمنع خلط موضوعات الأدعية بالأذكار)، وفي تدفق الحفظ:
/// الإضافة تنشئ موضوعاً جديداً ثم تنتقل إلى تبويب "أذكاري"، والتعديل يستبدل
/// الفئة ويرحّل المحفوظات والمفضلة.
class AzkarFormSheet extends StatefulWidget {
  const AzkarFormSheet({
    super.key,
    this.onChangeFilter,
    this.kind = AzkarLibrary.azkar,
    this.initialCategory,
    this.currentAzkar,
  }) : assert((initialCategory == null) == (currentAzkar == null));

  /// يُستدعى بعد نجاح الإضافة لتحويل التبويب إلى "أذكاري" حيث يظهر الموضوع.
  /// لاغٍ في وضع التعديل.
  final VoidCallback? onChangeFilter;

  /// المكتبة التي يُضاف إليها الموضوع (تغيّر التسميات وتحقّق العنوان).
  final AzkarLibrary kind;

  /// عنوان الفئة في وضع التعديل. فارغ = وضع الإضافة.
  final String? initialCategory;

  /// القائمة الحالية في وضع التعديل، وتبقى فارغة في وضع الإضافة.
  final List<ZekrEntity>? currentAzkar;

  @override
  State<AzkarFormSheet> createState() => _AzkarFormSheetState();
}

class _AzkarFormSheetState extends State<AzkarFormSheet> {
  late final TextEditingController titleController;
  late List<TextEditingController> zikrControllers;
  late List<TextEditingController> countControllers;

  bool get _isDua => widget.kind == AzkarLibrary.dua;
  bool get _isEdit => widget.initialCategory != null;

  @override
  void initState() {
    super.initState();
    final current = widget.currentAzkar;
    titleController = TextEditingController(text: widget.initialCategory ?? '');
    zikrControllers = (current != null && current.isNotEmpty)
        ? current.map((e) => TextEditingController(text: e.zekr)).toList()
        : [TextEditingController()];
    countControllers = (current != null && current.isNotEmpty)
        ? current
            .map((e) => TextEditingController(text: e.count.toString()))
            .toList()
        : [TextEditingController(text: '1')];
  }

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
                  _isEdit
                      ? 'تعديل الأذكار المخصصة'
                      : _isDua
                          ? 'إضافة أدعية جديدة'
                          : 'إضافة أذكار جديدة',
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
                    hintText: _isEdit
                        ? 'عنوان الأذكار'
                        : _isDua
                            ? 'عنوان الأدعية (مثال: دعاء السفر)'
                            : 'عنوان الأذكار (مثال: أذكار السفر)',
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
                    Expanded(
                      child: Text(
                        !_isEdit && _isDua ? 'نصوص الأدعية' : 'النصوص والأدعية',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
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
                                      color: AppPalette.errorColor),
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
                                  hintText: !_isEdit && _isDua
                                      ? 'نص الدعاء رقم ${index + 1}...'
                                      : 'نص الذكر رقم ${index + 1}...',
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
                    final title = titleController.text.trim();

                    // تجميع النصوص مع عدد التكرار لكل صف.
                    final List<Map<String, dynamic>> structuredAzkar = [];
                    for (int i = 0; i < zikrControllers.length; i++) {
                      final text = zikrControllers[i].text.trim();
                      final countVal = int.tryParse(
                              AppHelpers.normalizeArabicIndicDigits(
                                  countControllers[i].text)) ??
                          1;
                      if (text.isNotEmpty) {
                        if (countVal <= 0) {
                          AppHelpers.showToast(
                              'عدد التكرار يجب أن يكون أكبر من صفر',
                              status: ToastStatus.error);
                          return;
                        }
                        structuredAzkar.add({
                          'text': text,
                          'count': countVal,
                        });
                      }
                    }

                    if (_isEdit) {
                      await _saveEdit(title, structuredAzkar);
                    } else {
                      await _saveNew(title, structuredAzkar);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.mainColor,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    _isEdit ? 'تعديل وحفظ' : 'حفظ الكل',
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

  /// إنشاء موضوع جديد. العنوان هو ما يميّز موضوع الدعاء من موضوع الذكر،
  /// فنمنع حفظه في المكتبة الخطأ: عنوان بلا كلمة "دعاء" في ورقة الأدعية، أو
  /// عنوان فيها في ورقة الأذكار.
  Future<void> _saveNew(
      String title, List<Map<String, dynamic>> structuredAzkar) async {
    if (_isDua && title.isNotEmpty && !isDuaCategory(title)) {
      AppHelpers.showToast('العنوان يجب أن يحتوي على كلمة "دعاء" أو "أدعية"',
          status: ToastStatus.error);
      return;
    }
    if (!_isDua && isDuaCategory(title)) {
      AppHelpers.showToast('موضوعات الأدعية تُضاف من صفحة الأدعية',
          status: ToastStatus.error);
      return;
    }

    if (title.isEmpty || structuredAzkar.isEmpty) {
      AppHelpers.showToast('اكتب عنوانًا وذكرًا واحدًا على الأقل قبل الحفظ',
          status: ToastStatus.error);
      return;
    }

    final success = await context.read<AzkarProvider>().saveCustomAzkarCategory(
          categoryTitle: title,
          azkarItems: structuredAzkar,
        );

    if (!success) {
      if (context.mounted) {
        AppHelpers.showToast(
            _isDua
                ? 'فشل حفظ الأدعية، حاول مرة أخرى'
                : 'فشل حفظ الأذكار، حاول مرة أخرى',
            status: ToastStatus.error);
      }
      return;
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onChangeFilter?.call();
      AppHelpers.showToast(
          _isDua ? 'تم حفظ الأدعية بنجاح' : 'تم حفظ الأذكار بنجاح',
          status: ToastStatus.success);
    }
  }

  /// استبدال الفئة القديمة بالجديدة في معاملة واحدة، ثم ترحيل المحفوظات
  /// والمفضلة عند تغيير الاسم أو نص الذكر الفردي — حتى لا تُفقد البيانات لو
  /// فشل الحفظ.
  Future<void> _saveEdit(
      String title, List<Map<String, dynamic>> structuredAzkar) async {
    if (title.isEmpty || structuredAzkar.isEmpty) {
      AppHelpers.showToast('اكتب عنوانًا وذكرًا واحدًا على الأقل لحفظ التعديل',
          status: ToastStatus.error);
      return;
    }

    final favorites = context.read<FavoritesProvider>();
    final isOriginallyFavorited =
        favorites.isCategoryFav(widget.initialCategory!);

    final success =
        await context.read<AzkarProvider>().updateCustomAzkarCategory(
              oldCategoryTitle: widget.initialCategory!,
              newCategoryTitle: title,
              azkarItems: structuredAzkar,
            );

    if (!success) {
      if (context.mounted) {
        AppHelpers.showToast('فشل حفظ التعديل، حاول مرة أخرى',
            status: ToastStatus.error);
      }
      return;
    }

    if (widget.initialCategory != title) {
      await favorites.renameCategoryItemFavorites(
          widget.initialCategory!, title);
      if (isOriginallyFavorited) {
        await favorites.renameCategoryFavorite(widget.initialCategory!, title);
      }
    }

    // ترحيل مفضلة الذكر الفردي عند تغيير النص نفسه (مع تطابق عدد الصفوف فقط
    // لتجنّب الالتباس عند إضافة أو حذف صفوف).
    if (widget.currentAzkar!.length == structuredAzkar.length) {
      for (int i = 0; i < structuredAzkar.length; i++) {
        final oldZekr = widget.currentAzkar![i].zekr;
        final newZekr = structuredAzkar[i]['text'] as String;
        if (oldZekr != newZekr) {
          await favorites.renameItemFavorite(title, oldZekr, newZekr);
        }
      }
    }

    if (mounted) {
      Navigator.pop(context);
      AppHelpers.showToast('تم تعديل وحفظ الأذكار بنجاح',
          status: ToastStatus.success);
    }
  }
}
