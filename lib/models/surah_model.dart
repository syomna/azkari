class SurahModel {
  final String name;
  final String surah;

  SurahModel({required this.name, required this.surah});

  factory SurahModel.fromJson(json) {
    return SurahModel(
      name: json['name'],
      surah: json['surah'],
    );
  }
}
