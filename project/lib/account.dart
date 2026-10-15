import 'package:flutter/material.dart';
import 'auth.dart';
import 'core.dart';
import 'forgot.dart';
import 'order.dart';

// ───────────── Daftar Pesan ─────────────
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesState();
}

class _MessagesState extends State<MessagesScreen> {
  static const chats = [
    ('BK', 'Betta King Jakarta', 'Kak, ikan sudah kami packing, siap kirim besok pagi.', '13:45', 1, true),
    ('NA', 'Nemo Aquatic Farm', 'Terima kasih sudah berbelanja ya kak 🙏', 'Kemarin', 0, true),
    ('HG', 'Halfmoon Galaxy', 'Baik kak, akan saya cek stoknya dulu.', 'Kemarin', 2, true),
    ('CS', 'eCupFish Care', 'Klaim garansi Anda sedang kami tinjau.', '2 hr', 0, true),
    ('SR', 'Super Red Betta', 'Oke kak siap, ditunggu pembayarannya ya.', '3 hr', 0, true),
  ];
  String q = '';

  @override
  Widget build(BuildContext context) {
    final list = chats.where((c) => c.$2.toLowerCase().contains(q.toLowerCase())).toList();
    return Scaffold(
      body: Column(children: [
        AppHeader('Pesan',
            bottom: TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: fieldDec('Cari percakapan atau toko...',
                  prefix: const Icon(Icons.search, size: 18, color: C.mute)),
            )),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
            for (final c in list)
              InkWell(
                onTap: () => push(context, ChatScreen(seller: c.$2, initials: c.$1)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Stack(children: [
                      CircleAvatar(
                          radius: 22,
                          backgroundColor: C.blue,
                          child: Text(c.$1,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                      if (c.$6)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2)),
                          ),
                        ),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(c.$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: C.mute)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Column(children: [
                      Text(c.$4, style: const TextStyle(fontSize: 10, color: C.mute)),
                      const SizedBox(height: 4),
                      if (c.$5 > 0)
                        CircleAvatar(
                            radius: 9,
                            backgroundColor: C.amber,
                            child: Text('${c.$5}',
                                style: const TextStyle(fontSize: 10, color: C.ink, fontWeight: FontWeight.w700))),
                    ]),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ───────────── Chat penjual ─────────────
class ChatScreen extends StatefulWidget {
  final String seller;
  final String initials;
  const ChatScreen({super.key, required this.seller, this.initials = 'BK'});
  @override
  State<ChatScreen> createState() => _ChatState();
}

class _ChatState extends State<ChatScreen> {
  final ctrl = TextEditingController();
  final scroll = ScrollController();
  // (dari saya?, teks, jam, kartu produk?)
  final msgs = <(bool, String, String, bool)>[
    (false, 'Halo kak, ikan Plakat Blue Rim masih ready?', '13:20', false),
    (true, 'Halo! Ready kak, ini fotonya ya 😊', '13:21', false),
    (true, 'Plakat Blue Rim - Grade A', '13:21', true),
    (false, 'Boleh nego kak? Kalau ambil 2 ekor', '13:24', false),
    (true, 'Bisa kak, saya kasih Rp 470.000 untuk 2 ekor 👍', '13:26', false),
    (false, 'Oke deal kak, saya order sekarang ya', '13:28', false),
    (true, 'Kak, ikan sudah kami packing, siap kirim besok pagi.', '13:45', false),
  ];

  void _send() {
    final t = ctrl.text.trim();
    if (t.isEmpty) return;
    final now = TimeOfDay.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    setState(() => msgs.add((false, t, '$hh:$mm', false)));
    ctrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    ctrl.dispose();
    scroll.dispose();
    super.dispose();
  }

  Widget _bubble((bool, String, String, bool) m) {
    final seller = m.$1;
    return Align(
      alignment: seller ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .72),
        decoration: BoxDecoration(
          color: seller ? Colors.white : null,
          gradient: seller ? null : const LinearGradient(colors: [C.navy, C.blue]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(seller ? 2 : 14),
            bottomRight: Radius.circular(seller ? 14 : 2),
          ),
          boxShadow: const [BoxShadow(color: C.shadow, blurRadius: 6)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          if (m.$4)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: C.field, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        gradient: darkCard, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.set_meal, size: 18, color: C.orange)),
                const SizedBox(width: 8),
                Text(m.$2,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12, color: C.ink)),
              ]),
            )
          else
            Align(
                alignment: Alignment.centerLeft,
                child: Text(m.$2,
                    style: TextStyle(color: seller ? C.ink : Colors.white, fontSize: 13))),
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(m.$3,
                style: TextStyle(fontSize: 9, color: seller ? C.mute : Colors.white70)),
            if (!seller) ...[
              const SizedBox(width: 3),
              const Icon(Icons.done_all, size: 12, color: Colors.white70),
            ],
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          WaveHeader(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(children: [
                  const RoundBack(),
                  const SizedBox(width: 12),
                  CircleAvatar(
                      radius: 18,
                      backgroundColor: C.amber,
                      child: Text(widget.initials,
                          style: const TextStyle(
                              color: C.ink, fontWeight: FontWeight.w800, fontSize: 12))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.seller,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                      const Row(children: [
                        CircleAvatar(radius: 3, backgroundColor: Colors.greenAccent),
                        SizedBox(width: 4),
                        Text('Online', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
          Expanded(
            child: ListView(controller: scroll, padding: const EdgeInsets.all(16), children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: C.field, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Hari Ini, 13:20',
                      style: TextStyle(fontSize: 10, color: C.mute)),
                ),
              ),
              for (final m in msgs) _bubble(m),
            ]),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(children: [
                const Icon(Icons.attach_file, color: C.mute),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    onSubmitted: (_) => _send(),
                    decoration: fieldDec('Tulis pesan...', fill: C.field)
                        .copyWith(border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: C.blue,
                      child: Icon(Icons.send, size: 18, color: Colors.white)),
                ),
              ]),
            ),
          ),
        ]),
      );
}

// ───────────── Form klaim garansi (dipakai di Profil & layar klaim) ─────────────
class ClaimForm extends StatefulWidget {
  const ClaimForm({super.key});
  @override
  State<ClaimForm> createState() => _ClaimFormState();
}

class _ClaimFormState extends State<ClaimForm> {
  String? orderId;
  bool hasVideo = false;
  bool sent = false;

