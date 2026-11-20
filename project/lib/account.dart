import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/api_client.dart';
import 'api/chat_api.dart';
import 'api/user_api.dart';
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
  String q = '';
  String lastMsg = 'Ketuk untuk memulai obrolan dengan penjual';
  String lastTime = '';

  @override
  void initState() {
    super.initState();
    _checkLastMsg();
  }

  Future<void> _checkLastMsg() async {
    try {
      final remote = await ChatApi.getSyncMessages();
      if (remote.isNotEmpty && mounted) {
        final last = remote.last;
        setState(() {
          lastMsg = last['body']?.toString() ?? 'Pesan baru';
          lastTime = last['createdAt'] != null && last['createdAt'].toString().length >= 16
              ? last['createdAt'].toString().substring(11, 16)
              : '';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        AppHeader('Pesan',
            bottom: TextField(
              onChanged: (v) => setState(() => q = v),
              decoration: fieldDec('Cari percakapan atau toko...',
                  prefix: const Icon(Icons.search, size: 18, color: C.mute)),
            )),
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
            InkWell(
              onTap: () async {
                await push(context, const ChatScreen(seller: 'Betta King Jakarta (Penjual Official)', initials: 'BK'));
                _checkLastMsg();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: C.shadow, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(children: [
                  Stack(children: [
                    const CircleAvatar(
                        radius: 22,
                        backgroundColor: C.navy,
                        child: Text('BK',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
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
                      const Row(children: [
                        Text('Betta King Jakarta', style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(width: 6),
                        Pill('Official Store', bg: C.field, fg: C.navy),
                      ]),
                      const SizedBox(height: 3),
                      Text(lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: C.mute)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(lastTime, style: const TextStyle(fontSize: 10, color: C.mute)),
                    const SizedBox(height: 4),
                    const Icon(Icons.chevron_right, size: 18, color: C.mute),
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
  Timer? _poller;

  // Mulai dari nol / kosong (tidak ada data demo)
  final msgs = <(bool, String, String, bool)>[];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _poller = Timer.periodic(const Duration(milliseconds: 1500), (_) => _syncIncoming());
  }

  @override
  void dispose() {
    _poller?.cancel();
    ctrl.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final remote = await ChatApi.getSyncMessages();
      if (mounted) {
        final newMsgs = <(bool, String, String, bool)>[];
        for (final m in remote) {
          final isSeller = m['sender'] == 'SELLER';
          final body = m['body']?.toString() ?? '';
          final timeStr = m['createdAt'] != null && m['createdAt'].toString().length >= 16
              ? m['createdAt'].toString().substring(11, 16)
              : 'Baru saja';
          newMsgs.add((isSeller, body, timeStr, false));
        }
        setState(() {
          msgs.clear();
          msgs.addAll(newMsgs);
        });
        _scrollToEnd();
      }
    } catch (_) {}
  }

  Future<void> _syncIncoming() async {
    try {
      final remote = await ChatApi.getSyncMessages();
      if (remote.length != msgs.length && mounted) {
        final newMsgs = <(bool, String, String, bool)>[];
        for (final m in remote) {
          final isSeller = m['sender'] == 'SELLER';
          final body = m['body']?.toString() ?? '';
          final timeStr = m['createdAt'] != null && m['createdAt'].toString().length >= 16
              ? m['createdAt'].toString().substring(11, 16)
              : 'Baru saja';
          newMsgs.add((isSeller, body, timeStr, false));
        }
        setState(() {
          msgs.clear();
          msgs.addAll(newMsgs);
        });
        _scrollToEnd();
      }
    } catch (_) {}
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _send() {
    final t = ctrl.text.trim();
    if (t.isEmpty) return;
    final now = TimeOfDay.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    setState(() => msgs.add((false, t, '$hh:$mm', false)));
    ctrl.clear();
    _scrollToEnd();

    // Kirim pesan ke backend & sinkronkan seketika ke dashboard penjual
    ChatApi.sendSyncMessage(t);
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
            child: msgs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: C.mute.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'Mulai Obrolan',
                            style: TextStyle(
                              color: C.navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tanyakan seputar kualitas ikan, garansi pengiriman, atau lelang langsung ke penjual.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: C.mute, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(controller: scroll, padding: const EdgeInsets.all(16), children: [
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
  Map<String, dynamic> _user = Map<String, dynamic>.from(ApiClient.instance.user ?? {});

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final latest = await UserApi.getProfile();
      if (!mounted) return;
      setState(() {
        _user = Map<String, dynamic>.from(latest);
      });
    } catch (_) {
      // Tetap gunakan data cache dari ApiClient jika offline
      if (mounted) {
        final cached = ApiClient.instance.user;
        if (cached != null && cached.isNotEmpty) {
          setState(() {
            _user = Map<String, dynamic>.from(cached);
          });
        } else {
          try {
            final prefs = await SharedPreferences.getInstance();
            final raw = prefs.getString('local_registered_users');
            if (raw != null) {
              final users = jsonDecode(raw) as List;
              if (users.isNotEmpty) {
                final last = Map<String, dynamic>.from(users.last as Map);
                setState(() {
                  _user = last;
                });
              }
            }
          } catch (_) {}
        }
      }
    }
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(initialUser: _user),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _user = Map<String, dynamic>.from(updated as Map);
      });
    }
  }

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
                Text(t,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color == Colors.red ? Colors.red : C.ink)),
                Text(s, style: const TextStyle(fontSize: 11, color: C.mute)),
              ]),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: C.mute),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final rawName = _user['name'] ?? ApiClient.instance.user?['name'];
    final rawEmail = _user['email'] ?? ApiClient.instance.user?['email'];
    final displayName = (rawName != null && rawName.toString().trim().isNotEmpty)
        ? rawName.toString()
        : 'Pengguna eCupFish';
    final displayEmail = (rawEmail != null && rawEmail.toString().trim().isNotEmpty)
        ? rawEmail.toString()
        : '-';

    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        WaveHeader(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Column(children: [
                GestureDetector(
                  onTap: _openEditProfile,
                  child: Stack(children: [
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
                ),
                const SizedBox(height: 8),
                Text(displayName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                Text(displayEmail,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                    builder: (_, __) => _stat('${cart.orders.length}', 'Pesanan')),
                _stat('5.0', 'Rating'),
                _stat('0', 'Klaim Aktif'),
              ]),
            ),
            Box(
              padding: EdgeInsets.zero,
              child: Column(children: [
                ListenableBuilder(
                    listenable: cart,
                    builder: (_, __) => _row(Icons.receipt_long, 'Riwayat Pesanan',
                        '${cart.orders.length} pesanan aktif',
                        () => push(context, const OrdersScreen(back: true)))),
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
                    _openEditProfile),
              ]),
            ),
            Box(
              padding: EdgeInsets.zero,
              child: _row(Icons.logout, 'Keluar', 'Keluar dari akun ini',
                  () async {
                    await ApiClient.instance.clear();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const SplashScreen()),
                        (r) => false);
                  },
                  color: Colors.red),
            ),
            const SizedBox(height: 90), // Spasi agar tidak tertutup bottom bar navigasi
          ]),
        ),
      ]),
    );
  }
}

