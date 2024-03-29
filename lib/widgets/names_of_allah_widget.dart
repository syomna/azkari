import 'dart:async';
import 'dart:math';
import 'package:azkar_app/models/names_of_allah_model.dart';
import 'package:azkar_app/providers/azkar_provider.dart';
import 'package:azkar_app/providers/theme_provider.dart';
import 'package:azkar_app/widgets/card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class NamesOfAllahWidget extends StatefulWidget {
  const NamesOfAllahWidget({Key? key}) : super(key: key);

  @override
  State<NamesOfAllahWidget> createState() => _NamesOfAllahWidgetState();
}

class _NamesOfAllahWidgetState extends State<NamesOfAllahWidget>
    with SingleTickerProviderStateMixin {
  int namesRandomNumber = Random().nextInt(50);
  late AnimationController _controller;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _timer = Timer.periodic(const Duration(seconds: 3), (Timer t) {
      _controller.reset();
      _controller.forward();
      setState(() {
        namesRandomNumber = Random().nextInt(50);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<NamesOfAllahModel> namesOfAllah =
        Provider.of<AzkarProvider>(context).namesOfAllah;
    final themeProvider = Provider.of<ThemeProvider>(context);
    return CardWidget(
      height: MediaQuery.of(context).size.height * 0.14,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _controller.value * 0.5 + 1,
              child: CustomPaint(
                foregroundPainter: GradientTextPainter(
                  gradientColors: themeProvider.isLight
                      ? [
                          Colors.blue,
                          Colors.purple,
                          Colors.black
                              .withOpacity(0.5), // Darker color at the top
                        ]
                      : [
                          Colors.blue.withOpacity(0.9),
                          Colors.purple.withOpacity(0.9),
                          Colors.white
                              .withOpacity(0.7), // Darker color at the top
                        ],
                  text: namesOfAllah[namesRandomNumber].name,
                  textStyle: TextStyle(
                    fontSize: 30.sp,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Set text color to match background
                  ),
                ),
                child: Text(
                  namesOfAllah[namesRandomNumber].name,
                  key: ValueKey<int>(namesRandomNumber),
                  style: TextStyle(
                    fontSize: 30.sp,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    color: Colors.transparent,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel(); // Cancel the timer to avoid memory leaks
    super.dispose();
  }
}

class GradientTextPainter extends CustomPainter {
  final List<Color> gradientColors;
  final String text;
  final TextStyle textStyle;

  GradientTextPainter({
    required this.gradientColors,
    required this.text,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle.copyWith(
          foreground: Paint()
            ..shader = LinearGradient(
              colors: gradientColors,
            ).createShader(rect),
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(
        canvas, Offset(0, (size.height - textPainter.height) / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