  @override
  Widget build(BuildContext context) {
    final ids = cart.orders.map((o) => o.id).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (sent)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFFFF6DD), borderRadius: BorderRadius.circular(12)),
          child: const Row(children: [
            Icon(Icons.hourglass_top, color: C.amberDark, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Klaim garansi Anda sedang kami tinjau.', style: TextStyle(fontSize: 12))),
          ]),
        ),
      const Text('Form Klaim Garansi Ikan Mati',
          style: TextStyle(fontWeight: FontWeight.w800, color: C.navy)),
      const SizedBox(height: 4),
      const Text(
          'Silakan unggah video unboxing tanpa terputus sebagai syarat utama pengajuan klaim garansi kematian ikan.',
          style: TextStyle(fontSize: 11, color: C.mute)),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () => setState(() => hasVideo = true),
        child: Container(
          height: 110,
          width: double.infinity,
          decoration: BoxDecoration(
            color: C.field,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: hasVideo ? Colors.green : C.sky, width: 1.4),
          ),
          child: Center(
            child: hasVideo
                ? const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.videocam, color: Colors.green),
                    SizedBox(width: 8),
                    Text('unboxing.mp4 terpilih'),
                  ])
                : const Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.upload_outlined, size: 28, color: C.blue),
                    SizedBox(height: 4),
                    Text('Upload Video Unboxing', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('Format MP4, MOV (Maks. 50MB)', style: TextStyle(fontSize: 10, color: C.mute)),
                  ]),
          ),
        ),
      ),
      fieldLabel('ID Pesanan'),
      DropdownButtonFormField<String>(
        initialValue: orderId,
        isExpanded: true,
        hint: const Text('Pilih pesanan yang bermasalah...', style: TextStyle(fontSize: 13)),
        decoration: fieldDec(''),
        items: [for (final id in ids) DropdownMenuItem(value: id, child: Text(id))],
        onChanged: (v) => setState(() => orderId = v),
      ),
      if (ids.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('Belum ada pesanan untuk diklaim.',
              style: TextStyle(fontSize: 11, color: C.mute)),
        ),
      fieldLabel('Catatan Tambahan (opsional)'),
      TextField(maxLines: 3, decoration: fieldDec('Jelaskan kondisi ikan saat diterima...')),
      const SizedBox(height: 14),
      Btn('Ajukan Klaim',
          gold: true,
          onTap: (orderId == null || !hasVideo) ? null : () => setState(() => sent = true)),
    ]);
  }
}

class ClaimScreen extends StatelessWidget {
  const ClaimScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          const AppHeader('Pusat Klaim Garansi'),
          const Expanded(child: _ClaimBody()),
        ]),
      );
}

class _ClaimBody extends StatelessWidget {
  const _ClaimBody();
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Ajukan & pantau klaim garansi',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          SizedBox(height: 12),
          ClaimForm(),
        ],
      );
}

