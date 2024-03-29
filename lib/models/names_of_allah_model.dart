class NamesOfAllahModel {
  final int id;
  final String name;
  final String text;

  NamesOfAllahModel({required this.id, required this.name, required this.text});

factory NamesOfAllahModel.fromJson(json) {
    return NamesOfAllahModel(
      id: json['id'],
      name: json['name'],
      text: json['text'],
    );
  }
}
