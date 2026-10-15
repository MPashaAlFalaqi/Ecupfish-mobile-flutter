import 'package:flutter/material.dart';

/// Membuat seluruh layar (didesain untuk lebar 390) menyesuaikan semua ukuran
/// layar Android: HP kecil (320-360), HP besar (412-440), sampai tablet.
/// - Layar dirender pada lebar desain 390, lalu diskalakan seragam ke lebar perangkat.
/// - Di layar lebar (tablet/landscape) tampilan dibatasi [maxWidth] dan dipusatkan.
class ResponsiveFrame extends StatelessWidget {
  final Widget child;
  const ResponsiveFrame({super.key, required this.child});

  static const double designWidth = 390;
  static const double maxWidth = 480;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screen = mq.size;
    final shownW = screen.width > maxWidth ? maxWidth : screen.width;
    final scale = shownW / designWidth;
    final virtualH = screen.height / scale;

    final scaled = mq.copyWith(
      size: Size(designWidth, virtualH),
      padding: mq.padding / scale,
      viewPadding: mq.viewPadding / scale,
      viewInsets: mq.viewInsets / scale,
      systemGestureInsets: mq.systemGestureInsets / scale,
      // batasi pembesaran font sistem agar layout tidak overflow
      textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15),
    );

    return ColoredBox(
      color: const Color(0xFFEEF3FB),
      child: Center(
        child: SizedBox(
          width: shownW,
          height: screen.height,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: designWidth,
              height: virtualH,
              child: MediaQuery(data: scaled, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
