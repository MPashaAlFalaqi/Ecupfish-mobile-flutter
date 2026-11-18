import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'extra.dart';
import 'motion.dart';

Widget _check(bool v, VoidCallback onTap) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4), // area sentuh lebih besar
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: v ? C.navy : Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: v ? C.navy : C.sky, width: 1.5),
          ),
          child: AnimatedScale(
            scale: v ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
        ),
      ),
    );

Widget _stepper(BuildContext context, Fish f, {bool interactive = true}) {
  final q = cart.items[f] ?? 1;
  Widget b(IconData i, VoidCallback? onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: interactive && onTap == null ? .35 : 1,
          child: Container(
            width: 26,
            height: 26,
            decoration:
                BoxDecoration(color: C.field, borderRadius: BorderRadius.circular(8)),
            child: Icon(i, size: 14, color: C.navy),
          ),
        ),
      );
  return Row(mainAxisSize: MainAxisSize.min, children: [
    // jumlah minimal 1; hapus item lewat ikon tempat sampah
    b(Icons.remove, interactive && q > 1 ? () {
      HapticFeedback.selectionClick();
      cart.dec(f);
    } : null),
    SizedBox(
      width: 30,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (c, a) =>
            ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
        child: Text('$q',
            key: ValueKey(q),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    ),
    // tombol + nonaktif saat stok habis
    b(Icons.add, interactive && q < f.stock ? () {
      HapticFeedback.selectionClick();
      cart.add(f);
    } : null),
  ]);
}

Widget _sectionTitle(IconData i, String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(children: [
        Icon(i, size: 16, color: C.amberDark),
        const SizedBox(width: 6),
        Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      ]),
    );

Widget _bottomBar(Widget child) => Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: C.shadow, blurRadius: 14)],
      ),
      child: SafeArea(top: false, child: child),
    );

