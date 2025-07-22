import 'package:azkar_app/features/azkar/domain/entities/zikr_entity.dart';

class AzkarModel extends ZekrEntity {
  const AzkarModel(
      {required super.category,
      required super.count,
      required super.description,
      required super.reference,
      required super.zekr});

  factory AzkarModel.fromJson(Map<String, dynamic> json) {
    return AzkarModel(
      category: json['category'],
      count: json['count'],
      description: json['description'],
      reference: json['reference'],
      zekr: json['zekr'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'count': count,
      'description': description,
      'reference': reference,
      'zikr': zekr,
    };
  }
}
