import 'package:equatable/equatable.dart';

class NamesOfAllahEntity extends Equatable {
  final int id;
  final String name;
  final String text;

  const NamesOfAllahEntity({required this.id, required this.name, required this.text});
  
  @override
  List<Object?> get props => [id, name, text];
  

}