// ───────────── Keranjang ─────────────
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Item yang sedang animasi keluar sebelum benar-benar dihapus dari keranjang.
  final Set<Fish> _leaving = {};

  void _delete(Fish f) {
    if (_leaving.contains(f)) return;
    final qty = cart.items[f] ?? 1;
    final wasSelected = cart.selected.contains(f);
    HapticFeedback.lightImpact();
    setState(() => _leaving.add(f));
    Future.delayed(const Duration(milliseconds: 340), () {
      if (_leaving.remove(f)) cart.remove(f); // false bila sudah di-undo
    });
    final othersLeft = cart.items.length - _leaving.length > 0;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, othersLeft ? 130 : 16),
        content: Text('${f.name} dihapus dari keranjang'),
        action: SnackBarAction(
          label: 'Urungkan',
          textColor: C.amber,
          onPressed: () {
            if (_leaving.remove(f)) {
              if (mounted) setState(() {}); // masih animasi → batalkan saja
            } else {
              cart.restore(f, qty, wasSelected);
            }
          },
        ),
      ));
  }

  Widget _item(Fish f) => Collapse(
        key: ValueKey('item-${f.id}'),
        visible: !_leaving.contains(f),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            _check(cart.selected.contains(f), () => cart.toggle(f)),
            const SizedBox(width: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 64, height: 64, child: FishThumb(f)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('Grade ${f.grade} · ${f.type}',
                    style: const TextStyle(fontSize: 11, color: C.mute)),
                const SizedBox(height: 4),
                Text(rp(f.price),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: C.navy, fontSize: 12)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _delete(f),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                ),
              ),
              const SizedBox(height: 6),
              _stepper(context, f),
            ]),
          ]),
        ),
      );

  Widget _group(String s, int index) {
    final fs = [for (final f in cart.items.keys) if (f.seller == s) f];
    final allSel = fs.every(cart.selected.contains);
    final gone = fs.every(_leaving.contains);
    return Collapse(
      key: ValueKey('seller-$s'),
      visible: !gone,
      child: Reveal(
        index: index,
        child: Box(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              _check(allSel, () => cart.toggleSeller(s, !allSel)),
              const SizedBox(width: 4),
              const Icon(Icons.storefront_outlined, size: 16, color: C.blue),
              const SizedBox(width: 6),
              Text(s, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
            const Divider(height: 18, color: C.line),
            for (final f in fs) _item(f),
          ]),
        ),
      ),
    );
  }

  Widget _empty() => Center(
        key: const ValueKey('empty'),
        child: Reveal(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: C.field, shape: BoxShape.circle),
                child: const Icon(Icons.shopping_cart_outlined, size: 44, color: C.blue),
              ),
              const SizedBox(height: 16),
              const Text('Keranjang masih kosong',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              const Text('Yuk cari cupang favoritmu dan masukkan ke keranjang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: C.mute)),
              const SizedBox(height: 18),
              SizedBox(
                width: 190,
                child: Btn('Mulai Belanja',
                    gold: true,
                    height: 44,
                    onTap: () => Navigator.maybePop(context)),
              ),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: cart,
        builder: (context, _) {
          final sellers = <String>[];
          for (final f in cart.items.keys) {
            if (!sellers.contains(f.seller)) sellers.add(f.seller);
          }
          final empty = cart.items.isEmpty;
          return Scaffold(
            body: Column(children: [
              WaveHeader(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(children: [
                      const RoundBack(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Keranjang',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                          Text('${cart.items.length} produk',
                              style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ]),
                      ),
                      if (!empty)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => cart.toggleAll(!cart.allSelected),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Text(cart.allSelected ? 'Batal Pilih' : 'Pilih Semua',
                                style: const TextStyle(
                                    color: C.amber, fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  child: empty
                      ? _empty()
                      : ListView(
                          key: const ValueKey('list'),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          children: [
                            for (var i = 0; i < sellers.length; i++) _group(sellers[i], i),
                          ],
                        ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomCenter,
                child: empty
                    ? const SizedBox(width: double.infinity)
                    : _bottomBar(Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          Text('${cart.chosenCount} barang dipilih',
                              style: const TextStyle(fontSize: 11, color: C.mute)),
                          const Spacer(),
                          CountUp(
                            value: cart.subtotal,
                            format: rp,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 18, color: C.navy),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Btn('Checkout Sekarang',
                            onTap: cart.chosen.isEmpty
                                ? null
                                : () => push(context, const CheckoutScreen())),
                      ])),
              ),
            ]),
          );
        },
      );
}

// ───────────── Checkout ─────────────
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutState();
}

class _CheckoutState extends State<CheckoutScreen> {
  int disc = 0;
  String? promoErr;
  final promo = TextEditingController();

  @override
  void dispose() {
    promo.dispose();
    super.dispose();
  }

