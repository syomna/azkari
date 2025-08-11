import 'dart:math';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/theme/app_palette.dart';
import 'package:azkar_app/features/names_of_allah/presentation/providers/names_of_allah_provider.dart';
import 'package:azkar_app/widgets/card_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NamesOfAllahWidget extends StatefulWidget {
  const NamesOfAllahWidget({super.key});

  @override
  State<NamesOfAllahWidget> createState() => _NamesOfAllahWidgetState();
}

class _NamesOfAllahWidgetState extends State<NamesOfAllahWidget> {
  int namesRandomNumber = Random().nextInt(50);

  @override
  Widget build(BuildContext context) {
    final namesOfAllahProvider = Provider.of<NamesOfAllahProvider>(context);

    const colorizeColors = [
      Colors.blue,
      Colors.purple,
      Colors.white,
    ];

    const colorizeTextStyle = TextStyle(
      fontSize: 30.0,
      fontFamily: 'Tajawal',
    );
    if (namesOfAllahProvider.namesOfAllahStatus == AppLoadingStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppPalette.mainColor,
        ),
      );
    }
    return CardWidget(
      height: MediaQuery.of(context).size.height * 0.14,
      child: DefaultTextStyle(
        style: colorizeTextStyle,
        child: Center(
          child: AnimatedTextKit(
            animatedTexts: namesOfAllahProvider.namesOfAllahList
                .map((e) => ColorizeAnimatedText(
                      e.name,
                      textStyle: colorizeTextStyle,
                      colors: colorizeColors,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
