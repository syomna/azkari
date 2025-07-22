import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart'; // For copyText
import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';
import 'package:azkar_app/features/surah/presentation/providers/surah_provider.dart'; // Import SurahProvider
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<SurahEntity> _currentDisplayedSurahs =
      []; // State to hold filtered results

  @override
  void initState() {
    super.initState();
    // Initial data filtering will happen in didChangeDependencies or build
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-filter when dependencies change (e.g., provider updates)
    _filterSurahs(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSurahs(String query) {
    final surahProvider = Provider.of<SurahProvider>(context, listen: false);
    List<SurahEntity> baseList =
        surahProvider.surahList; // Get the full list from the provider

    setState(() {
      if (query.isEmpty) {
        _currentDisplayedSurahs = baseList;
      } else {
        _currentDisplayedSurahs = baseList
            .where((surah) =>
                surah.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final surahProvider = Provider.of<SurahProvider>(context);

    // Handle loading/error states for the SurahProvider
    if (surahProvider.surahStatus == AppLoadingStatus.initial ||
        surahProvider.surahStatus == AppLoadingStatus.loading) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('السور',
                style: TextStyle(fontWeight: FontWeight.bold))),
        body: const Center(
          child: CircularProgressIndicator(color: AppPalette.mainColor),
        ),
      );
    }
    if (surahProvider.surahStatus == AppLoadingStatus.error) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('السور',
                style: TextStyle(fontWeight: FontWeight.bold))),
        body: Center(
          child: Text(
            'Error loading Surahs: ${surahProvider.surahErrorMessage ?? "Unknown error"}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    // Handle case where list might be empty after loading
    if (_currentDisplayedSurahs.isEmpty && _searchController.text.isEmpty) {
      return Scaffold(
          appBar: AppBar(
              title: const Text('السور',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          body: Center(
              child: Text('لا توجد سور متاحة.',
                  style: TextStyle(
                      fontSize: 18.sp, fontWeight: FontWeight.bold))));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'السور', // Fixed title for Surah page
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/duaa.png'),
                opacity: 0.08)), // Keep background consistent
        child: Column(
          children: [
            // Search bar for Surah filtering
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: TextFormField(
                        controller: _searchController,
                        onChanged: (v) {
                          _filterSurahs(v); // Trigger filtering on change
                        },
                        cursorColor: AppPalette.mainColor,
                        decoration: const InputDecoration(
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                              color: AppPalette.mainColor,
                            )),
                            hintText:
                                'ابحث عن سورة'), // Specific hint for Surah
                      )),
                  MaterialButton(
                    onPressed: () {
                      _filterSurahs(_searchController
                          .text); // Trigger filtering on button press
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                    padding: const EdgeInsets.all(10),
                    color: AppPalette.mainColor,
                    child: const Text(
                      'بحث',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 10.h,
            ),
            Text(
              'لنسخ أي سورة، قم بالضغط المطول عليها.',
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
              child: _currentDisplayedSurahs.isEmpty &&
                      _searchController.text.isNotEmpty
                  ? Center(
                      // Show "Not Found" specifically for search results
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
                      child: ListView.separated(
                          itemCount: _currentDisplayedSurahs.length,
                          separatorBuilder: (context, index) => SizedBox(
                                height: 20.h,
                              ),
                          itemBuilder: (context, index) {
                            final surah = _currentDisplayedSurahs[index];
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                        color: AppPalette.mainColor),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.w, vertical: 8.h),
                                      child: Text(
                                        surah.name,
                                        style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10.h,
                                  ),
                                  Container(
                                      width: MediaQuery.of(context).size.width,
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: AppPalette.mainColor),
                                          borderRadius:
                                              BorderRadius.circular(8.r)),
                                      child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.w, vertical: 16.h),
                                          child: GestureDetector(
                                            onLongPress: () {
                                              AppHelpers.copyText(surah.surah);
                                            },
                                            child: Text(
                                              surah.surah,
                                              style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          )))
                                ],
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