  Widget _row(String l, int v, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(l,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                  fontSize: bold ? 14 : 13,
                  color: bold ? C.ink : C.mute)),
          const Spacer(),
          Text(rp(v),
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  fontSize: bold ? 20 : 13,
                  color: color ?? (bold ? C.navy : C.ink))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final d = cart.draft(discount: disc);
    return Scaffold(
      body: Column(children: [
        const AppHeader('Checkout'),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
            _sectionTitle(Icons.location_on_outlined, 'Alamat Pengiriman'),
            Box(
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: C.field, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.location_on_outlined, color: C.blue),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Berry Pop · 0812-3456-7890',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Text('Jl. Merdeka No. 45, RT 03/RW 02, Rai, Malang, Jawa Timur 65162',
                        style: TextStyle(fontSize: 11, color: C.mute)),
                  ]),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: C.navy),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 14)),
                  child: const Text('Ubah',
                      style: TextStyle(color: C.navy, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ]),
            ),
            _sectionTitle(Icons.inventory_2_outlined, 'Ringkasan Produk'),
            for (final l in d.lines)
              Box(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(width: 52, height: 52, child: FishThumb(l.$1)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.$1.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('Grade ${l.$1.grade} · ${l.$1.type}',
                          style: const TextStyle(fontSize: 11, color: C.mute)),
                      const SizedBox(height: 4),
                      ListenableBuilder(
                          listenable: cart,
                          builder: (_, __) => _stepper(context, l.$1, interactive: false)),
                    ]),
                  ),
                  Text(rp(l.$1.price * l.$2),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: C.navy, fontSize: 13)),
                ]),
              ),
            _sectionTitle(Icons.local_shipping_outlined, 'Opsi Pengiriman'),
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: C.field,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: C.navy, width: 1.6),
                ),
                child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.radio_button_checked, color: C.navy, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Live Fish Safe Delivery (Garansi 100%)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      SizedBox(height: 4),
                      Text(
                          'Ikan dikemas double packing dengan oksigen & heat/cool pack. Garansi penuh jika ikan mati di perjalanan (DOA).',
                          style: TextStyle(fontSize: 11, color: C.mute, height: 1.35)),
                    ]),
                  ),
                ]),
              ),
              const Positioned(right: 12, top: -10, child: Pill('100%')),
            ]),
            const SizedBox(height: 12),
            Box(
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: promo,
                        decoration: fieldDec('Masukkan kode promo', error: promoErr))),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: C.navy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => setState(() {
                      if (promo.text.trim().toUpperCase() == 'CUPANG10') {
                        disc = 10000;
                        promoErr = null;
                      } else {
                        disc = 0;
                        promoErr = 'Kode tidak valid';
                      }
                    }),
                    child: const Text('Pakai'),
                  ),
                ),
              ]),
            ),
            _sectionTitle(Icons.receipt_long_outlined, 'Rincian Biaya'),
            Box(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _row('Harga Ikan', d.subtotal),
                _row('Ongkir', d.ship),
                _row('Biaya Garansi', d.guarantee),
                if (disc > 0) _row('Diskon Promo', -disc, color: Colors.green),
                const Divider(color: C.line),
                _row('Total Pembayaran', d.total, bold: true),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF6DD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: C.amber)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.local_offer_outlined, size: 13, color: C.amberDark),
                    SizedBox(width: 6),
                    Text('Termasuk garansi ikan mati/cacat',
                        style: TextStyle(fontSize: 10, color: C.amberDark, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
        _bottomBar(Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Text('Total Pembayaran', style: TextStyle(fontSize: 11, color: C.mute)),
            const Spacer(),
            Text(rp(d.total),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: C.navy)),
          ]),
          const SizedBox(height: 10),
          Btn('Konfirmasi Pesanan & Bayar',
              onTap: d.lines.isEmpty ? null : () => push(context, PaymentScreen(draft: d))),
        ])),
      ]),
    );
  }
}

// ───────────── Metode Pembayaran ─────────────
class _Pm {
  final String name, note, logo;
  final bool off;
  final int? balance;
  final double feePct;
  const _Pm(this.name, this.note, this.logo,
      {this.off = false, this.balance, this.feePct = 0});
}

const _wallet = [
  _Pm('GoPay', 'Saldo mencukupi', 'G', balance: 180000),
  _Pm('QRIS', 'Scan dengan aplikasi bank/e-wallet apapun', 'QR'),
];
const _bank = [
  _Pm('BCA Virtual Account', 'Verifikasi otomatis 1-5 menit', 'BCA'),
  _Pm('BNI Virtual Account', 'Verifikasi otomatis 1-5 menit', 'BNI'),
  _Pm('Mandiri Virtual Account', 'Sedang dalam pemeliharaan sistem', 'MDR', off: true),
];

class PaymentScreen extends StatefulWidget {
  final Draft draft;
  const PaymentScreen({super.key, required this.draft});
  @override
  State<PaymentScreen> createState() => _PaymentState();
}

class _PaymentState extends State<PaymentScreen> {
  _Pm? picked;

  int get fee => picked == null ? 0 : (widget.draft.total * picked!.feePct).round();
  int get grand => widget.draft.total + fee;
  bool get low => picked?.balance != null && picked!.balance! < grand;

