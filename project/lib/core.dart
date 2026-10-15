import 'package:flutter/material.dart';
import 'motion.dart';

/// Warna utama eCupFish (diambil dari logo)
class C {
  static const navy = Color(0xFF0F3A63);
  static const blue = Color(0xFF1E6AA8);
  static const sky = Color(0xFF8DB8E8);
  static const skySoft = Color(0x598DB8E8);
  static const field = Color(0xFFEAF2FD);
  static const line = Color(0xFFD5E3F5);
  static const amber = Color(0xFFF5B400);
  static const amberDark = Color(0xFFC98F00);
  static const orange = Color(0xFFFF914D);
  static const bg = Color(0xFFF1F6FD);
  static const ink = Color(0xFF14283D);
  static const mute = Color(0xFF6B7F95);
  static const shadow = Color(0x1A0F3A63);
}

const headerGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [C.navy, C.blue],
);

const darkCard = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0F3A63), Color(0xFF1B5E96)],
);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
        seedColor: C.blue, primary: C.blue, secondary: C.amber),
    scaffoldBackgroundColor: C.bg,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: SmoothPageTransitions(),
      TargetPlatform.iOS: SmoothPageTransitions(),
    }),
  );
}

void push(BuildContext c, Widget w) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => w));

String rp(int v) =>
    'Rp ${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

// ───────────────────────── DATA ─────────────────────────

class Fish {
  final String id, name, seller, type, grade, cat, desc;
  final int price, reviews, stock;
  final double rating;
  const Fish(this.id, this.name, this.seller, this.type, this.grade, this.cat,
      this.price, this.rating, this.reviews, this.desc,
      {this.stock = 5});
}

const _desc =
    'Betta Fish kualitas kontes. Ikan memiliki proporsi badan yang seimbang '
    '(body mass index ideal) dengan form sirip yang rapi dan bukaan ekor yang '
    'maksimal.';

const fishes = [
  Fish('1', 'Plakat Blue Rim', 'Betta King Jakarta', 'Plakat', 'A', 'Contest', 150000, 4.9, 24, _desc),
  Fish('2', 'Halfmoon Galaxy Koi', 'Halfmoon Galaxy', 'Halfmoon', 'S', 'Contest', 325000, 5.0, 12, _desc),
  Fish('3', 'Halfmoon Multi Copper Galaxy', 'Halfmoon Galaxy', 'Halfmoon', 'B', 'Contest', 450000, 4.9, 31, _desc),
  Fish('4', 'Halfmoon Multi Blue Rim Pure', 'Halfmoon Galaxy', 'Halfmoon', 'A', 'Player', 275000, 4.8, 18, _desc),
  Fish('5', 'Halfmoon Multi Fancy Avatar', 'Halfmoon Galaxy', 'Halfmoon', 'S', 'Contest', 850000, 5.0, 9, _desc),
  Fish('6', 'Halfmoon Marble Multi Splash', 'Betta King Jakarta', 'Halfmoon', 'B', 'Pet', 95000, 4.7, 45, _desc),
  Fish('7', 'Nemo Classic Multi', 'Nemo Aquatic Farm', 'Nemo', 'B', 'Pet', 85000, 4.7, 45, _desc),
  Fish('8', 'Super Red Plakat', 'Super Red Betta', 'Plakat', 'A', 'Player', 120000, 4.6, 38, _desc),
];

/// Rincian pesanan sebelum dibayar (dari keranjang atau dari lelang).
class Draft {
  final List<(Fish, int)> lines;
  final List<String> names;
  final int subtotal, ship, guarantee, discount;
  const Draft(this.lines, this.names, this.subtotal,
      {this.ship = 35000, this.guarantee = 15000, this.discount = 0});
  int get total => subtotal + ship + guarantee - discount;
}

class Order {
  final String id, payment;
  final List<String> names;
  final List<(Fish, int)> lines;
  final int subtotal, ship, guarantee, discount, total;
  final DateTime at;
  int step; // 0 dibayar/diproses, 1 diproses, 2 dikirim, 3 tiba
  Order(this.id, this.payment, this.names, this.lines, this.subtotal, this.ship,
      this.guarantee, this.discount, this.total, this.at,
      {this.step = 0});
}

