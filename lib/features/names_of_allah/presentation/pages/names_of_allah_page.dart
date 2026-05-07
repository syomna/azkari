import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
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
    final provider = Provider.of<NamesOfAllahProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.namesOfAllah),
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
          : Padding(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
              child: ListView.builder(
                  // gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  //     crossAxisCount: 2),
                  itemCount: provider.namesOfAllahList.length,
                  itemBuilder: (context, index) {
                    return NamesOfAllahCard(
                        item: provider.namesOfAllahList[index]);
                  }),
            ),
    );
  }
}
