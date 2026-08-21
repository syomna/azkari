import 'package:azkar_app/features/names_of_allah/data/models/names_of_allah_model.dart';

abstract class NamesOfAllahLocalDataSource {
  Future<List<NamesOfAllahModel>> getNamesOfAllah();
}
