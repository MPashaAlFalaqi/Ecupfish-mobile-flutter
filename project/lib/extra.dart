import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'account.dart';
import 'core.dart';
import 'order.dart';

// ───────────── Status Pengiriman ─────────────
class StatusPengirimanScreen extends StatelessWidget {
  final Order o;
  const StatusPengirimanScreen(this.o, {super.key});

  Widget _notice(String text, {bool warn = true}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6DD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF2D58A)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline, size: 18, color: C.amberDark),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11, height: 1.35))),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListenableBuilder(
          listenable: cart,
          builder: (context, _) {
            final step = o.step;
            final cur = step >= 3 ? 4 : (step < 1 ? 1 : step); // tahap yang sedang berjalan
            final show = cur <= 1 ? [0, 1, 2] : [1, 2, 3];
            final shipped = step >= 2;
            final chip = step >= 3 ? 'Selesai' : (shipped ? 'Dalam Pengiriman' : 'Diproses');

            String title(int i) => switch (i) {
                  0 => 'Pesanan Dikonfirmasi',
                  1 => 'Diproses',
                  2 => (cur >= 2 ? 'Dalam Pengiriman' : 'Dikirim'),
                  _ => 'Tiba',
                };
            String desc(int i) => switch (i) {
                  0 => 'Pembayaran berhasil, menunggu peternak memproses',
                  1 => 'Peternak sedang menyiapkan & mengemas ikan Anda',
                  2 => (cur >= 2
                      ? 'Paket dalam perjalanan menuju alamat Anda'
                      : 'Menunggu paket diserahkan ke kurir'),
                  _ => (step >= 3 ? 'Pesanan telah diterima. Terima kasih!' : 'Menunggu konfirmasi diterima'),
                };
            IconData icon(int i) => switch (i) {
                  0 => Icons.check,
                  1 => Icons.inventory_2_outlined,
                  2 => Icons.local_shipping_outlined,
                  _ => Icons.home_outlined,
                };

            return Column(children: [
              WaveHeader(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const RoundBack(),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Status Pengiriman',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                          Text(o.id, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ]),
                      ]),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                            color: const Color(0x22FFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: C.sky)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const CircleAvatar(radius: 3, backgroundColor: C.sky),
                          const SizedBox(width: 6),
                          Text(chip,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
                  Box(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      for (final i in show)
                        IntrinsicHeight(
                          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            SizedBox(
                              width: 36,
                              child: Column(children: [
                                CircleAvatar(
                                  radius: 17,
                                  backgroundColor: i < cur
                                      ? C.navy
                                      : (i == cur ? const Color(0xFFFFF0C2) : C.field),
                                  child: i < cur
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : Icon(icon(i),
                                          size: 16, color: i == cur ? C.amberDark : C.sky),
                                ),
                                if (i != show.last)
                                  Expanded(
                                      child: Container(
                                          width: 2, color: i < cur ? C.navy : C.line)),
                              ]),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: i == show.last ? 0 : 18),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(title(i),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: i > cur ? C.mute : C.ink)),
                                  const SizedBox(height: 2),
                                  Text(desc(i),
                                      style: const TextStyle(fontSize: 12, color: C.mute)),
                                  if (i <= cur && i < 4) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                        tgl(o.at.add(Duration(hours: i == 0 ? 0 : (i * 26) ~/ 2))),
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: i == cur ? C.amberDark : C.blue)),
                                  ],
                                  if (i == cur && i == 1) ...[
                                    const SizedBox(height: 6),
                                    const Pill('Estimasi dikirim 1x24 jam'),
                                  ],
                                  if (i == cur && i == 2) ...[
                                    const SizedBox(height: 6),
                                    const Pill('Estimasi tiba besok'),
                                  ],
                                ]),
                              ),
                            ),
                          ]),
                        ),
                    ]),
                  ),
                  _sectionTitleExtra(Icons.inventory_2_outlined, 'Informasi Kurir'),
                  Box(
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: C.field, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.local_shipping_outlined, color: C.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: shipped
                            ? const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('JNE Live Fish',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                Text('Resi 12345678',
                                    style: TextStyle(fontSize: 12, color: C.mute)),
                              ])
                            : const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Belum Tersedia',
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: C.blue)),
                                Text('Nomor resi muncul setelah pesanan dikirim',
                                    style: TextStyle(fontSize: 11, color: C.mute)),
                              ]),
                      ),
                      if (shipped)
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18, color: C.blue),
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: '12345678'));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('Nomor resi disalin')));
                          },
                        ),
                    ]),
                  ),
                  if (!shipped)
                    _notice(
                        'Pesanan masih bisa dibatalkan selama berstatus Diproses dan belum diserahkan ke kurir. Setelah dikirim, pembatalan tidak dapat dilakukan.')
                  else
                    _notice(
                        'Estimasi tiba dalam 1-2 hari kerja. Harap pastikan seseorang tersedia untuk menerima paket guna menjaga kesehatan ikan.'),
                  if (!shipped) ...[
                    GoldOutlineBtn('Hubungi Penjual',
                        onTap: () => push(context, const ChatScreen(seller: 'Betta King Jakarta'))),
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Batalkan pesanan?'),
                              content: const Text('Pesanan yang dibatalkan tidak dapat dikembalikan.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Tidak')),
                                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Ya, batalkan')),
                              ],
                            ),
                          );
                          if (ok == true && context.mounted) {
                            cart.cancel(o);
                            Navigator.popUntil(context, (r) => r.isFirst);
                          }
                        },
                        child: const Text('Batalkan Pesanan',
                            style: TextStyle(color: C.amberDark, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ] else ...[
                    if (step == 2) Btn('Pesanan Diterima', onTap: () => cart.advance(o)),
                    if (step == 2) const SizedBox(height: 10),
                    Btn('Berikan Ulasan', gold: true, onTap: () => push(context, ReviewScreen(o))),
                    const SizedBox(height: 10),
                    GoldOutlineBtn('Ajukan Klaim Garansi', onTap: () => push(context, const ClaimScreen())),
                    const SizedBox(height: 8),
                    const Text('*Pastikan melakukan video unboxing tanpa jeda untuk klaim garansi',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: C.mute)),
                  ],
                ]),
              ),
            ]);
          },
        ),
      );
}

