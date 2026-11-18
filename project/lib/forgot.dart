import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'api/auth_api.dart';
import 'api/api_client.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotState();
}

class _ForgotState extends State<ForgotPasswordScreen> {
  int step = 0;
  final email = TextEditingController();
  final p1 = TextEditingController();
  final p2 = TextEditingController();
  final otp = List.generate(6, (_) => TextEditingController());
  final nodes = List.generate(6, (_) => FocusNode());
  String? err;
  
  String? _resetToken;
  bool busy = false;

  @override
  void dispose() {
    for (final c in [email, p1, p2, ...otp]) {
      c.dispose();
    }
    for (final n in nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get masked {
    final v = email.text.trim();
    final i = v.indexOf('@');
    if (i < 2) return v.isEmpty ? 'bu***@email.com' : v;
    return '${v.substring(0, 2)}***${v.substring(i)}';
  }

  Future<void> _next() async {
    if (busy) return;

    String? e;
    if (step == 0) {
      final v = email.text.trim();
      if (!v.contains('@') && v.replaceAll(RegExp(r'\D'), '').length < 9) {
        e = 'Masukkan email atau nomor HP yang valid';
      }
    } else if (step == 1) {
      if (otp.any((c) => c.text.isEmpty)) e = 'Lengkapi 6 digit kode OTP';
    } else {
      if (p1.text.length < 8) {
        e = 'Kata sandi minimal 8 karakter';
      } else if (p1.text != p2.text) {
        e = 'Konfirmasi kata sandi tidak sama';
      }
    }
    
    setState(() => err = e);
    if (e != null) return;
  
    setState(() => busy = true);
    try {
      if (step == 0) {
        await AuthApi.forgotPassword(email.text);
        setState(() => step = 1);
      } else if (step == 1) {
        final kode = otp.map((c) => c.text).join();
        _resetToken = await AuthApi.verifyOtp(email.text, kode);
        setState(() => step = 2);
      } else {
        await AuthApi.resetPassword(_resetToken!, p1.text);
        _success(); 
      }
    } on ApiException catch (e) { 
      if (mounted) setState(() => err = e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _success() => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircleAvatar(
                  radius: 26,
                  backgroundColor: C.blue, 
                  child: Icon(Icons.check, color: Colors.white, size: 28)),
              const SizedBox(height: 14),
              const Text('Kata Sandi Berhasil Diubah',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 6),
              const Text('Silakan masuk kembali menggunakan kata sandi baru Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: C.mute)), 
              const SizedBox(height: 16),
              Btn('Login', onTap: () { 
                Navigator.pop(ctx);
                Navigator.pop(context);
              }),
            ]),
          ),
        ),
      );

  Widget _icon(IconData i) => Center(
        child: CircleAvatar(
            radius: 28, backgroundColor: C.field, child: Icon(i, color: C.blue)),
      );

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Center(
            child: Text(t,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
      );

  Widget _hint(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            textAlign: TextAlign.center,
            style: const TextStyle(color: C.mute, fontSize: 12)), // Asumsi C.mute didefinisikan di core.dart
      );

  Widget _otpBox(int i) => SizedBox(
        width: 54,
        height: 54,
        child: TextField(
          controller: otp[i],
          focusNode: nodes[i],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          decoration: fieldDec('', fill: C.field).copyWith(counterText: ''), 
          onChanged: (v) {
            if (v.isNotEmpty && i < 5) nodes[i + 1].requestFocus();
            if (v.isEmpty && i > 0) nodes[i - 1].requestFocus();
          },
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(children: [
              const AppHeader('Lupa Kata Sandi'), 
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(children: [
                  for (var i = 0; i < 3; i++) 
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                        decoration: BoxDecoration(
                            color: i <= step ? C.blue : C.line, 
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                ]),
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.all(22), children: [
                  if (err != null) errorBanner(err!), 
                  if (step == 0) ...[
                    _icon(Icons.mail_outline),
                    _title('Lupa Kata Sandi?'),
                    _hint('Masukkan email atau nomor HP yang terdaftar. Kami akan mengirimkan kode verifikasi (OTP) ke sana.'),
                    LField('Email / No. HP',
                        hint: 'Contoh: user@email.com',
                        icon: Icons.mail_outline,
                        controller: email,
                        fill: C.field),
                    const SizedBox(height: 18),
                    Btn('Kirim Kode OTP', onTap: busy ? null : _next),
                  ],
                  if (step == 1) ...[
                    _icon(Icons.lock_outline),
                    _title('Masukkan Kode OTP'),
                    _hint('Kode verifikasi telah dikirim ke $masked'),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (var i = 0; i < 6; i++)
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4), 
                            child: _otpBox(i)),
                    ]),
                    const SizedBox(height: 12),
                    Center(
                      child: GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kode OTP dikirim ulang'))),
                        child: const Text.rich(TextSpan(children: [
                          TextSpan(text: 'Tidak menerima kode? ', style: TextStyle(color: C.mute)),
                          TextSpan(
                              text: 'Kirim ulang (30s)',
                              style: TextStyle(color: C.blue, fontWeight: FontWeight.w700)),
                        ]), style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Btn('Verifikasi', onTap: busy ? null : _next),
                  ],
                  if (step == 2) ...[
                    _icon(Icons.lock_outline),
                    _title('Buat Kata Sandi Baru'),
                    _hint('Pastikan kata sandi baru berbeda dari yang sebelumnya pernah digunakan.'),
                    LField('Kata Sandi Baru',
                        hint: 'Minimal 8 karakter',
                        password: true,
                        controller: p1,
                        fill: C.field),
                    LField('Konfirmasi Kata Sandi',
                        hint: 'Ulangi kata sandi baru',
                        password: true,
                        controller: p2,
                        fill: C.field),
                    const SizedBox(height: 18),
                    Btn('Simpan Kata Sandi', onTap: busy ? null : _next),
                  ],
                ]),
              ),
            ]),
            if (busy) const Center(child: CircularProgressIndicator()), 
          ],
        ),
      );
}