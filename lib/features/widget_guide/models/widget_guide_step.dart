import 'package:flutter/material.dart';

class WidgetGuideStep {
  const WidgetGuideStep({
    required this.title,
    required this.description,
    required this.imagePath,
    this.imageFit = BoxFit.contain,
    this.imageAlignment = Alignment.center,
    this.isIntro = false,
  });

  final String title;
  final String description;
  final String imagePath;
  final BoxFit imageFit;
  final Alignment imageAlignment;
  final bool isIntro;
}