  Widget _tile(_Pm m) {
    final sel = identical(picked, m);
    final bad = m.balance != null && m.balance! < widget.draft.total;
    return Opacity(
      opacity: m.off ? .5 : 1,
      child: GestureDetector(
        onTap: m.off ? null : () => setState(() => picked = m),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sel ? C.navy : C.line, width: sel ? 1.6 : 1),
            boxShadow: sel ? const [BoxShadow(color: C.shadow, blurRadius: 10)] : null,
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: C.field, borderRadius: BorderRadius.circular(10)),
              child: Text(m.logo,
                  style: const TextStyle(
                      color: C.blue, fontWeight: FontWeight.w800, fontSize: 11)),
            ),
            Expanded(
              child: Column(children: [
                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text(
                    m.balance != null && bad
                        ? 'Saldo tidak cukup (${rp(m.balance!)})'
                        : m.note,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: bad ? Colors.red : C.mute)),
              ]),
            ),
            Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: sel ? C.navy : C.sky),
          ]),
        ),
      ),
    );
  }

  Widget _group(IconData i, String t, List<_Pm> l, {String? tag}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _sectionTitle(i, t)),
          if (tag != null)
            Text(tag, style: const TextStyle(color: C.blue, fontWeight: FontWeight.w700, fontSize: 11)),
        ]),
        for (final m in l) _tile(m),
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          AppHeader('Metode Pembayaran',
              bottom: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                    color: const Color(0x22FFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24)),
                child: Row(children: [
                  const Text('Total Tagihan',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  Text(rp(grand),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                ]),
              )),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
              if (low)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFDECEC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: 'Saldo ${picked!.name} kamu tidak cukup untuk menyelesaikan pembayaran ini. '),
                        const TextSpan(text: 'Isi saldo', style: TextStyle(color: C.blue, fontWeight: FontWeight.w800)),
                        const TextSpan(text: ' dulu atau pilih metode lain.'),
                      ]), style: const TextStyle(fontSize: 11, color: Color(0xFFB3261E))),
                    ),
                  ]),
                ),
              _group(Icons.account_balance_wallet_outlined, 'E-Wallet', _wallet),
              _group(Icons.account_balance_outlined, 'Transfer Bank (Virtual Account)', _bank, tag: 'Gratis')])),
          _bottomBar(
            Btn(
              low
                  ? 'Saldo Tidak Cukup'
                  : (picked == null ? 'Pilih Metode Pembayaran' : 'Lanjutkan Pembayaran'),
              gold: picked == null || low,
              onTap: (picked == null || low)
                  ? null
                  : () => push(context,
                      ProcessPaymentScreen(draft: widget.draft, method: picked!.name, amount: grand)),
            ),
          ),
        ]),
      );
}