class Cart extends ChangeNotifier {
  final Map<Fish, int> items = {};
  final Set<Fish> selected = {};
  final List<Order> orders = [];

  int get count => items.values.fold(0, (a, b) => a + b);
  List<Fish> get chosen => items.keys.where(selected.contains).toList();
  int get chosenCount => chosen.fold(0, (a, f) => a + items[f]!);
  int get subtotal => chosen.fold(0, (a, f) => a + f.price * items[f]!);
  bool get allSelected => items.isNotEmpty && items.keys.every(selected.contains);

  /// Tambah 1 ke keranjang. Mengembalikan false bila stok sudah habis.
  bool add(Fish f) {
    final q = items[f] ?? 0;
    if (q >= f.stock) return false;
    items[f] = q + 1;
    selected.add(f);
    notifyListeners();
    return true;
  }

  /// Kurangi jumlah, minimal 1. Untuk menghapus item pakai [remove].
  void dec(Fish f) {
    final q = items[f] ?? 0;
    if (q <= 1) return;
    items[f] = q - 1;
    notifyListeners();
  }

  void remove(Fish f) {
    items.remove(f);
    selected.remove(f);
    notifyListeners();
  }

  /// Dipakai tombol "Beli Sekarang": pastikan ikan ada di keranjang & terpilih
  /// tanpa menambah jumlahnya setiap kali ditekan.
  void buyNow(Fish f) {
    if (items.containsKey(f)) {
      selected.add(f);
      notifyListeners();
    } else {
      add(f);
    }
  }

  /// Mengembalikan item yang baru dihapus (tombol "Urungkan").
  void restore(Fish f, int qty, bool wasSelected) {
    items[f] = qty.clamp(1, f.stock).toInt();
    if (wasSelected) selected.add(f);
    notifyListeners();
  }

  void toggle(Fish f) {
    selected.contains(f) ? selected.remove(f) : selected.add(f);
    notifyListeners();
  }

  void toggleAll(bool v) {
    v ? selected.addAll(items.keys) : selected.clear();
    notifyListeners();
  }

  void toggleSeller(String seller, bool v) {
    for (final f in items.keys.where((f) => f.seller == seller)) {
      v ? selected.add(f) : selected.remove(f);
    }
    notifyListeners();
  }

  Draft draft({int discount = 0}) => Draft(
        [for (final f in chosen) (f, items[f]!)],
        [for (final f in chosen) f.name],
        subtotal,
        discount: discount,
      );

  // Draft yang sudah dibuat jadi pesanan (cegah pesanan ganda saat tombol
  // "Konfirmasi Pembayaran" ditekan dua kali).
  final Map<Draft, Order> _placed = {};

  Order place(Draft d, String payment) {
    final done = _placed[d];
    if (done != null) return done;
    final o = Order(
      '#ECF-${DateTime.now().millisecondsSinceEpoch % 100000000}',
      payment,
      d.names,
      d.lines,
      d.subtotal,
      d.ship,
      d.guarantee,
      d.discount,
      d.total,
      DateTime.now(),
    );
    orders.insert(0, o);
    _placed[d] = o;
    for (final l in d.lines) {
      items.remove(l.$1);
      selected.remove(l.$1);
    }
    notifyListeners();
    return o;
  }

  void cancel(Order o) {
    orders.remove(o);
    notifyListeners();
  }

  void advance(Order o) {
    if (o.step < 3) o.step++;
    notifyListeners();
  }
}

final cart = Cart();

// ───────────────────────── HEADER GELOMBANG ─────────────────────────

Path _wave(Size s, double dy) {
  final h = s.height - 6 + dy;
  return Path()
    ..moveTo(0, 0)
    ..lineTo(0, h - 22)
    ..quadraticBezierTo(s.width * .22, h - 52, s.width * .5, h - 26)
    ..quadraticBezierTo(s.width * .8, h + 2, s.width, h - 30)
    ..lineTo(s.width, 0)
    ..close();
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _wave(size, 0);
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _GoldWave extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()..color = C.amber;
    canvas.drawPath(_wave(size, 7), gold);
    final band = Paint()..color = const Color(0xFF3F86C7);
    canvas.drawPath(_wave(size, 3), band);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Latar navy dengan tepi bergelombang dan garis emas (sesuai desain).
class WaveHeader extends StatelessWidget {
  final Widget child;
  const WaveHeader({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _GoldWave())),
        ClipPath(
          clipper: _WaveClipper(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 36),
            decoration: const BoxDecoration(gradient: headerGradient),
            child: child,
          ),
        ),
      ]);
}

