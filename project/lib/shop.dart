import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'account.dart';
import 'core.dart';
import 'extra.dart';
import 'motion.dart';
import 'order.dart';

// ───────────── Tambah ke keranjang (dengan umpan balik) ─────────────
void addToCart(BuildContext context, Fish f) {
  final ok = cart.add(f);
  final nav = Navigator.of(context);
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
    content: Text(ok ? '${f.name} masuk keranjang' : 'Stok ${f.name} hanya ${f.stock}'),
    action: ok
        ? SnackBarAction(
            label: 'Lihat',
            textColor: C.amber,
            onPressed: () =>
                nav.push(MaterialPageRoute(builder: (_) => const CartScreen())))
        : null,
  ));
  if (ok) HapticFeedback.lightImpact();
}

// ───────────── Ikon keranjang dengan badge ─────────────
class CartIcon extends StatelessWidget {
  final Color color;
  const CartIcon({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: cart,
        builder: (context, _) => IconButton(
          onPressed: () => push(context, const CartScreen()),
          icon: Bump(
            trigger: cart.count,
            child: Badge(
              label: Text('${cart.count}'),
              isLabelVisible: cart.count > 0,
              child: Icon(Icons.shopping_cart_outlined, color: color),
            ),
          ),
        ),
      );
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badge;
  const _RoundIcon(this.icon, this.onTap, {this.badge = 0});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Pressable(
          onTap: onTap,
          scale: .9,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: C.line)),
            child: Bump(
              trigger: badge,
              child: Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                child: Icon(icon, size: 20, color: C.navy),
              ),
            ),
          ),
        ),
      );
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Pulse(child: CircleAvatar(radius: 3, backgroundColor: Colors.white)),
          SizedBox(width: 5),
          Text('LIVE',
              style: TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      );
}

// ───────────── Banner geser (auto-play) ─────────────
class _BannerData {
  final Gradient gradient;
  final Widget tag;
  final String title, button;
  final IconData? icon;
  final VoidCallback Function(BuildContext) onTap;
  const _BannerData(this.gradient, this.tag, this.title, this.button, this.icon, this.onTap);
}

class _HomeBanner extends StatefulWidget {
  const _HomeBanner();
  @override
  State<_HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<_HomeBanner> {
  static final _slides = <_BannerData>[
    _BannerData(
      darkCard,
      const Row(children: [
        _LivePill(),
        SizedBox(width: 6),
        Pill('19.00 WIB', bg: Color(0x33FFFFFF), fg: Colors.white),
      ]),
      'Lelang Betta\nMalam Ini',
      'LIHAT LIVE',
      null,
      (c) => () => push(c, const AuctionScreen()),
    ),
    _BannerData(
      const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E96), Color(0xFF0F3A63)]),
      const Row(children: [
        Pill('PROMO', bg: C.amber, fg: C.ink),
        SizedBox(width: 6),
        Pill('CUPANG10', bg: Color(0x33FFFFFF), fg: Colors.white),
      ]),
      'Diskon Rp10.000\nPembelian Pertama',
      'BELANJA',
      Icons.local_offer_rounded,
      (c) => () => push(c, const SearchScreen()),
    ),
    _BannerData(
      const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14283D), Color(0xFF1E6AA8)]),
      const Row(children: [
        Pill('GARANSI', bg: Color(0x33FFFFFF), fg: Colors.white),
        SizedBox(width: 6),
        Pill('100%', bg: C.amber, fg: C.ink),
      ]),
      'Ikan Mati di Jalan?\nUang Kembali',
      'LIHAT KATALOG',
      Icons.verified_user_rounded,
      (c) => () => push(c, const SearchScreen()),
    ),
  ];

  final PageController _ctrl = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted || !_ctrl.hasClients) return;
      _ctrl.animateToPage((_page + 1) % _slides.length,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic);
    });
  }

  bool _onScroll(ScrollNotification n) {
    // berhenti auto-play saat disentuh pengguna, lanjut lagi setelah selesai
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _timer?.cancel();
    } else if (n is ScrollEndNotification) {
      _schedule();
    }
    return false;
  }

  Widget _art(_BannerData d) => Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x66FFFFFF))),
        child: Center(
          child: d.icon == null
              ? const Text('Foto\nIkan',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 11))
              : Icon(d.icon, size: 44, color: C.amber),
        ),
      );

  Widget _slide(BuildContext context, int i) {
    final d = _slides[i];
    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(gradient: d.gradient, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Expanded(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                d.tag,
                const SizedBox(height: 10),
                Text(d.title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                SizedBox(
                  width: d.button.length > 10 ? 146 : 124,
                  child: Btn(d.button,
                      gold: true,
                      height: 32,
                      icon: Icons.arrow_forward,
                      onTap: d.onTap(context)),
                ),
              ]),
        ),
        const SizedBox(width: 8),
        _art(d),
      ]),
    );
    // sedikit mengecil pada slide yang sedang bergeser keluar
    return AnimatedBuilder(
      animation: _ctrl,
      child: card,
      builder: (_, child) {
        double delta = 0;
        if (_ctrl.hasClients && _ctrl.position.haveDimensions) {
          delta = ((_ctrl.page ?? _page.toDouble()) - i).abs();
        } else {
          delta = i == _page ? 0 : 1;
        }
        final scale = 1 - delta.clamp(0.0, 1.0).toDouble() * .06;
        return Transform.scale(scale: scale, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        SizedBox(
          height: 166,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: _slide,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < _slides.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _timer?.cancel();
                _ctrl.animateToPage(i,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOutCubic);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? C.amber : C.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ]),
      ]);
}

