import 'package:azkar_app/features/surah/domain/entities/surah_entity.dart';

class SurahModel extends SurahEntity {
  const SurahModel({required super.name, required super.surah});

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      name: json['name'],
      surah: json['surah'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'surah': surah,
    };
  }

}