// ───────────── Profil (tab) ─────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  bool claimOpen = false;

  Widget _stat(String v, String l) => Expanded(
        child: Column(children: [
          Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: C.navy)),
          Text(l, style: const TextStyle(fontSize: 11, color: C.mute)),
        ]),
      );

  Widget _row(IconData i, String t, String s, VoidCallback onTap,
          {Color color = C.blue, Widget? trailing}) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: color.withAlpha(30), borderRadius: BorderRadius.circular(10)),
              child: Icon(i, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color == Colors.red ? Colors.red : C.ink)),
                Text(s, style: const TextStyle(fontSize: 11, color: C.mute)),
              ]),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: C.mute),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListView(padding: EdgeInsets.zero, children: [
          WaveHeader(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(children: [
                  Stack(children: [
                    const CircleAvatar(
                        radius: 40,
                        backgroundColor: C.skySoft,
                        child: Icon(Icons.person, size: 44, color: Colors.white)),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(color: C.amber, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 12, color: C.ink),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Pasha',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  const Text('pasha@email.com',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(children: [
              Box(
                child: Row(children: [
                  ListenableBuilder(
                      listenable: cart,
                      builder: (_, __) => _stat('${cart.orders.length + 12}', 'Pesanan')),
                  _stat('4,9', 'Rating'),
                  _stat('1', 'Klaim Aktif'),
                ]),
              ),
              Box(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _row(Icons.receipt_long, 'Riwayat Pesanan', '12 pesanan',
                      () => push(context, const OrdersScreen(back: true))),
                  const Divider(height: 1, color: C.line),
                  _row(Icons.shield_outlined, 'Pusat Klaim Garansi Ikan Mati',
                      'Ajukan & pantau klaim garansi',
                      () => setState(() => claimOpen = !claimOpen),
                      color: C.amberDark,
                      trailing: Icon(claimOpen ? Icons.expand_less : Icons.expand_more, color: C.mute)),
                  if (claimOpen)
                    const Padding(
                        padding: EdgeInsets.fromLTRB(14, 0, 14, 14), child: ClaimForm()),
                  const Divider(height: 1, color: C.line),
                  _row(Icons.chat_bubble_outline, 'Pesan', 'Chat dengan penjual',
                      () => push(context, const MessagesScreen())),
                  const Divider(height: 1, color: C.line),
                  _row(Icons.notifications_none, 'Notifikasi', 'Lelang, pesanan, promo',
                      () => push(context, const NotificationScreen())),
                  const Divider(height: 1, color: C.line),
                  _row(Icons.settings_outlined, 'Pengaturan Akun', 'Profil, alamat, keamanan',
                      () => push(context, const EditProfileScreen())),
                ]),
              ),
              Box(
                padding: EdgeInsets.zero,
                child: _row(Icons.logout, 'Keluar', 'Keluar dari akun ini',
                    () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const SplashScreen()),
                        (r) => false),
                    color: Colors.red),
              ),
            ]),
          ),
        ]),
      );
}

// ───────────── Edit Profil ─────────────
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListView(padding: EdgeInsets.zero, children: [
          WaveHeader(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(children: [
                  const Row(children: [
                    RoundBack(),
                    SizedBox(width: 12),
                    Text('Edit Profil',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  ]),
                  const SizedBox(height: 10),
                  Stack(children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: const BoxDecoration(color: C.skySoft, shape: BoxShape.circle),
                      child: const Icon(Icons.person, size: 44, color: Colors.white),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(color: C.amber, shape: BoxShape.circle),
                        child: const Icon(Icons.photo_camera, size: 12, color: C.ink),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _F('Nama Lengkap', 'PASHA', Icons.person_outline),
              _F('Username', 'Pasha_betta', Icons.alternate_email),
              _F('Email', 'pasha@email.com', Icons.mail_outline, verified: true),
              _F('Nomor Handphone', '+62 812-3456-7890', Icons.phone_outlined),
              const SizedBox(height: 18),
              Btn('Simpan Profile', onTap: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Perubahan disimpan')));
                Navigator.pop(context);
              }),
              const SizedBox(height: 20),
              const Row(children: [
                Expanded(child: Divider(color: C.line)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('KEAMANAN AKUN',
                      style: TextStyle(fontSize: 10, color: C.mute, letterSpacing: 1)),
                ),
                Expanded(child: Divider(color: C.line)),
              ]),
              const SizedBox(height: 12),
              Box(
                child: Row(children: [
                  const Icon(Icons.lock_outline, color: C.blue, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Kata Sandi', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text('Terakhir diubah 2 bulan lalu',
                          style: TextStyle(fontSize: 11, color: C.mute)),
                    ]),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(backgroundColor: C.field),
                    onPressed: () => push(context, const ForgotPasswordScreen()),
                    child: const Text('Ubah', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      );
}

class _F extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool verified;
  const _F(this.label, this.value, this.icon, {this.verified = false});

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        fieldLabel(label),
        TextFormField(
          initialValue: value,
          decoration: fieldDec(label,
              fill: C.field,
              prefix: Icon(icon, size: 18, color: C.navy),
              suffix: verified
                  ? const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Center(
                          widthFactor: 1,
                          child: Text('✓ Terverifikasi',
                              style: TextStyle(color: Colors.green, fontSize: 10))))
                  : null),
        ),
      ]);
}
