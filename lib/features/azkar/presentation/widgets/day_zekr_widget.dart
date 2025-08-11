import 'dart:math';
import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/core/utils/app_helpers.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';
import 'package:azkar_app/features/azkar/presentation/providers/azkar_provider.dart';
import 'package:azkar_app/widgets/card_widget.dart';
import 'package:azkar_app/widgets/refresh_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DayZekrWidget extends StatefulWidget {
  const DayZekrWidget({super.key});

  @override
  State<DayZekrWidget> createState() => _DayZekrWidgetState();
}

class _DayZekrWidgetState extends State<DayZekrWidget> {
  int _currentZekrIndex = 0; // Renamed for clarity, and initialized to 0

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final azkarProvider = Provider.of<AzkarProvider>(context, listen: false);
    if (azkarProvider.azkarStatus == AppLoadingStatus.loaded &&
        azkarProvider.azkarList.isNotEmpty) {
      if (_currentZekrIndex == 0 && azkarProvider.azkarList.isNotEmpty) {
        _currentZekrIndex = Random().nextInt(azkarProvider.azkarList.length);
      }
    }
  }

  void _refreshZekr(List<ZekrEntity> azkarList) {
    if (azkarList.isNotEmpty) {
      setState(() {
        _currentZekrIndex = Random().nextInt(azkarList.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final azkarProvider = Provider.of<AzkarProvider>(context);

    var formatDay = DateFormat('EEEE', 'ar');

    var format = DateFormat.yMMMMd('ar');
    String dateString = format.format(DateTime.now());
    String dateDay = formatDay.format(DateTime.now());

    if (azkarProvider.azkarStatus == AppLoadingStatus.initial ||
        azkarProvider.azkarStatus == AppLoadingStatus.loading) {
      return CardWidget(
          // Show loading inside the CardWidget
          height: MediaQuery.of(context).size.height * 0.18,
          child: const Center(
            child: CircularProgressIndicator(color: AppPalette.mainColor),
          ));
    }
    if (azkarProvider.azkarStatus == AppLoadingStatus.error) {
      return CardWidget(
          // Show error inside the CardWidget
          height: MediaQuery.of(context).size.height * 0.18,
          child: Center(
            child: Text(
              'Error loading Zekr: ${azkarProvider.azkarErrorMessage ?? "Unknown error"}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ));
    }
    if (azkarProvider.azkarList.isEmpty) {
      return CardWidget(
          height: MediaQuery.of(context).size.height * 0.18,
          child: const Center(
              child: Text('No Azkar available to display.',
                  textAlign: TextAlign.center)));
    }
    if (_currentZekrIndex >= azkarProvider.azkarList.length) {
      _currentZekrIndex = 0;
    }

    ZekrEntity currentZekr = azkarProvider.azkarList[_currentZekrIndex];

    return GestureDetector(
      onLongPress: () {
        AppHelpers.copyText(currentZekr.zekr);
      },
      child: CardWidget(
          height: MediaQuery.of(context).size.height * 0.18,
          child: Scrollbar(
            thickness: 6.w,
            radius: Radius.circular(8.r),
            trackVisibility: true,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$dateDay ، $dateString',
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                          onPressed: () =>
                              _refreshZekr(azkarProvider.azkarList),
                          icon: const RefreshIcon())
                    ],
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Text(
                    currentZekr.zekr,
                    style:
                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          )),
    );
  }
}
