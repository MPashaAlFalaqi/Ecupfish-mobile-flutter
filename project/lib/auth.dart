import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'account.dart';
import 'core.dart';
import 'forgot.dart';
import 'order.dart';
import 'shop.dart';

// ───────────── Splash / Onboarding ─────────────
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: headerGradient),
          child: Column(children: [
            Expanded(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(
                      child: Image.asset('assets/images/logo.png',
                          fit: BoxFit.contain)),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: C.line, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 22),
                  const Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'eCup', style: TextStyle(color: C.navy)),
                      TextSpan(text: 'Fish', style: TextStyle(color: C.amber)),
                    ]),
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Platform Jual Beli & Lelang Ikan Cupang\nTerpercaya di Indonesia',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: C.mute, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Wrap(spacing: 8, children: [
                    Pill('Jual Beli', bg: C.field, fg: C.navy),
                    Pill('Lelang Live', bg: C.field, fg: C.navy),
                    Pill('Garansi 100%', bg: C.field, fg: C.navy),
                  ]),
                  const SizedBox(height: 22),
                  Btn('Masuk', onTap: () => push(context, const LoginScreen())),
                  LinkLine('Belum punya akun?', 'Daftar',
                      onTap: () => push(context, const RegisterScreen())),
                ]),
              ),
            ),
          ]),
        ),
      );
}

void _enterApp(BuildContext context) => Navigator.pushAndRemoveUntil(
    context, MaterialPageRoute(builder: (_) => const MainShell()), (r) => false);

// ───────────── Masuk Akun ─────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  String? error;
  int fails = 0;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  void _login() {
    if (email.text.trim().isEmpty || pass.text.length < 6) {
      fails++;
      if (fails >= 3) {
        setState(() => error = null);
        _showLocked();
      } else {
        setState(() => error =
            'Email atau kata sandi yang kamu masukkan salah. Coba periksa kembali, atau reset kata sandi jika lupa.');
      }
      return;
    }
    _enterApp(context);
  }

  void _showLocked() => showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, color: Colors.white, size: 28)),
              const SizedBox(height: 14),
              const Text('Mohon Maaf',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w800, fontSize: 17)),
              const Text('Email atau Password anda salah',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              const Text(
                  'Anda sudah salah beberapa kali, segera atur ulang password anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: C.mute)),
              const SizedBox(height: 16),
              Btn('Atur Ulang Password', gold: true, onTap: () {
                Navigator.pop(ctx);
                push(context, const ForgotPasswordScreen());
              }),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          AppHeader('Masuk Akun',
              bottom: Image.asset('assets/images/logo.png', height: 150)),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), children: [
              const Center(
                  child: Text('Silakan masuk ke akun Anda',
                      style: TextStyle(color: C.navy, fontSize: 17, fontWeight: FontWeight.w500))),
              const SizedBox(height: 10),
              if (error != null) errorBanner(error!),
              LField('Email',
                  hint: 'Masukkan Email Anda',
                  controller: email,
                  keyboard: TextInputType.emailAddress),
              LField('Password',
                  hint: '••••••••',
                  controller: pass,
                  password: true,
                  required: true,
                  helper: 'Hint text to help users'),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => push(context, const ForgotPasswordScreen()),
                  child: const Text('Lupa Kata Sandi?',
                      style: TextStyle(color: C.navy, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
              Btn('Masuk', onTap: _login),
              const SizedBox(height: 14),
              const OrDivider(),
              const SizedBox(height: 14),
              GoldOutlineBtn('Google', onTap: () => _enterApp(context)),
              const SizedBox(height: 6),
              LinkLine('Belum punya akun?', 'Daftar di sini.',
                  onTap: () => push(context, const RegisterScreen())),
            ]),
          ),
        ]),
      );
}