// ───────────── Beranda ─────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  static const cats = ['All', 'Plakat', 'Halfmoon', 'Nemo'];
  static const _whiteGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Colors.white]);
  String cat = 'All';

  @override
  Widget build(BuildContext context) {
    final list = fishes.where((f) => cat == 'All' || f.type == cat).toList();
    return ListView(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 24),
      children: [
        Reveal(
          child: Row(children: [
            Image.asset('assets/images/logo.png', height: 56),
            const Spacer(),
            ListenableBuilder(
              listenable: cart,
              builder: (_, __) => _RoundIcon(Icons.shopping_cart_outlined,
                  () => push(context, const CartScreen()),
                  badge: cart.count),
            ),
            _RoundIcon(Icons.chat_bubble_outline, () => push(context, const MessagesScreen())),
            _RoundIcon(Icons.notifications_none, () => push(context, const NotificationScreen())),
          ]),
        ),
        const SizedBox(height: 12),
        Reveal(
          index: 1,
          child: Pressable(
            scale: .98,
            onTap: () => push(context, const SearchScreen()),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: C.mute),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('Cari Cupang, Peleti, dll...',
                        style: TextStyle(color: Color(0xFF9AAABC), fontSize: 13))),
                Container(
                  width: 72,
                  height: double.infinity,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFFE0A100), C.amber])),
                  child: const Text('Cari',
                      style: TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Reveal(index: 2, child: _HomeBanner()),
        const SizedBox(height: 12),
        Reveal(
          index: 3,
          child: Row(children: [
            for (final c in cats)
              Expanded(
                child: Pressable(
                  scale: .93,
                  onTap: () {
                    if (cat != c) {
                      HapticFeedback.selectionClick();
                      setState(() => cat = c);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    height: 36,
                    margin: EdgeInsets.only(right: c == cats.last ? 0 : 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: cat == c ? headerGradient : _whiteGradient,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cat == c ? C.navy : C.line),
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 280),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cat == c ? Colors.white : C.navy),
                      child: Text(c),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 14),
        Reveal(
          index: 4,
          child: Row(children: [
            const Text('Katalog Cupang',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => push(context, const SearchScreen()),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Lihat Semua →',
                    style: TextStyle(
                        color: C.amberDark, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        // Tinggi grid berubah halus saat kategori diganti; kartu muncul bergantian.
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: .7,
            children: [
              for (var i = 0; i < list.length; i++)
                Reveal(
                  key: ValueKey('$cat-${list[i].id}'),
                  index: 5 + i,
                  child: FishCard(list[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class FishCard extends StatelessWidget {
  final Fish f;
  const FishCard(this.f, {super.key});

  @override
  Widget build(BuildContext context) {
    void open() => push(context, ProductDetailScreen(f));
    return Pressable(
      scale: .97,
      onTap: open,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: C.shadow, blurRadius: 12, offset: Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Hero(tag: 'fish-${f.id}', child: FishThumb(f)))),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.star, size: 13, color: C.amber),
            Text(' ${f.rating}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            Text(' (${f.reviews})', style: const TextStyle(fontSize: 10, color: C.mute)),
          ]),
          Text(f.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Text(rp(f.price),
              style: const TextStyle(fontWeight: FontWeight.w800, color: C.navy, fontSize: 13)),
          const SizedBox(height: 6),
          // sebelumnya tanpa onTap sehingga tampak pudar (seperti nonaktif)
          Btn('Lihat', gold: true, height: 30, onTap: open),
        ]),
      ),
    );
  }
}

// ───────────── Pencarian + Filter ─────────────
class SearchScreen extends StatefulWidget {
  final String initial;
  const SearchScreen({super.key, this.initial = ''});
  @override
  State<SearchScreen> createState() => _SearchState();
}

class _SearchState extends State<SearchScreen> {
  static const maxPrice = 1000000.0;
  late final TextEditingController qc = TextEditingController(text: widget.initial);
  final minC = TextEditingController();
  final maxC = TextEditingController();
  RangeValues price = const RangeValues(0, maxPrice);
  String? cat;
  bool open = true;

  @override
  void dispose() {
    qc.dispose();
    minC.dispose();
    maxC.dispose();
    super.dispose();
  }

  void _syncFields() {
    minC.text = price.start > 0 ? price.start.round().toString() : '';
    maxC.text = price.end < maxPrice ? price.end.round().toString() : '';
  }

  void _fromFields() {
    final lo = (int.tryParse(minC.text) ?? 0).clamp(0, 1000000).toDouble();
    final hi = (int.tryParse(maxC.text) ?? 1000000).clamp(0, 1000000).toDouble();
    setState(() => price = lo <= hi ? RangeValues(lo, hi) : RangeValues(hi, lo));
  }

  void _reset() => setState(() {
        price = const RangeValues(0, maxPrice);
        cat = null;
        minC.clear();
        maxC.clear();
      });

  Widget _priceField(String hint, TextEditingController c) => Expanded(
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          onChanged: (_) => _fromFields(),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 10, right: 6),
              child: Center(
                  widthFactor: 1,
                  child: Text('Rp',
                      style: TextStyle(color: C.amber, fontWeight: FontWeight.w800, fontSize: 12))),
            ),
            isDense: true,
            filled: true,
            fillColor: const Color(0x22FFFFFF),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0x33FFFFFF))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0x33FFFFFF))),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final q = qc.text.toLowerCase();
    final res = fishes
        .where((f) =>
            (f.name.toLowerCase().contains(q) || f.seller.toLowerCase().contains(q)) &&
            f.price >= price.start &&
            (price.end >= maxPrice || f.price <= price.end) &&
            (cat == null || f.cat == cat))
        .toList();
    return Scaffold(
      body: Column(children: [
        WaveHeader(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(children: [
                const RoundBack(),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: qc,
                    autofocus: widget.initial.isEmpty,
                    onChanged: (_) => setState(() {}),
                    decoration: fieldDec('Cari cupang, peternak...',
                        prefix: const Icon(Icons.search, size: 20, color: C.mute)),
                  ),
                ),
              ]),
            ),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  gradient: darkCard, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => setState(() => open = !open),
                    child: Row(children: [
                      const Icon(Icons.tune, color: C.amber, size: 18),
                      const SizedBox(width: 6),
                      const Text('Filter',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      Icon(open ? Icons.expand_less : Icons.expand_more, color: Colors.white),
                    ]),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _reset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white54)),
                      child: const Text('Reset Filter',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
                if (open) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    const Text('Rentang Harga',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const Spacer(),
                    Text(
                        'Rp ${(price.start / 1000).round()}rb – ${price.end >= maxPrice ? 'Rp 1 jt+' : 'Rp ${(price.end / 1000).round()}rb'}',
                        style: const TextStyle(
                            color: C.amber, fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: C.amber,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: C.amber,
                      overlayColor: const Color(0x33F5B400),
                    ),
                    child: RangeSlider(
                      values: price,
                      min: 0,
                      max: maxPrice,
                      divisions: 100,
                      onChanged: (v) {
                        setState(() => price = v);
                        _syncFields();
                      },
                    ),
                  ),
                  Row(children: [
                    _priceField('Min', minC),
                    const SizedBox(width: 10),
                    _priceField('Max', maxC),
                  ]),
                  const SizedBox(height: 12),
                  const Text('Grade', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(children: [
                    for (final g in ['Contest', 'Player', 'Pet'])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => cat = cat == g ? null : g),
                          child: Container(
                            height: 36,
                            margin: EdgeInsets.only(right: g == 'Pet' ? 0 : 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: cat == g ? C.amber : const Color(0x22FFFFFF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0x44FFFFFF)),
                            ),
                            child: Text(g,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: cat == g ? C.ink : Colors.white)),
                          ),
                        ),
                      ),
                  ]),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              const Text('Hasil Pencarian',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              Pill('${res.length} Ditemukan', bg: C.field, fg: C.blue),
            ]),
            const SizedBox(height: 10),
            if (res.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Tidak ada ikan yang cocok')),
              ),
            for (final f in res)
              GestureDetector(
                onTap: () => push(context, ProductDetailScreen(f)),
                child: Box(
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                          width: 76,
                          height: 92,
                          child: FishThumb(f, badge: f.cat.toUpperCase())),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 92,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(f.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 2),
                          Row(children: [
                            const Icon(Icons.star, size: 13, color: C.amber),
                            Text(' ${f.rating}  ',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            Expanded(
                              child: Text('Grade ${f.cat} / ${f.type}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: C.mute)),
                            ),
                          ]),
                          const Spacer(),
                          Row(children: [
                            Expanded(
                              child: Text(rp(f.price),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, color: C.navy, fontSize: 14)),
                            ),
                            GestureDetector(
                              onTap: () => addToCart(context, f),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(
                                      colors: [Color(0xFFE0A100), C.amber]),
                                ),
                                child: const Icon(Icons.shopping_cart_outlined,
                                    size: 18, color: C.ink),
                              ),
                            ),
                          ]),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ───────────── Detail Produk ─────────────
