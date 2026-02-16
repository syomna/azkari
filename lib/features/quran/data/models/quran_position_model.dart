class QuranPositionModel {
  final int surahNumber;
  final int ayahNumber;

  QuranPositionModel({
    required this.surahNumber,
    required this.ayahNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
    };
  }

  factory QuranPositionModel.fromJson(Map<String, dynamic> json) {
    return QuranPositionModel(
      surahNumber: json['surahNumber'] as int,
      ayahNumber: json['ayahNumber'] as int,
    );
  }
}