// ───────────── Daftar Akun ─────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  String? error;

  @override
  void dispose() {
    for (final c in [name, phone, address, email, pass]) {
      c.dispose();
    }
    super.dispose();
  }

  void _register() {
    final digits = phone.text.replaceAll(RegExp(r'\D'), '');
    String? e;
    if (name.text.trim().isEmpty) {
      e = 'Nama lengkap wajib diisi.';
    } else if (digits.length < 9) {
      e = 'Nomor handphone tidak valid.';
    } else if (!email.text.contains('@')) {
      e = 'Email tidak valid.';
    } else if (pass.text.length < 6) {
      e = 'Kata sandi minimal 6 karakter.';
    }
    setState(() => error = e);
    if (e != null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Akun berhasil dibuat. Silakan masuk.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(children: [
          AppHeader('Masuk Akun',
              bottom: Image.asset('assets/images/logo.png', height: 150)),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), children: [
              const Center(
                  child: Text('Daftarkan Akun Anda',
                      style: TextStyle(color: C.navy, fontSize: 17, fontWeight: FontWeight.w500))),
              const SizedBox(height: 4),
              if (error != null) errorBanner(error!),
              LField('Nama Lengkap', hint: 'Masukkan nama lengkap anda', controller: name),
              LField('Nomor Handphone',
                  hint: '878 0299 ...',
                  prefixText: '+62',
                  controller: phone,
                  keyboard: TextInputType.phone),
              LField('Alamat', hint: 'Masukkan Alamat Anda', controller: address),
              LField('Masukkan Email Anda',
                  hint: 'Masukkan Email Anda',
                  controller: email,
                  keyboard: TextInputType.emailAddress),
              LField('Password',
                  hint: '••••••••',
                  controller: pass,
                  password: true,
                  required: true,
                  helper: 'Minimal 6 karakter'),
              const SizedBox(height: 18),
              Btn('Daftar Akun', onTap: _register),
              const SizedBox(height: 14),
              const OrDivider(),
              const SizedBox(height: 14),
              GoldOutlineBtn('Google', onTap: () => _enterApp(context)),
              const SizedBox(height: 6),
              LinkLine('Sudah punya akun?', 'Masuk', onTap: () => Navigator.pop(context)),
            ]),
          ),
        ]),
      );
}

// ───────────── Shell dengan navigasi bawah gelap ─────────────
class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late int index = widget.initialIndex;

  // animasi fade + naik pelan saat pindah tab
  late final AnimationController _swap = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 340), value: 1);
  late final Animation<double> _swapCurve =
      CurvedAnimation(parent: _swap, curve: Curves.easeOutCubic);

  static const items = [
    (Icons.home_outlined, Icons.home, 'Beranda'),
    (Icons.gavel_outlined, Icons.gavel, 'Lelang'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Pesanan'),
    (Icons.person_outline, Icons.person, 'Profil'),
  ];

  @override
  void dispose() {
    _swap.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (i == index) return;
    HapticFeedback.selectionClick();
    setState(() => index = i);
    _swap.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AnimatedBuilder(
          animation: _swapCurve,
          child: IndexedStack(index: index, children: const [
            HomeScreen(),
            AuctionScreen(tab: true),
            OrdersScreen(),
            ProfileScreen(),
          ]),
          builder: (_, child) => Opacity(
            opacity: _swapCurve.value.clamp(0.0, 1.0).toDouble(),
            child: Transform.translate(
                offset: Offset(0, (1 - _swapCurve.value) * 14), child: child),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              gradient: headerGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [BoxShadow(color: C.shadow, blurRadius: 14, offset: Offset(0, 4))],
            ),
            child: Row(children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _go(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: index == i ? const Color(0x1FFFFFFF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        AnimatedScale(
                          scale: index == i ? 1.18 : 1,
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutBack,
                          child: Icon(index == i ? items[i].$2 : items[i].$1,
                              color: index == i ? C.amber : Colors.white70, size: 22),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: index == i ? FontWeight.w700 : FontWeight.w400,
                              color: index == i ? C.amber : Colors.white70),
                          child: Text(items[i].$3),
                        ),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      );
}
