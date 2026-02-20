import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart'; // Import AzkarProvider
import 'package:azkar_app/features/azkar/presentation/widgets/display_azkar.dart'; // Assuming DisplayAzkar is generic
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AzkarCategoryPage extends StatefulWidget {
  const AzkarCategoryPage({
    super.key,
    required this.title,
    required this.categoryName,
  });

  final String title;
  final String categoryName; // The category to filter by

  @override
  State<AzkarCategoryPage> createState() => _AzkarCategoryPageState();
}

class _AzkarCategoryPageState extends State<AzkarCategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ZekrEntity> _currentDisplayedAzkar = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _filterAzkar(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAzkar(String query) {
    final azkarProvider = Provider.of<AzkarProvider>(context, listen: false);
    List<ZekrEntity> baseList;

    if (widget.categoryName == AppConstants.morningAzkarCategory) {
      baseList = azkarProvider.morningAzkar;
    } else if (widget.categoryName == AppConstants.eveningAzkarCategory) {
      baseList = azkarProvider.eveningAzkar;
    } else if (widget.categoryName == AppConstants.wakingUpAzkarCategory) {
      baseList = azkarProvider.wakingUpAzkar;
    } else if (widget.categoryName == AppConstants.sleepingAzkarCategory) {
      baseList = azkarProvider.sleepingAzkar;
    } else if (widget.categoryName == AppConstants.prayerAzkarCategory) {
      baseList = azkarProvider.prayerAzkar;
    } else if (widget.categoryName == AppConstants.mosqueAzkarCategory) {
      baseList = azkarProvider.mosqueAzkar;
    } else if (widget.categoryName == AppConstants.variousDuaaCategory) {
      baseList = azkarProvider.variousDuaa;
    } else {
      baseList = azkarProvider.azkarList;
    }

    setState(() {
      if (query.isEmpty) {
        _currentDisplayedAzkar = baseList;
      } else {
        _currentDisplayedAzkar = baseList
            .where((zekr) =>
                    zekr.category
                        .toLowerCase()
                        .contains(query.toLowerCase()) || // Search by category
                    zekr.zekr
                        .toLowerCase()
                        .contains(query.toLowerCase()) // Or search by zikr text
                )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // final azkarProvider = Provider.of<AzkarProvider>(context);

    // // Handle loading/error states for the AzkarProvider
    // if (azkarProvider.azkarStatus == AppLoadingStatus.initial ||
    //     azkarProvider.azkarStatus == AppLoadingStatus.loading) {
    //   return Scaffold(
    //     appBar: AppBar(
    //       title: Text(widget.title),
    //       centerTitle: true,
    //     ),
    //     body: const Center(
    //       child: CircularProgressIndicator(color: AppPalette.mainColor),
    //     ),
    //   );
    // }
    // if (azkarProvider.azkarStatus == AppLoadingStatus.error) {
    //   return Scaffold(
    //     appBar: AppBar(
    //       title: Text(widget.title),
    //       centerTitle: true,
    //     ),
    //     body: Center(
    //       child: Text(
    //         'Error loading Azkar: ${azkarProvider.azkarErrorMessage ?? "Unknown error"}',
    //         textAlign: TextAlign.center,
    //         style: const TextStyle(color: Colors.red),
    //       ),
    //     ),
    //   );
    // }

    // if (_currentDisplayedAzkar.isEmpty && azkarProvider.azkarList.isNotEmpty) {
    //   if (_searchController.text.isEmpty) {
    //     return Scaffold(
    //         appBar: AppBar(
    //           title: Text(widget.title),
    //           centerTitle: true,
    //         ),
    //         body: Center(
    //             child: Text('لا توجد أذكار في هذا القسم.',
    //                 style: TextStyle(
    //                     fontSize: 18.sp, fontWeight: FontWeight.bold))));
    //   } else {
    //     return Scaffold(
    //         appBar: AppBar(
    //           title: Text(widget.title),
    //           centerTitle: true,
    //         ),
    //         body: Center(
    //             child: Text('غير موجود',
    //                 style: TextStyle(
    //                     fontSize: 18.sp, fontWeight: FontWeight.bold))));
    //   }
    // }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/duaa.png'), opacity: 0.08)),
        child: Column(
          children: [
            if (widget.categoryName == AppConstants.variousDuaaCategory)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: SizedBox(
                  height: 35.h,
                  child: TextFormField(
                    style: TextStyle(fontSize: 14.sp),
                    controller: _searchController,
                    onChanged: (v) {
                      _filterAzkar(v);
                    },
                    cursorColor: AppPalette.mainColor,
                    decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppPalette.mainColor,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppPalette.mainColor,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterAzkar('');
                                },
                              )
                            : null,
                        focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.r)),
                            borderSide: BorderSide(
                              color:
                                  AppPalette.mainColor.withValues(alpha: 0.5),
                            )),
                        enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.r)),
                            borderSide: BorderSide(
                              color:
                                  AppPalette.mainColor.withValues(alpha: 0.2),
                            )),
                        hintText: 'ابحث عن ذكر أو دعاء'),
                  ),
                ),
              ),
            SizedBox(
              height: 10.h,
            ),
            Text(
              widget.categoryName == AppConstants.variousDuaaCategory
                  ? 'لنسخ أي ذكر او دعاء، قم بالضغط المطول عليه.'
                  : 'لنسخ أي ذكر، قم بالضغط المطول عليه. لإنقاص عداد الذكر، اضغط على الذكر.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(
              height: 10.h,
            ),
            Expanded(
              child: _currentDisplayedAzkar.isEmpty &&
                      _searchController.text.isNotEmpty
                  ? Center(
                      child: Text(
                        'غير موجود',
                        style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    )
                  : Scrollbar(
                      thickness: 6.w,
                      radius: Radius.circular(8.r),
                      trackVisibility: true,
                      thumbVisibility: true,
                      child: ListView.separated(
                          itemCount: _currentDisplayedAzkar.length,
                          separatorBuilder: (context, index) => SizedBox(
                                height: 20.h,
                              ),
                          itemBuilder: (context, index) {
                            final zikr = _currentDisplayedAzkar[index];
                            bool showHeader = false;
                            if (widget.categoryName ==
                                        AppConstants.variousDuaaCategory &&
                                    (index == 0 ||
                                        zikr.category !=
                                            _currentDisplayedAzkar[index - 1]
                                                .category) ||
                                widget.categoryName ==
                                    AppConstants.mosqueAzkarCategory) {
                              showHeader = true;
                            }
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: DisplayAzkar(
                                zikrEntity: zikr,
                                showCategoryHeader: showHeader,
                              ),
                            );
                          }),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
