import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcı bilgilerini tutan model sınıfı
/// Firebase Authentication ve Firestore ile kullanılır
class Kullanici {
  
  // Kullanıcı özellikleri
  final String id;              // Firebase Auth UID
  final String ad;              // Kullanıcı adı
  final String soyad;           // Kullanıcı soyadı
  final String eposta;          // E-posta adresi
  final String bolum;           // Bölüm bilgisi (örn: "Bilgisayar Mühendisliği")
  final String rol;             // Kullanıcı rolü: "Admin" veya "User"
  final DateTime kayitTarihi;   // Hesap oluşturulma tarihi

  /// Constructor - Yeni kullanıcı nesnesi oluşturur
  Kullanici({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.eposta,
    required this.bolum,
    required this.rol,
    required this.kayitTarihi,
  });

  /// Firebase Firestore'dan gelen veriyi Kullanici nesnesine çevirir
  factory Kullanici.fromFirestore(DocumentSnapshot doc) {
    // Firestore'dan gelen veriyi Map olarak al
    Map<String, dynamic> veri = doc.data() as Map<String, dynamic>;

    return Kullanici(
      id: doc.id,                                         // Firestore document ID
      ad: veri['ad'] ?? '',                               // Ad
      soyad: veri['soyad'] ?? '',                         // Soyad
      eposta: veri['eposta'] ?? '',                       // E-posta
      bolum: veri['bolum'] ?? '',                         // Bölüm
      rol: veri['rol'] ?? 'User',                         // Rol (varsayılan: User)
      kayitTarihi: (veri['kayitTarihi'] as Timestamp).toDate(), // Timestamp'i DateTime'a çevir
    );
  }

  /// Kullanıcı nesnesini Firestore'a kaydedilecek formata çevirir
  Map<String, dynamic> toJson() {
    return {
      'ad': ad,
      'soyad': soyad,
      'eposta': eposta,
      'bolum': bolum,
      'rol': rol,
      'kayitTarihi': Timestamp.fromDate(kayitTarihi),     // DateTime'ı Timestamp'e çevir
    };
  }

  /// Kullanıcının tam adını döndürür (Ad + Soyad)
  String get tamIsim => '$ad $soyad';

  /// Kullanıcının admin olup olmadığını kontrol eder
  bool get adminMi => rol == 'Admin';
}
