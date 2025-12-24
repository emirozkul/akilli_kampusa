import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/giris_ekrani.dart';
import 'screens/admin_sayfasi.dart';
import 'screens/kampus_harita_sayfasi.dart';
import 'services/auth_servisi.dart';

import 'package:intl/date_symbol_data_local.dart'; // Tarih formatı başlatıcı

/// Uygulamanın giriş noktası
/// Firebase'i başlatır ve uygulamayı çalıştırır
void main() async {
  // Flutter binding'lerinin başlatıldığından emin ol
  // Firebase gibi native kodlar kullanmadan önce gerekli
  WidgetsFlutterBinding.ensureInitialized();

  // Tarih yerelleştirmesini başlat (Türkçe için)
  await initializeDateFormatting('tr_TR', null);

  // Firebase'i başlat
  // firebase_options.dart dosyasındaki yapılandırmayı kullanır
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Uygulamayı başlat
  runApp(const AkilliKampusUygulamasi());
}

/// Ana uygulama widget'ı
/// MaterialApp yapılandırmasını içerir
class AkilliKampusUygulamasi extends StatelessWidget {
  const AkilliKampusUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Uygulama başlığı
      title: 'Akıllı Kampüs',

      // Debug banner'ını kapat (sağ üst köşedeki "DEBUG" yazısı)
      debugShowCheckedModeBanner: false,

      // Uygulama teması
      theme: ThemeData(
        // Modern ve canlı renk paleti
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EE), // Derin Mor (Primary)
          secondary: const Color(0xFF03DAC6), // Turkuaz (Secondary)
          tertiary: const Color(0xFFFF0266), // Canlı Pembe (Accent)
          background: const Color(0xFFF5F5F5), // Kırık Beyaz (Background)
          brightness: Brightness.light,
        ),

        // AppBar teması
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0, // Düz tasarım
          backgroundColor: Color(0xFF6200EE), // Primary color
          foregroundColor: Colors.white,
        ),

        // Genel kullanılabilirlik ayarları
        useMaterial3: true,
      ),

      // Ana sayfa: Auth kontrolü ile
      home: const AuthKontrol(),
    );
  }
}

/// Authentication durumunu kontrol eden widget
/// Kullanıcı giriş durumuna göre sayfa yönlendirme yapar
class AuthKontrol extends StatelessWidget {
  const AuthKontrol({super.key});

  @override
  Widget build(BuildContext context) {
    // Auth servisi
    final AuthServisi authServisi = AuthServisi();

    // Firebase Auth durumunu dinle
    return StreamBuilder<User?>(
      stream: authServisi.authDurumuDinle,
      builder: (context, snapshot) {
        // Bağlantı durumu kontrol et
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Yüklenirken loading göster
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Kullanıcı giriş yapmış mı kontrol et
        if (snapshot.hasData) {
          // Kullanıcı giriş yapmış - rolünü kontrol et
          return FutureBuilder<String?>(
            future: authServisi.kullaniciRolunuGetir(),
            builder: (context, rolSnapshot) {
              // Rol bilgisi yüklenirken
              if (rolSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Rol bilgisine göre yönlendir
              String? rol = rolSnapshot.data;
              
              if (rol == 'Admin') {
                // Admin ise admin sayfasına git
                return const AdminSayfasi();
              } else {
                // User ise harita sayfasına git
                return const KampusHaritaSayfasi();
              }
            },
          );
        } else {
          // Kullanıcı giriş yapmamış - giriş ekranına yönlendir
          return const GirisEkrani();
        }
      },
    );
  }
}