// ───────────── Proses Pembayaran (QRIS / VA) ─────────────
class _QrPainter extends CustomPainter {
  final int seed;
  const _QrPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    const n = 29;
    final cell = size.width / n;
    final rnd = Random(seed);
    final p = Paint()..color = Colors.black;
    bool finder(int x, int y) =>
        (x < 8 && y < 8) || (x >= n - 8 && y < 8) || (x < 8 && y >= n - 8);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (finder(x, y)) continue;
        if (rnd.nextDouble() < .5) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell + .4, cell + .4), p);
        }
      }
    }
    void eye(int ox, int oy) {
      canvas.drawRect(Rect.fromLTWH(ox * cell, oy * cell, 7 * cell, 7 * cell), p);
      canvas.drawRect(Rect.fromLTWH((ox + 1) * cell, (oy + 1) * cell, 5 * cell, 5 * cell),
          Paint()..color = Colors.white);
      canvas.drawRect(Rect.fromLTWH((ox + 2) * cell, (oy + 2) * cell, 3 * cell, 3 * cell), p);
    }

    eye(0, 0);
    eye(n - 7, 0);
    eye(0, n - 7);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProcessPaymentScreen extends StatelessWidget {
  final Draft draft;
  final String method;
  final int amount;
  const ProcessPaymentScreen(
      {super.key, required this.draft, required this.method, required this.amount});

  @override
  Widget build(BuildContext context) {
    final isQr = method == 'QRIS';
    final isVa = method.contains('Virtual');
    final deadline = DateTime.now().add(const Duration(hours: 24));
    return Scaffold(
      body: Column(children: [
        const AppHeader('Proses Pembayaran'),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
            Box(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Metode Pembayaran: $method',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                Text(rp(amount).replaceFirst('Rp ', 'Rp. '),
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                const Text('Segera lakukan pembayaran sebelum waktu habis!',
                    style: TextStyle(fontSize: 11, color: C.mute)),
                Text(tgl(deadline),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800, color: C.blue)),
                const SizedBox(height: 12),
                if (isQr) ...[
                  Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      padding: const EdgeInsets.all(8),
                      color: Colors.white,
                      child: CustomPaint(painter: _QrPainter(amount)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                      child: Text('QRIS atas nama : eCupFish Store',
                          style: TextStyle(fontSize: 11, color: C.mute))),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: C.field, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(isVa ? 'Nomor Virtual Account' : 'Kode Pembayaran',
                              style: const TextStyle(fontSize: 11, color: C.mute)),
                          const SizedBox(height: 4),
                          Text('8077 0812 3456 7890',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1)),
                        ]),
                      ),
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: '8077081234567890'));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nomor disalin')));
                        },
                        child: const Text('Salin'),
                      ),
                    ]),
                  ),
                ],
              ]),
            ),
            Btn('Konfirmasi Pembayaran', onTap: () {
              final o = cart.place(draft, method);
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => DetailPesananScreen(o, justPaid: true)),
                  (r) => r.isFirst);
            }),
            const SizedBox(height: 10),
            GoldOutlineBtn('Konfirmasi jika pembayaran tidak masuk', onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Permintaan dikirim. Tim eCupFish akan memeriksa pembayaran Anda.')));
            }),
            const SizedBox(height: 10),
            const Text('*Pastikan melakukan pembayaran dengan baik dan benar',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: C.mute)),
          ]),
        ),
      ]),
    );
  }
}

// ───────────── Detail Pesanan ─────────────
class DetailPesananScreen extends StatelessWidget {
  final Order o;
  final bool justPaid;
  const DetailPesananScreen(this.o, {super.key, this.justPaid = false});

  static const _steps = [
    (Icons.check, 'Dibayar'),
    (Icons.inventory_2_outlined, 'Diproses'),
    (Icons.local_shipping_outlined, 'Dikirim'),
    (Icons.home_outlined, 'Diterima'),
  ];

