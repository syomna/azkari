import 'dart:math';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:azkar_app/models/names_of_allah_model.dart';
import 'package:azkar_app/providers/azkar_provider.dart';
import 'package:azkar_app/widgets/card_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NamesOfAllahWidget extends StatefulWidget {
  const NamesOfAllahWidget({Key? key}) : super(key: key);

  @override
  State<NamesOfAllahWidget> createState() => _NamesOfAllahWidgetState();
}

class _NamesOfAllahWidgetState extends State<NamesOfAllahWidget> {
  int namesRandomNumber = Random().nextInt(50);

  @override
  Widget build(BuildContext context) {
    List<NamesOfAllahModel> namesOfAllah =
        Provider.of<AzkarProvider>(context).namesOfAllah;

    const colorizeColors = [
      Colors.blue,
      Colors.purple,
      Colors.white,
    ];

    const colorizeTextStyle = TextStyle(
      fontSize: 30.0,
      fontFamily: 'Tajawal',
    );
    return CardWidget(
      height: MediaQuery.of(context).size.height * 0.14,
      child: DefaultTextStyle(
        style: colorizeTextStyle,
        child: Center(
          child: AnimatedTextKit(
            animatedTexts: namesOfAllah
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