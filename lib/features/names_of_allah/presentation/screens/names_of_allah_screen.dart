import 'package:azkar_app/core/constants/app_strings.dart';
import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/features/names_of_allah/presentation/widgets/names_of_allah_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class NamesOfAllahScreen extends StatefulWidget {
  const NamesOfAllahScreen({super.key});

  @override
  State<NamesOfAllahScreen> createState() => _NamesOfAllahScreenState();
}

class _NamesOfAllahScreenState extends State<NamesOfAllahScreen> {
  final PageController _controller = PageController(viewportFraction: 0.82);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NamesOfAllahProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.namesOfAllah),
        centerTitle: true,
        elevation: 0,
      ),
      body: provider.namesOfAllahStatus == AppLoadingStatus.loading
          ? SizedBox(
              height: 150.h,
              child: const Center(
                child: CircularProgressIndicator(color: AppPalette.mainColor),
              ),
            )
          : provider.namesOfAllahStatus == AppLoadingStatus.error
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48.w, color: Colors.redAccent),
                        SizedBox(height: 12.h),
                        Text(
                          provider.namesOfAllahErrorMessage ??
                              AppStrings.loadError,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14.sp, color: Colors.grey),
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: () => provider.loadNamesOfAllah(),
                          child: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
              color: AppPalette.mainColor,
              onRefresh: () => provider.loadNamesOfAllah(),
              child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
              child: ListView.builder(
                  itemCount: provider.namesOfAllahList.length,
                  itemBuilder: (context, index) {
                    return NamesOfAllahCard(
                        item: provider.namesOfAllahList[index]);
                  }),
            ),
            ),
    );
  }
}
