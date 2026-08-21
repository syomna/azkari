import 'dart:convert';

import 'package:azkar_app/features/azkar/data/datasources/azkar_local_data_source.dart';
import 'package:azkar_app/features/azkar/data/datasources/sqflite/database_helper.dart';
import 'package:azkar_app/features/azkar/data/models/azkar_model.dart';
import 'package:flutter/services.dart';

class AzkarLocalDataSourceImpl extends AzkarLocalDataSource {
  final DatabaseHelper dbHelper;

  AzkarLocalDataSourceImpl({required this.dbHelper});

  List<AzkarModel>? _cachedAzkar;

  @override
  Future<List<AzkarModel>> getAzkar() async {
    if (_cachedAzkar != null) {
      return _cachedAzkar!;
    }
    final jsonString = await rootBundle.loadString('assets/db/azkar.json');
    List<dynamic> jsonData = json.decode(jsonString);
    List<AzkarModel> azkarList =
        jsonData.map((json) => AzkarModel.fromJson(json)).toList();
    _cachedAzkar = azkarList;
    return azkarList;
  }

  @override
  Future<List<AzkarModel>> getCustomAzkar() async {
    return await dbHelper.getCustomAzkar();
  }

  @override
  Future<void> saveCustomAzkar(List<AzkarModel> items) async {
    await dbHelper.insertCustomAzkar(items);
  }

  @override
  Future<void> updateCustomCategory({
    required String originalCategory,
    required String newCategory,
    required List<AzkarModel> items,
  }) async {
    await dbHelper.updateCustomCategory(
      originalCategory: originalCategory,
      newCategory: newCategory,
      items: items,
    );
  }

  @override
  Future<void> deleteCustomCategory(String categoryName) async {
    await dbHelper.deleteCustomCategory(categoryName);
  }
}
