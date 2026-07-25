import 'package:flutter/material.dart';

class FullScreenScreenshot extends StatelessWidget {
  const FullScreenScreenshot({
    super.key,
    required this.imagePath,
  });

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const ColoredBox(
                    color: Colors.transparent,
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Hero(
                    tag: imagePath,
                    child: InteractiveViewer(
                      minScale: 0.9,
                      maxScale: 4,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 10,
                end: 12,
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
