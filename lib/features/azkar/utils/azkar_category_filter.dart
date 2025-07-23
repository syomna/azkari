import 'package:azkar_app/core/constants/app_constants.dart';
import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';

extension AzkarCategoryFilter on List<ZekrEntity> {
  List<ZekrEntity> getMorningAzkar() =>
      where((e) => e.category == AppConstants.morningAzkarCategory).toList();

  List<ZekrEntity> getEveningAzkar() =>
      where((e) => e.category == AppConstants.eveningAzkarCategory).toList();

      List<ZekrEntity> getWakingUpAzkar() =>
      where((e) => e.category == AppConstants.wakingUpAzkarCategory).toList();

      List<ZekrEntity> getPrayerAzkar() =>
      where((e) => e.category == AppConstants.prayerAzkarCategory).toList();

      List<ZekrEntity> getVariousDuaa() =>
      where((e) => e.category != AppConstants.morningAzkarCategory &&
          e.category != AppConstants.eveningAzkarCategory &&
          e.category != AppConstants.wakingUpAzkarCategory &&
          e.category != AppConstants.prayerAzkarCategory).toList();

}