  Widget _row(String l, int v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(l,
              style: TextStyle(
                  fontSize: bold ? 13 : 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                  color: bold ? C.ink : C.mute)),
          const Spacer(),
          Text(rp(v),
              style: TextStyle(
                  fontSize: bold ? 16 : 12,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: bold ? C.navy : C.ink)),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListenableBuilder(
          listenable: cart,
          builder: (context, _) {
            final cur = o.step.clamp(0, 3);
            return Column(children: [
              WaveHeader(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Column(children: [
                      const Row(children: [
                        RoundBack(),
                        SizedBox(width: 12),
                        Text('Detail Pesanan',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                      ]),
                      const SizedBox(height: 10),
                      const CircleAvatar(
                          radius: 24,
                          backgroundColor: C.amber,
                          child: Icon(Icons.check, size: 28, color: C.ink)),
                      const SizedBox(height: 6),
                      const Text('Pembayaran Berhasil',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(tgl(o.at),
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ]),
                  ),
                ),
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
                  Box(
                    child: Row(children: [
                      const Text('NO. PESANAN',
                          style: TextStyle(fontSize: 10, color: C.mute, letterSpacing: .5)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(o.id,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
                      OutlinedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: o.id));
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Nomor pesanan disalin')));
                        },
                        style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text('Salin', style: TextStyle(fontSize: 11)),
                      ),
                    ]),
                  ),
                  _sectionTitle(Icons.timeline, 'Status Pesanan'),
                  Box(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      for (var i = 0; i < _steps.length; i++) ...[
                        if (i > 0)
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.only(top: 13),
                            child: Container(height: 2, color: i <= cur ? C.navy : C.line),
                          )),
                        Column(children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: i <= cur ? C.navy : C.field,
                            child: Icon(_steps[i].$1,
                                size: 14, color: i <= cur ? Colors.white : C.sky),
                          ),
                          const SizedBox(height: 4),
                          Text(_steps[i].$2, style: const TextStyle(fontSize: 10)),
                        ]),
                      ],
                    ]),
                  ),
                  _sectionTitle(Icons.inventory_2_outlined, 'Produk Dipesan'),
                  for (final l in o.lines)
                    Box(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(width: 48, height: 48, child: FishThumb(l.$1)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l.$1.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            Text('${l.$2}x · Grade ${l.$1.grade} · ${l.$1.type}',
                                style: const TextStyle(fontSize: 11, color: C.mute)),
                          ]),
                        ),
                        Text(rp(l.$1.price * l.$2),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ]),
                    ),
                  if (o.lines.isEmpty)
                    for (final n in o.names)
                      Box(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Text(n, style: const TextStyle(fontWeight: FontWeight.w700))),
                  _sectionTitle(Icons.location_on_outlined, 'Dikirim ke'),
                  const Box(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.location_on_outlined, color: C.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Bobby · 0812-3456-7890',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('Jl. Merdeka No. 45, RT 03/RW 02, Sumber Rejeki, Malang, Jawa Timur 65162',
                              style: TextStyle(fontSize: 11, color: C.mute)),
                        ]),
                      ),
                    ]),
                  ),
                  Box(
                    child: Column(children: [
                      _row('Harga Ikan', o.subtotal),
                      _row('Ongkir (Live Fish Safe Delivery)', o.ship),
                      _row('Biaya Garansi', o.guarantee),
                      if (o.discount > 0) _row('Diskon Promo', -o.discount),
                      const Divider(color: C.line),
                      _row('Total Pembayaran', o.total, bold: true),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.account_balance_wallet_outlined, size: 14, color: C.mute),
                          const SizedBox(width: 6),
                          Text('Dibayar via ${o.payment}',
                              style: const TextStyle(fontSize: 11, color: C.mute)),
                        ]),
                      ),
                    ]),
                  ),
                  Btn('Lacak Pesanan', onTap: () => push(context, StatusPengirimanScreen(o))),
                  const SizedBox(height: 10),
                  GoldOutlineBtn('Unduh Invoice', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Invoice PDF akan tersedia setelah terhubung ke server')));
                  }),
                ]),
              ),
            ]);
          },
        ),
      );
}

// ───────────── Pesanan (tab) ─────────────
class OrdersScreen extends StatelessWidget {
  final bool back;
  const OrdersScreen({super.key, this.back = false});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          AppHeader('Pesanan Saya', back: back),
          Expanded(
            child: ListenableBuilder(
              listenable: cart,
              builder: (context, _) {
                if (cart.orders.isEmpty) {
                  return const Center(child: Text('Belum ada pesanan'));
                }
                return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
                  for (final o in cart.orders)
                    GestureDetector(
                      onTap: () => push(context, DetailPesananScreen(o)),
                      child: Box(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(o.id, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const Spacer(),
                            Pill(TrackStepper.labels[o.step].toUpperCase()),
                          ]),
                          const SizedBox(height: 6),
                          Text(o.names.join(', '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: C.mute, fontSize: 12)),
                          const SizedBox(height: 12),
                          TrackStepper(o.step),
                          const SizedBox(height: 8),
                          Row(children: [
                            Text(rp(o.total),
                                style: const TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
                            const Spacer(),
                            TextButton(
                                onPressed: () => push(context, StatusPengirimanScreen(o)),
                                child: const Text('Lacak')),
                            if (o.step < 3)
                              TextButton(
                                  onPressed: () => cart.advance(o),
                                  child: const Text('Lanjutkan status (demo)')),
                          ]),
                        ]),
                      ),
                    ),
                ]);
              },
            ),
          ),
        ]),
      );
}

