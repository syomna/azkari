class City {
  const City({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.countryCode,
    required this.lat,
    required this.lng,
    required this.population,
  });

  final int id;
  final String name;
  final String arabicName;
  final String countryCode;
  final double lat;
  final double lng;
  final int population;

  String get displayName => arabicName.isNotEmpty ? arabicName : name;

  factory City.fromList(List<dynamic> row) => City(
        id: row[0] as int,
        name: row[1] as String,
        arabicName: row[2] as String,
        countryCode: row[3] as String,
        lat: (row[4] as num).toDouble(),
        lng: (row[5] as num).toDouble(),
        population: row[6] as int,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is City && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
