import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';

class NamesOfAllahModel extends NamesOfAllahEntity{
  const NamesOfAllahModel({required super.id, required super.name, required super.text});

  factory NamesOfAllahModel.fromJson(Map<String, dynamic> json) {
    return NamesOfAllahModel(
      id: json['id'],
      name: json['name'],
      text: json['text'],
    );
  }
Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'text': text,
    };
  }

}