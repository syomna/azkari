class AzkarModel {
  final String category;
  final String count;
  final String description;
  final String reference;
  final String zekr;

  AzkarModel(
      {required this.category,
      required this.count,
      required this.description,
      required this.reference,
      required this.zekr});

  factory AzkarModel.fromJson(json) {
    return AzkarModel(
      category: json['category'],
      count: json['count'],
      description: json['description'],
      reference: json['reference'],
      zekr: json['zekr'],
    );
  }
}
