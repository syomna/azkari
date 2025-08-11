class QuranPositionModel {
  final int surahNumber;
  final double scrollOffset;

  QuranPositionModel({
    required this.surahNumber,
    required this.scrollOffset,
  });

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'scrollOffset': scrollOffset,
    };
  }

  factory QuranPositionModel.fromJson(Map<String, dynamic> json) {
    return QuranPositionModel(
      surahNumber: json['surahNumber'] as int,
      scrollOffset: json['scrollOffset'] as double,
    );
  }
}