import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/features/names_of_allah/presentation/widgets/names_of_allah_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class NamesOfAllahPage extends StatefulWidget {
  const NamesOfAllahPage({super.key});

  @override
  State<NamesOfAllahPage> createState() => _NamesOfAllahPageState();
}

class _NamesOfAllahPageState extends State<NamesOfAllahPage> {
  // Use a PageController with viewportFraction to see edges of side cards
  final PageController _controller = PageController(viewportFraction: 0.82);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = context.select<NamesOfAllahProvider, AppLoadingStatus>(
        (p) => p.namesOfAllahStatus);
    final errorMessage = context.select<NamesOfAllahProvider, String?>(
        (p) => p.namesOfAllahErrorMessage);
    final namesList =
        context.select<NamesOfAllahProvider, List<NamesOfAllahEntity>>(
            (p) => p.namesOfAllahList);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.namesOfAllah),
        centerTitle: true,
        elevation: 0,
      ),
      body: switch (status) {
        AppLoadingStatus.loading || AppLoadingStatus.initial => const Center(
            child: CircularProgressIndicator(color: AppPalette.mainColor),
          ),
        AppLoadingStatus.error => _buildErrorState(errorMessage),
        AppLoadingStatus.loaded => Padding(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
            child: ListView.builder(
                itemCount: namesList.length,
                itemBuilder: (context, index) {
                  return NamesOfAllahCard(item: namesList[index]);
                }),
          ),
      },
    );
  }

  Widget _buildErrorState(String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 50.h, color: Colors.grey.withValues(alpha: 0.5)),
          SizedBox(height: 12.h),
          Text(
            message ?? 'حدث خطأ في تحميل الأسماء الحسنى',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () =>
                Provider.of<NamesOfAllahProvider>(context, listen: false)
                    .loadNamesOfAllah(),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