Widget _sectionTitleExtra(IconData i, String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(children: [
        Icon(i, size: 16, color: C.amberDark),
        const SizedBox(width: 6),
        Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
      ]),
    );

// ───────────── Beri Ulasan ─────────────
class ReviewScreen extends StatefulWidget {
  final Order o;
  const ReviewScreen(this.o, {super.key});
  @override
  State<ReviewScreen> createState() => _ReviewState();
}

class _ReviewState extends State<ReviewScreen> {
  static const tags = ['Ikan Sehat', 'Warna Cerah', 'Packing Rapi', 'Pengiriman Cepat', 'Sesuai Deskripsi', 'Peternak Ramah'];
  int rating = 0;
  final picked = <String>{};
  bool anon = false;
  bool photo = false;

  @override
  Widget build(BuildContext context) {
    final first = widget.o.lines.isNotEmpty ? widget.o.lines.first.$1 : null;
    return Scaffold(
      body: Column(children: [
        const AppHeader('Beri Ulasan'),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
            Box(
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(gradient: darkCard),
                      child: const Icon(Icons.set_meal, color: C.orange)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(first?.name ?? (widget.o.names.isEmpty ? 'Pesanan' : widget.o.names.first),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Text(
                        '${first?.seller ?? 'Betta King Jakarta'} · 1x · Grade ${first?.grade ?? 'A'}',
                        style: const TextStyle(fontSize: 11, color: C.mute)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 4),
            const Text('Bagaimana kualitas & kesehatan ikan yang Anda terima?',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  iconSize: 36,
                  onPressed: () => setState(() => rating = i),
                  icon: Icon(i <= rating ? Icons.star : Icons.star_border,
                      color: i <= rating ? C.amber : C.sky),
                ),
            ]),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              for (final t in tags)
                GestureDetector(
                  onTap: () => setState(() => picked.contains(t) ? picked.remove(t) : picked.add(t)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: picked.contains(t) ? C.navy : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: picked.contains(t) ? C.navy : C.line),
                    ),
                    child: Text(t,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: picked.contains(t) ? Colors.white : C.navy)),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            TextField(
              maxLines: 4,
              maxLength: 300,
              decoration: fieldDec('Ceritakan pengalaman Anda membeli di toko ini...', fill: C.field),
            ),
            GestureDetector(
              onTap: () => setState(() => photo = !photo),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: C.field,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: photo ? Colors.green : C.sky),
                ),
                child: Icon(photo ? Icons.check : Icons.photo_camera_outlined,
                    color: photo ? Colors.green : C.blue),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: anon,
              onChanged: (v) => setState(() => anon = v ?? false),
              title: const Text('Sembunyikan nama saya (tampil sebagai "Pembeli eCupFish")',
                  style: TextStyle(fontSize: 12)),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [BoxShadow(color: C.shadow, blurRadius: 14)],
          ),
          child: SafeArea(
            top: false,
            child: Btn('Beri Ulasan',
                gold: true,
                onTap: rating == 0
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Terima kasih atas ulasan Anda!')));
                        Navigator.pop(context);
                      }),
          ),
        ),
      ]),
    );
  }
}

