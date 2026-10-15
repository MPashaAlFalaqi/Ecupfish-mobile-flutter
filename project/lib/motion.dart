import 'dart:async';
import 'package:flutter/material.dart';

/// Transisi antar halaman: halaman baru geser + fade dari kanan,
/// halaman di bawahnya bergeser sedikit ke kiri (terasa berlapis & halus).
class SmoothPageTransitions extends PageTransitionsBuilder {
  const SmoothPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic);
    final cover = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic);
    return SlideTransition(
      position: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.07, 0))
          .animate(cover),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.10, 0), end: Offset.zero)
            .animate(enter),
        child: FadeTransition(opacity: enter, child: child),
      ),
    );
  }
}

/// Muncul dengan fade + naik pelan. [index] mengatur jeda antar elemen (stagger).
class Reveal extends StatefulWidget {
  final Widget child;
  final int index;
  final double dy;
  const Reveal({super.key, required this.child, this.index = 0, this.dy = 18});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final ms = widget.index.clamp(0, 12).toInt() * 60;
    if (ms == 0) {
      _c.forward();
    } else {
      _timer = Timer(Duration(milliseconds: ms), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _a,
        child: widget.child,
        builder: (_, child) => Opacity(
          opacity: _a.value.clamp(0.0, 1.0).toDouble(),
          child: Transform.translate(
              offset: Offset(0, (1 - _a.value) * widget.dy), child: child),
        ),
      );
}

/// Efek menekan: mengecil sedikit saat disentuh, lalu kembali dengan halus.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const Pressable(
      {super.key, required this.child, this.onTap, this.scale = .96});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}

/// Membesar sebentar lalu memantul kembali setiap kali [trigger] berubah
/// (dipakai untuk ikon keranjang saat jumlah barang berubah).
class Bump extends StatefulWidget {
  final Object? trigger;
  final Widget child;
  const Bump({super.key, required this.trigger, required this.child});

  @override
  State<Bump> createState() => _BumpState();
}

class _BumpState extends State<Bump> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.28)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30),
    TweenSequenceItem(
        tween: Tween(begin: 1.28, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70),
  ]).animate(_c);

  @override
  void didUpdateWidget(Bump old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// Mengecil/memudar (tinggi → 0) atau sebaliknya saat [visible] berubah.
/// Dipakai untuk menghapus item keranjang dengan halus.
class Collapse extends StatelessWidget {
  final bool visible;
  final Widget child;
  const Collapse({super.key, required this.visible, required this.child});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(end: visible ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
        child: child,
        builder: (_, v, child) => ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: v.clamp(0.0, 1.0).toDouble(),
            child: Opacity(opacity: v.clamp(0.0, 1.0).toDouble(), child: child),
          ),
        ),
      );
}

/// Angka yang berhitung naik/turun dengan halus saat nilainya berubah.
class CountUp extends StatelessWidget {
  final int value;
  final String Function(int) format;
  final TextStyle? style;
  const CountUp(
      {super.key, required this.value, required this.format, this.style});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween<double>(end: value.toDouble()),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => Text(format(v.round()), style: style),
      );
}

/// Berkedip pelan (untuk titik LIVE).
class Pulse extends StatefulWidget {
  final Widget child;
  const Pulse({super.key, required this.child});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: .3, end: 1).animate(
            CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: widget.child,
      );
}
