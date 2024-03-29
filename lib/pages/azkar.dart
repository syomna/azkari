import 'package:azkar_app/models/azkar_model.dart';
import 'package:azkar_app/pages/azkar_page.dart';
import 'package:azkar_app/providers/azkar_provider.dart';
import 'package:azkar_app/widgets/component.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Azkar extends StatelessWidget {
  const Azkar({super.key});

  @override
  Widget build(BuildContext context) {
    List<AzkarModel> allAzkar = Provider.of<AzkarProvider>(context).allAzkar;
    return Scaffold(
      appBar: AppBar(
        title: const Text('أذكار و أدعية', style: TextStyle(fontWeight: FontWeight.bold),),
      ),
      body:   Padding(
        padding:  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
             const SizedBox(
              height: 20,
            ),
             Component(text: "أذكار الصباح", img: "sun" , page: AzkarPage(title: "أذكار الصباح", listOfAzkar: allAzkar.where((e) => e.category == "أذكار الصباح").toList())),
             const SizedBox(
              height: 20,
            ),
             Component(text: "أذكار المساء", img: "night" , page: AzkarPage(title: "أذكار المساء", listOfAzkar: allAzkar.where((e) => e.category == "أذكار المساء").toList(),)),
             const SizedBox(
              height: 20,
            ),
             Component(text: "أذكار الاستيقاظ من النوم", img: "get-up" , page: AzkarPage(title: "أذكار الاستيقاظ من النوم", listOfAzkar: allAzkar.where((e) => e.category == "أذكار الاستيقاظ من النوم").toList())),
             const SizedBox(
              height: 20,
            ),
             Component(text: "أذكار الآذان", img: "temple" , page: AzkarPage(title: "أذكار الآذان", listOfAzkar: allAzkar.where((e) => e.category == "أذكار الآذان").toList())),
             const SizedBox(
              height: 20,
            ),
             Component(text: "سور قصيرة للصلاة", img: "mat" , page: AzkarPage(title: "سور قصيرة للصلاة", surah: Provider.of<AzkarProvider>(context).surah,)),
             const SizedBox(
              height: 20,
            ),
             Component(text: "أدعية متنوعة", img: "duaa" ,
             
              page: AzkarPage(title: "أدعية متنوعة", isVarious: true, listOfAzkar: allAzkar.where((e) => e.category != "أذكار الصباح" && e.category != "أذكار المساء" && e.category != "أذكار الاستيقاظ من النوم" && e.category != "أذكار الآذان").toList())),
          ],
        ),
      ),
    );
  }
}