// ───────────── Edit Profil ─────────────
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialUser;

  const EditProfileScreen({super.key, this.initialUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _phoneCtrl;
  late final String _email;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.initialUser ?? ApiClient.instance.user ?? {};
    _nameCtrl = TextEditingController(text: (u['name'] ?? '').toString());
    _usernameCtrl = TextEditingController(text: (u['username'] ?? '').toString());
    _phoneCtrl = TextEditingController(text: (u['phoneNumber'] ?? '').toString());
    _email = (u['email'] ?? '').toString();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpanProfil() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final updatedUser = await UserApi.updateProfile(
        name: _nameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
      Navigator.pop(context, updatedUser);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        const AppHeader('Edit Profil'),
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                fieldLabel('Nama Lengkap'),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: fieldDec('Masukkan nama lengkap',
                      fill: C.field,
                      prefix: const Icon(Icons.person_outline, size: 18, color: C.navy)),
                  validator: (v) =>
                      (v == null || v.trim().length < 2) ? 'Nama minimal 2 karakter' : null,
                ),
                fieldLabel('Username'),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: fieldDec('Masukkan username',
                      fill: C.field,
                      prefix: const Icon(Icons.alternate_email, size: 18, color: C.navy)),
                  validator: (v) =>
                      (v == null || v.trim().length < 3) ? 'Username minimal 3 karakter' : null,
                ),
                fieldLabel('Email'),
                TextFormField(
                  initialValue: _email,
                  readOnly: true,
                  decoration: fieldDec('Email',
                      fill: C.field,
                      prefix: const Icon(Icons.mail_outline, size: 18, color: C.navy),
                      suffix: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Center(
                            widthFactor: 1,
                            child: Text('✓ Terverifikasi',
                                style: TextStyle(color: Colors.green, fontSize: 10))),
                      )),
                ),
                fieldLabel('Nomor Telepon'),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: fieldDec('Contoh: 08123456789',
                      fill: C.field,
                      prefix: const Icon(Icons.phone_outlined, size: 18, color: C.navy)),
                ),
                const SizedBox(height: 20),
                Btn(
                  _saving ? 'Menyimpan...' : 'Simpan Perubahan',
                  gold: true,
                  onTap: _saving ? null : _simpanProfil,
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}