// ───────────── Notifikasi ─────────────
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotifState();
}

class _NotifState extends State<NotificationScreen> {
  static const tabs = ['Semua', 'Lelang', 'Pesanan', 'Promo'];
  // (grup, kategori, ikon, warna, judul, isi, waktu)
  static const items = [
    ('HARI INI', 'Lelang', Icons.gavel, C.blue, 'Anda Ditawar Melebihi!',
        'User C menawar Rp 170.000 di lelang Halfmoon Multi. Ayo tawar lagi sebelum waktu habis.', '2 mnt'),
    ('HARI INI', 'Pesanan', Icons.inventory_2_outlined, Color(0xFF2EAD5B), 'Pesanan Dalam Pengiriman',
        'Pesanan #BETTA-9920 sedang dalam perjalanan via JNE Live Fish.', '1 jam'),
    ('HARI INI', 'Pesanan', Icons.chat_bubble_outline, Color(0xFF3D8FE0), 'Pesan Baru dari Betta King Jakarta',
        '"Kak, ikan sudah kami packing, siap kirim besok pagi."', '3 jam'),
    ('KEMARIN', 'Promo', Icons.local_offer_outlined, C.amber, 'Promo Spesial Weekend!',
        'Dapatkan cashback 5% untuk pembayaran via QRIS, berlaku hingga Minggu.', '1 hr'),
    ('KEMARIN', 'Pesanan', Icons.verified_outlined, Color(0xFF2EAD5B), 'Klaim Garansi Disetujui',
        'Klaim garansi untuk pesanan #BETTA-9871 telah disetujui. Refund diproses 1x24 jam.', '1 hr'),
    ('KEMARIN', 'Lelang', Icons.gavel, C.blue, 'Lelang Berakhir - Anda Menang!',
        'Selamat! Anda memenangkan lelang Plakat Blue Rim seharga Rp 190.000.', '2 hr'),
  ];
  String tab = 'Semua';
  final read = <int>{3, 4, 5};

  @override
  Widget build(BuildContext context) {
    final shown = [for (var i = 0; i < items.length; i++) if (tab == 'Semua' || items[i].$2 == tab) i];
    String? last;
    return Scaffold(
      body: Column(children: [
        AppHeader('Notifikasi',
            actions: [
              GestureDetector(
                onTap: () => setState(() => read.addAll(List.generate(items.length, (i) => i))),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Tandai Dibaca',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
            bottom: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final t in tabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => tab = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: tab == t ? C.amber : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: tab == t ? C.amber : Colors.white54),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: tab == t ? C.ink : Colors.white)),
                      ),
                    ),
                  ),
              ]),
            )),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
            for (final i in shown) ...[
              if (items[i].$1 != last) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 8),
                  child: Text((last = items[i].$1)!,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w800, color: C.mute, letterSpacing: 1)),
                ),
              ],
              GestureDetector(
                onTap: () => setState(() => read.add(i)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: read.contains(i) ? Colors.white : const Color(0xFFE6F0FC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: read.contains(i) ? C.line : C.sky),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Stack(clipBehavior: Clip.none, children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: items[i].$4, borderRadius: BorderRadius.circular(12)),
                        child: Icon(items[i].$3, color: Colors.white, size: 20),
                      ),
                      if (!read.contains(i))
                        const Positioned(
                            left: -4, top: -4, child: CircleAvatar(radius: 4, backgroundColor: C.amber)),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(items[i].$5,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(items[i].$6,
                            style: const TextStyle(fontSize: 11, color: C.mute, height: 1.3)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Text(items[i].$7, style: const TextStyle(fontSize: 10, color: C.mute)),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}