class ProductDetailScreen extends StatelessWidget {
  final Fish f;
  const ProductDetailScreen(this.f, {super.key});

  Widget _bar(String label, double v) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(children: [
          SizedBox(
              width: 104,
              child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  color: C.amber,
                  backgroundColor: Colors.white24),
            ),
          ),
          SizedBox(
              width: 38,
              child: Text('${(v * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))),
        ]),
      );

  Widget _info(String k, String v) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: const TextStyle(fontSize: 10, color: C.mute)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListView(padding: EdgeInsets.zero, children: [
          SizedBox(
            height: 320,
            child: Stack(children: [
              Positioned.fill(
                child: Hero(
                  tag: 'fish-${f.id}',
                  child: const DecoratedBox(
                      decoration: BoxDecoration(gradient: darkCard)),
                ),
              ),
              const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.set_meal, size: 70, color: C.orange),
                SizedBox(height: 4),
                Text('Foto Ikan', style: TextStyle(color: Colors.white54)),
              ])),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                  child: Row(children: [
                    const RoundBack(),
                    const Spacer(),
                    const CartIcon(),
                  ]),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 40,
                child: Row(children: [
                  Container(
                      width: 18,
                      height: 5,
                      decoration: BoxDecoration(
                          color: C.amber, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 4),
                  const CircleAvatar(radius: 2.5, backgroundColor: Colors.white38),
                  const SizedBox(width: 4),
                  const CircleAvatar(radius: 2.5, backgroundColor: Colors.white38),
                ]),
              ),
              Positioned(
                right: 16,
                bottom: 34,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    CircleAvatar(radius: 3, backgroundColor: Colors.red),
                    SizedBox(width: 5),
                    Text('Live Preview',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
          ),
          Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              decoration: const BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 6, children: [
                  Pill('GRADE ${f.grade}'),
                  Pill(f.type.toUpperCase(), bg: C.field, fg: C.blue),
                  const Pill('MALE', bg: C.field, fg: C.blue),
                ]),
                const SizedBox(height: 10),
                Text('${f.name} – Grade ${f.grade}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(rp(f.price),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800, color: C.navy)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF6DD),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: C.amber)),
                    child: Text('Stock: ${f.stock}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.amberDark)),
                  ),
                ]),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      gradient: darkCard, borderRadius: BorderRadius.circular(20)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                            color: C.amber, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.memory, size: 18, color: C.ink),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('AI Health & Grade\nScanner',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0x22FFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24)),
                        child: const Text('✓ Terverifikasi',
                            style: TextStyle(color: Colors.white, fontSize: 9)),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      SizedBox(
                        width: 88,
                        height: 88,
                        child: Stack(alignment: Alignment.center, children: [
                          const SizedBox.expand(
                              child: CircularProgressIndicator(
                                  value: .98,
                                  strokeWidth: 8,
                                  color: C.amber,
                                  backgroundColor: Colors.white24)),
                          const Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('98%',
                                style: TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                            Text('Sehat', style: TextStyle(color: Colors.white70, fontSize: 9)),
                          ]),
                        ]),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Health Status:',
                              style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text('Sehat (98%)',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                          SizedBox(height: 6),
                          Text('Grade Assessment:',
                              style: TextStyle(color: Colors.white70, fontSize: 11)),
                          SizedBox(height: 3),
                          Pill('CONTEST GRADE'),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    _bar('Pola Sirip', .97),
                    _bar('Kebersihan Sisik', .99),
                    _bar('Keaktifan Gerak', .98),
                    const SizedBox(height: 10),
                    const Text(
                        '*Analisis berdasarkan pola sirip, kebersihan sisik, dan keaktifan gerakan pada video terbaru.',
                        style: TextStyle(color: Colors.white54, fontSize: 9, fontStyle: FontStyle.italic)),
                  ]),
                ),
                const SizedBox(height: 16),
                const Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(f.desc, style: const TextStyle(color: C.mute, fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                Row(children: [
                  _info('Umur', '4,5 Bulan'),
                  const SizedBox(width: 8),
                  _info('Ukuran', 'medium'),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _info('Warna', 'Clean Blue Rim (No leaks)'),
                  const SizedBox(width: 8),
                  _info('Mental', 'Fighter / Sangat Agresif'),
                ]),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ]),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [BoxShadow(color: C.shadow, blurRadius: 14)],
          ),
          child: SafeArea(
            top: false,
            child: Row(children: [
              GestureDetector(
                onTap: () => push(context, ChatScreen(seller: f.seller)),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: C.line)),
                  child: const Icon(Icons.chat_bubble_outline, color: C.navy),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Btn('Beli / Bid Sekarang',
                    icon: Icons.arrow_forward,
                    onTap: () {
                      // tidak menambah jumlah lagi bila sudah ada di keranjang
                      cart.buyNow(f);
                      push(context, const CartScreen());
                    }),
              ),
            ]),
          ),
        ),
      );
}

