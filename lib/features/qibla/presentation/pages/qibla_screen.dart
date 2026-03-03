import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/di/injection_container.dart';
import 'package:azkar_app/features/qibla/presentation/providers/qibla_provider.dart';
import 'package:azkar_app/features/qibla/presentation/widgets/qibla_body.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class QiblaScreen extends StatelessWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // GetIt provides the instance with all dependencies (UseCase/Repo) injected
      create: (context) => sl<QiblaProvider>()..init(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppConstants.qibla),
          centerTitle: true,
        ),
        body: Consumer<QiblaProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null) {
              return Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10.h,
                children: [
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16.sp, color: Colors.red),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 10.w,
                    children: [
                      _button(
                        context: context,
                        title: 'فتح الاعدادات',
                        icon: CupertinoIcons.location,
                        backgroundColor: Colors.blue.shade500,
                        onPressed: () async {
                          await Geolocator.openLocationSettings();
                        },
                      ),
                      _button(
                          context: context,
                          title: 'تحديث',
                          icon: CupertinoIcons.refresh,
                          onPressed: () {
                            provider.init();
                          }),
                    ],
                  ),
                ],
              ));
            }

            return QiblaBody(
              heading: provider.currentHeading,
              difference: provider.difference,
              isAligned: provider.isAligned,
            );
          },
        ),
      ),
    );
  }

  SizedBox _button(
      {required BuildContext context,
      required VoidCallback onPressed,
      required String title,
      required IconData icon,
      Color? backgroundColor}) {
    return SizedBox(
      height: 35.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        icon: Icon(icon),
        label: Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
