import 'package:azkar_app/features/azkar/data/models/azkar_model.dart';

abstract class AzkarLocalDataSource {
  Future<List<AzkarModel>> getAzkar();
  Future<List<AzkarModel>> getCustomAzkar();
  Future<void> saveCustomAzkar(List<AzkarModel> items);
  Future<void> updateCustomCategory({
    required String originalCategory,
    required String newCategory,
    required List<AzkarModel> items,
  });
  Future<void> deleteCustomCategory(String categoryName);
}