class RoundBack extends StatelessWidget {
  const RoundBack({super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.maybePop(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
              color: Color(0x33FFFFFF), shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      );
}

/// Header halaman: tombol kembali + judul (+ konten opsional di bawahnya).
class AppHeader extends StatelessWidget {
  final String title;
  final Widget? bottom;
  final bool back;
  final List<Widget> actions;
  const AppHeader(this.title,
      {super.key, this.bottom, this.back = true, this.actions = const []});

  @override
  Widget build(BuildContext context) => WaveHeader(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(children: [
              Row(children: [
                if (back) ...[const RoundBack(), const SizedBox(width: 12)],
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                ),
                ...actions,
              ]),
              if (bottom != null) ...[const SizedBox(height: 8), bottom!],
            ]),
          ),
        ),
      );
}

/// AppBar polos bergaris emas, untuk layar sekunder.
PreferredSizeWidget gradAppBar(String title,
        {List<Widget> actions = const [], bool back = true}) =>
    AppBar(
      automaticallyImplyLeading: back,
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: Colors.white, fontSize: 17)),
      centerTitle: false,
      foregroundColor: Colors.white,
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(3),
        child: SizedBox(height: 3, width: double.infinity, child: ColoredBox(color: C.amber)),
      ),
      flexibleSpace:
          Container(decoration: const BoxDecoration(gradient: headerGradient)),
    );

// ───────────────────────── WIDGET UMUM ─────────────────────────

class Box extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;
  const Box(
      {super.key,
      required this.child,
      this.margin = const EdgeInsets.only(bottom: 12),
      this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: C.shadow, blurRadius: 12, offset: Offset(0, 4))
          ],
        ),
        child: child,
      );
}

class Pill extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const Pill(this.text, {super.key, this.bg = C.amber, this.fg = C.ink});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class Btn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool gold;
  final IconData? icon;
  final double height;
  const Btn(this.label,
      {super.key, this.onTap, this.gold = false, this.icon, this.height = 50});

  @override
  Widget build(BuildContext context) {
    final small = height < 40;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: onTap == null ? .5 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(small ? 10 : 14),
            gradient: gold
                ? const LinearGradient(colors: [Color(0xFFE0A100), C.amber, Color(0xFFE0A100)])
                : const LinearGradient(colors: [C.navy, C.blue]),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(small ? 10 : 14),
            onTap: onTap,
            child: Center(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(label,
                    style: TextStyle(
                        color: gold ? C.ink : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: small ? 12 : 15)),
                if (icon != null) ...[
                  const SizedBox(width: 6),
                  Icon(icon, size: small ? 14 : 18, color: gold ? C.ink : Colors.white)
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol garis emas (mis. "Google").
class GoldOutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const GoldOutlineBtn(this.label, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: C.amber, width: 1.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: C.amberDark, fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      );
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});
  @override
  Widget build(BuildContext context) => const Row(children: [
        Expanded(child: Divider(color: C.line)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('ATAU MASUK DENGAN',
              style: TextStyle(fontSize: 10, color: C.mute, letterSpacing: 1)),
        ),
        Expanded(child: Divider(color: C.line)),
      ]);
}

/// Teks "Belum punya akun? Daftar di sini." dengan tautan emas.
class LinkLine extends StatelessWidget {
  final String text, link;
  final VoidCallback onTap;
  const LinkLine(this.text, this.link, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => Center(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '$text ', style: const TextStyle(color: C.mute)),
              TextSpan(
                  text: link,
                  style: const TextStyle(
                      color: C.amberDark, fontWeight: FontWeight.w700)),
            ]), style: const TextStyle(fontSize: 12)),
          ),
        ),
      );
}

