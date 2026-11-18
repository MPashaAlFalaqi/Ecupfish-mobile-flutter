import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth.dart';
import 'core.dart';
import 'responsive.dart';
import 'api/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.load();
  runApp(const ECupFishApp()); // gunakan pemanggilan runApp yang sudah ada
}

class ECupFishApp extends StatelessWidget {
  const ECupFishApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'eCupFish',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // menyesuaikan semua ukuran layar Android (lihat responsive.dart)
        builder: (context, child) =>
            ResponsiveFrame(child: child ?? const SizedBox()),
        home: const SplashScreen(),
      );
}