// ───────────── Lelang Live ─────────────
class AuctionScreen extends StatefulWidget {
  final bool tab;
  const AuctionScreen({super.key, this.tab = false});
  @override
  State<AuctionScreen> createState() => _AuctionState();
}

class _AuctionState extends State<AuctionScreen> {
  late final Timer _timer;
  int secs = 322;
  int current = 160000;
  int step = 10000;
  bool wonShown = false;
  final bids = <MapEntry<String, int>>[
    const MapEntry('User B', 160000),
    const MapEntry('User A', 150000),
  ];

  bool get ended => secs == 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || secs == 0) return;
      setState(() => secs--);
      if (secs == 0 && bids.first.key == 'Anda' && !wonShown) {
        wonShown = true;
        push(context, MenangLelangScreen(amount: current));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get clock {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(secs ~/ 3600)}:${two(secs % 3600 ~/ 60)}:${two(secs % 60)}';
  }

  void _bid() {
    if (ended) return;
    setState(() {
      current += step;
      bids.insert(0, MapEntry('Anda', current));
    });
  }

  Widget _pill(Widget child, {Color? bg, Color? border}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg ?? const Color(0x33000000),
          borderRadius: BorderRadius.circular(20),
          border: border == null ? null : Border.all(color: border),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final winner = bids.first;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B2E50), Color(0xFF14497A), Color(0xFF1B5E96)])),
        child: Column(children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 10, 16, 16), children: [
                Row(children: [
                  if (!widget.tab) ...[const RoundBack(), const SizedBox(width: 12)],
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Lelang Halfmoon Multi',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
                      Text('Betta King Jakarta · Lot #12',
                          style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ]),
                  ),
                  GestureDetector(
                    // demo: ketuk pewaktu untuk melompat ke akhir lelang
                    onTap: () => setState(() => secs = secs > 3 ? 3 : secs),
                    child: ended
                        ? _pill(
                            const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.hourglass_bottom, size: 14, color: Color(0xFFFFB4A8)),
                              SizedBox(width: 4),
                              Text('BERAKHIR',
                                  style: TextStyle(
                                      color: Color(0xFFFFB4A8),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11)),
                            ]),
                            border: const Color(0xFFB5574A))
                        : _pill(
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.hourglass_empty, size: 14, color: C.amber),
                              const SizedBox(width: 4),
                              Text(clock,
                                  style: const TextStyle(
                                      color: C.amber, fontWeight: FontWeight.w800, fontSize: 12)),
                            ]),
                            border: C.amber),
                  ),
                ]),
                const SizedBox(height: 14),
                Container(
                  height: 214,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2E7CC4), Color(0xFF1B5E96)]),
                    border: Border.all(color: C.sky, width: 1.5),
                  ),
                  child: Stack(children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: ended
                          ? _pill(const Text('● SELESAI',
                              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800)))
                          : _pill(
                              const Text('● LIVE',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                              bg: Colors.red),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: _pill(const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.visibility_outlined, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text('1,2K', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ])),
                    ),
                    const Align(
                      alignment: Alignment(0, -.35),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        CircleAvatar(
                            radius: 26,
                            backgroundColor: Color(0x55FFFFFF),
                            child: Icon(Icons.play_arrow, color: Colors.white, size: 32)),
                        SizedBox(height: 6),
                        Text('Video Live Stream Peternak',
                            style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ]),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            color: const Color(0x99062040),
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Penawaran Tertinggi',
                                  style: TextStyle(color: Colors.white70, fontSize: 10)),
                              Text(rp(current),
                                  style: const TextStyle(
                                      color: C.amber, fontWeight: FontWeight.w800, fontSize: 20)),
                            ]),
                          ),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            const Text('Oleh', style: TextStyle(color: Colors.white70, fontSize: 10)),
                            Text(winner.key,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                          ]),
                        ]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  const Text('Riwayat Penawaran',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  const Spacer(),
                  Pill('${bids.length} bid'),
                ]),
                const SizedBox(height: 10),
                for (var i = 0; i < bids.take(5).length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: i == 0 ? C.amber : Colors.white24),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: i == 0 && ended ? C.amber : Colors.white,
                        child: Text(
                            bids[i].key == 'Anda' ? 'A' : bids[i].key.substring(bids[i].key.length - 1),
                            style: const TextStyle(
                                color: C.navy, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                              i == 0 && ended ? '${bids[i].key} 🏆 Pemenang' : bids[i].key,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(
                              i == 0 && ended
                                  ? 'Lelang berakhir'
                                  : (i == 0 ? '1 mnt lalu' : '${i * 2 + 1} mnt lalu'),
                              style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        if (i == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: C.amber, borderRadius: BorderRadius.circular(6)),
                            child: const Text('TERTINGGI',
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: C.ink)),
                          ),
                        Text(rp(bids[i].value),
                            style: TextStyle(
                                color: i == 0 ? C.amber : Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                      ]),
                    ]),
                  ),
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: ended
                  ? Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFDECEC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade100)),
                        child: Row(children: [
                          const Icon(Icons.info_outline, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(TextSpan(children: [
                              const TextSpan(text: 'Lelang ini sudah berakhir. Pemenangnya adalah '),
                              TextSpan(
                                  text: winner.key,
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                              const TextSpan(text: ' dengan penawaran '),
                              TextSpan(
                                  text: rp(current),
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                              const TextSpan(text: '.'),
                            ]), style: const TextStyle(fontSize: 11, color: Color(0xFF8A2A22))),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      Btn('Lihat lelang lainnya', onTap: () {
                        if (widget.tab) {
                          setState(() {});
                        } else {
                          Navigator.popUntil(context, (r) => r.isFirst);
                        }
                      }),
                    ])
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        const Text('Tempatkan Penawaran',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        const Spacer(),
                        const Text('Kenaikan minimum Rp 10.000',
                            style: TextStyle(fontSize: 10, color: C.mute)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        for (final v in [10000, 25000, 50000])
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => step = v),
                              child: Container(
                                height: 40,
                                margin: EdgeInsets.only(right: v == 50000 ? 0 : 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: step == v ? headerGradient : null,
                                  color: step == v ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: step == v ? C.navy : C.line),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Text('+${v ~/ 1000}.000',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: step == v ? Colors.white : C.navy)),
                                  if (step == v) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.star, size: 11, color: C.amber),
                                  ],
                                ]),
                              ),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Text('Bid Anda', style: TextStyle(fontSize: 12, color: C.mute)),
                        const Spacer(),
                        Text(rp(current + step),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 20, color: C.navy)),
                      ]),
                      const SizedBox(height: 10),
                      Btn('Tempatkan Bid', onTap: _bid),
                    ]),
            ),
          ),
        ]),
      ),
    );
  }
}