InputDecoration fieldDec(String hint,
        {Widget? suffix, Widget? prefix, String? error, Color fill = Colors.white}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9AAABC), fontSize: 13),
      errorText: error,
      suffixIcon: suffix,
      prefixIcon: prefix,
      filled: true,
      fillColor: fill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: C.line)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: C.blue, width: 1.5)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: C.line)),
    );

Widget fieldLabel(String t, {bool required = false}) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: t),
        if (required)
          const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
      ]), style: const TextStyle(fontWeight: FontWeight.w600, color: C.navy, fontSize: 14)),
    );

/// Kolom isian berlabel. [password] menambah ikon gembok + tombol mata.
class LField extends StatefulWidget {
  final String label, hint;
  final TextEditingController? controller;
  final bool password, required;
  final String? helper, prefixText;
  final TextInputType? keyboard;
  final IconData? icon;
  final Color fill;
  final ValueChanged<String>? onChanged;
  const LField(this.label,
      {super.key,
      this.hint = '',
      this.controller,
      this.password = false,
      this.required = false,
      this.helper,
      this.prefixText,
      this.keyboard,
      this.icon,
      this.fill = Colors.white,
      this.onChanged});

  @override
  State<LField> createState() => _LFieldState();
}

class _LFieldState extends State<LField> {
  bool hide = true;

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon ?? (widget.password ? Icons.lock_outline : null);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      fieldLabel(widget.label, required: widget.required),
      TextField(
        controller: widget.controller,
        obscureText: widget.password && hide,
        keyboardType: widget.keyboard,
        onChanged: widget.onChanged,
        decoration: fieldDec(
          widget.hint,
          fill: widget.fill,
          prefix: icon != null
              ? Icon(icon, size: 18, color: C.navy)
              : (widget.prefixText != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 14, right: 6),
                      child: Center(
                          widthFactor: 1,
                          child: Text(widget.prefixText!,
                              style: const TextStyle(color: C.mute))))
                  : null),
          suffix: widget.password
              ? IconButton(
                  icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18, color: C.mute),
                  onPressed: () => setState(() => hide = !hide),
                )
              : null,
        ),
      ),
      if (widget.helper != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: [
            const Icon(Icons.info, size: 13, color: C.blue),
            const SizedBox(width: 6),
            Text(widget.helper!, style: const TextStyle(fontSize: 11, color: C.mute)),
          ]),
        ),
    ]);
  }
}

Widget errorBanner(String msg) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFFDECEC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 20),
        const SizedBox(width: 8),
        Expanded(
            child: Text(msg,
                style: const TextStyle(fontSize: 12, color: Color(0xFFB3261E)))),
      ]),
    );

/// Placeholder foto ikan (ganti dengan Image.asset / Image.network foto asli).
class FishThumb extends StatelessWidget {
  final Fish f;
  final bool compact;
  final double? height;
  final String? badge;
  const FishThumb(this.f, {super.key, this.compact = false, this.height, this.badge});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(gradient: darkCard),
        child: Stack(children: [
          Center(
              child: compact
                  ? const Icon(Icons.set_meal, size: 26, color: C.orange)
                  : const Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.set_meal, size: 40, color: C.orange),
                      SizedBox(height: 4),
                      Text('Foto Ikan',
                          style: TextStyle(color: Color(0x99FFFFFF), fontSize: 11)),
                    ])),
          if (!compact)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0x66000000),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(badge ?? 'GRADE ${f.grade}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      );
}

class TrackStepper extends StatelessWidget {
  final int step;
  const TrackStepper(this.step, {super.key});
  static const labels = ['Dibayar', 'Diproses', 'Dikirim', 'Tiba'];

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.only(top: 11),
                child: Container(
                    height: 2, color: i <= step ? C.amber : Colors.black12),
              )),
            Column(children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: i <= step ? C.amber : Colors.black12,
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(labels[i], style: const TextStyle(fontSize: 10)),
            ]),
          ],
        ],
      );
}

String tgl(DateTime d, {bool jam = true}) {
  const bln = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  final t = '${d.day} ${bln[d.month - 1]} ${d.year}';
  if (!jam) return t;
  return '$t, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
