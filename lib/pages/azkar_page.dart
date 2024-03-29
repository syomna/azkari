import 'package:azkar_app/models/azkar_model.dart';
import 'package:azkar_app/models/surah_model.dart';
import 'package:azkar_app/utils/theme.dart';
import 'package:azkar_app/widgets/display_azkar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AzkarPage extends StatefulWidget {
  const AzkarPage(
      {super.key,
      required this.title,
      this.isVarious = false,
      this.listOfAzkar,
      this.surah});

  final String title;
  final bool isVarious;
  final List<AzkarModel>? listOfAzkar;
  final List<SurahModel>? surah;

  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage> {
  TextEditingController searchController = TextEditingController();
  List<AzkarModel>? listOfData;
  List<SurahModel>? listOfSurah;

  @override
  void initState() {
    listOfData = widget.listOfAzkar;
    listOfSurah = widget.surah;
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: Container(
        decoration: const BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/duaa.png'), opacity: 0.08)
                ),
        child: Column(
          children: [
            if (widget.isVarious || widget.surah != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: TextFormField(
                          controller: searchController,
                          onChanged: (v) {
                            if (v.isEmpty) {
                              if (widget.isVarious) {
                                listOfData = widget.listOfAzkar;
                              } else {
                                listOfSurah = widget.surah;
                              }
                              setState(() {});
                            }
                          },
                          cursorColor: mainColor,
                          decoration: InputDecoration(
                              focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(
                                color: mainColor,
                              )),
                              hintText: widget.isVarious
                                  ? 'ابحث عن دعاء'
                                  : 'ابحث عن سورة'),
                        )),
                    MaterialButton(
                      onPressed: () {
                        if (searchController.text.isNotEmpty) {
                          if (widget.isVarious) {
                            listOfData = listOfData
                                ?.where((e) =>
                                    e.category.contains(searchController.text))
                                .toList();
                          } else {
                            listOfSurah = listOfSurah
                                ?.where((e) =>
                                    e.name.contains(searchController.text))
                                .toList();
                          }
                          setState(() {});
                        }
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r)),
                      padding: const EdgeInsets.all(10),
                      color: mainColor,
                      child: const Text(
                        'بحث',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            SizedBox(
              height: widget.isVarious ? 30.h : 20.h,
            ),
            Expanded(
              child: _display(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _display() {
    if (listOfSurah != null) {
      if (listOfSurah!.isEmpty) {
        return  Center(
          child: Text('غير موجود' , style: TextStyle(
                fontSize: 18.sp , fontWeight: FontWeight.bold, color: Colors.white),),
        );
      }
      return Scrollbar(
        child: ListView.separated(
            itemCount: listOfSurah!.length,
            separatorBuilder: (context, index) => SizedBox(
                  height: 20.h,
                ),
            itemBuilder: (context, index) {
              return Padding(
                padding:  EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          color: mainColor),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                        child: Text(
                          '${listOfSurah?[index].name}',
                          style: TextStyle(
                            fontSize: 18.sp,
                             fontWeight: FontWeight.bold , color: Colors.white),
                        ),
                      ),
                    ),
                     SizedBox(
                      height: 10.h,
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                            border: Border.all(color: mainColor),
                            borderRadius: BorderRadius.circular(8.r)),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          child: Text(
                            '${listOfSurah?[index].surah}',
                            style: TextStyle(
                                fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                        ))
                  ],
                ),
              );
            }),
      );
    } else {
      if (listOfData!.isEmpty) {
        return Center(
          child: Text(
            'غير موجود',
            style: TextStyle(
                fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      }
      return Scrollbar(
        child: ListView.separated(
            itemCount: listOfData!.length,
            separatorBuilder: (context, index) => SizedBox(
                  height: 20.h,
                ),
            itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: DisplayAzkar(
                  listOfAzkar: listOfData,
                  index: index,
                  isVarious: widget.isVarious),
            )),
      );
    }
  }
}