// ───────────── Menang Lelang ─────────────
class MenangLelangScreen extends StatefulWidget {
  final int amount;
  const MenangLelangScreen({super.key, required this.amount});
  @override
  State<MenangLelangScreen> createState() => _MenangState();
}

class _MenangState extends State<MenangLelangScreen> {
  late final Timer _t;
  int secs = 7112; // 01:58:32

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secs > 0 && mounted) setState(() => secs--);
    });
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  String get clock {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(secs ~/ 3600)}:${two(secs % 3600 ~/ 60)}:${two(secs % 60)}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B2E50), Color(0xFF1B5E96)])),
          child: Column(children: [
            Expanded(
              child: SafeArea(
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  Align(alignment: Alignment.centerLeft, child: const RoundBack()),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 118,
                      height: 118,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x33F5B400),
                        border: Border.all(color: C.amber, width: 2),
                      ),
                      child: ClipOval(
                        child: Container(
                          color: Colors.white,
                          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('Selamat, Anda Menang!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'Anda memenangkan lelang untuk item di bawah ini.\nSegera selesaikan pembayaran sebelum waktu habis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0x22FFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24)),
                    child: Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            gradient: darkCard, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.set_meal, color: C.orange),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Halfmoon Multi Copper Galaxy',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('Betta King Jakarta · Lot #12',
                              style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        const Text('Bid Akhir', style: TextStyle(color: Colors.white60, fontSize: 9)),
                        Text(rp(widget.amount).replaceFirst('Rp ', 'Rp. '),
                            style: const TextStyle(
                                color: C.amber, fontWeight: FontWeight.w800, fontSize: 14)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      const Text('Selesaikan pembayaran dalam ',
                          style: TextStyle(color: Colors.white70, fontSize: 11)),
                      Text(clock,
                          style: const TextStyle(
                              color: C.amber, fontWeight: FontWeight.w800, fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: SafeArea(
                top: false,
                child: Btn('Bayar Sekarang',
                    onTap: () => push(
                        context,
                        PaymentScreen(
                            draft: Draft(const [], const ['Halfmoon Multi Copper Galaxy (Lelang)'],
                                widget.amount)))),
              ),
            ),
          ]),
        ),
      );
}
