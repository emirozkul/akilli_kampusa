import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kullanici.dart';
import '../helpers/hata_mesajlari.dart';

/// Firebase Authentication ve Firestore ile kullanıcı işlemlerini yöneten servis
/// Kayıt, giriş, çıkış ve şifre sıfırlama işlemlerini yapar
class AuthServisi {
  
  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Users koleksiyonu referansı
  final String _usersKoleksiyon = 'users';

  /// Şu anda giriş yapmış kullanıcıyı döndürür
  /// Kimse giriş yapmamışsa null döner
  User? get mevcutKullanici => _auth.currentUser;

  /// Aktif kullanıcının ID'sini döndürür
  String? get aktifKullaniciId => _auth.currentUser?.uid;

  /// Auth durumu değişikliklerini dinler
  /// Giriş/çıkış yapıldığında tetiklenir
  Stream<User?> get authDurumuDinle => _auth.authStateChanges();

  /// Yeni kullanıcı kaydı oluşturur
  /// 
  /// Parametreler:
  /// - ad: Kullanıcının adı
  /// - soyad: Kullanıcının soyadı
  /// - eposta: E-posta adresi
  /// - sifre: Şifre (en az 6 karakter)
  /// - bolum: Bölüm bilgisi
  /// 
  /// Başarılı olursa kullanıcı otomatik giriş yapmış olur
  /// Hata olursa Türkçe hata mesajıyla exception fırlatır
  Future<void> kayitOl({
    required String ad,
    required String soyad,
    required String eposta,
    required String sifre,
    required String bolum,
  }) async {
    try {
      // Firebase Auth ile kullanıcı oluştur
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: eposta,
        password: sifre,
      );

      // Kullanıcı ID'sini al
      String userId = userCredential.user!.uid;

      // Kullanıcı bilgilerini Firestore'a kaydet
      Kullanici yeniKullanici = Kullanici(
        id: userId,
        ad: ad,
        soyad: soyad,
        eposta: eposta,
        bolum: bolum,
        rol: 'User',                    // Varsayılan rol: User
        kayitTarihi: DateTime.now(),    // Şu anki zaman
      );

      // Firestore'a kaydet
      await _firestore
          .collection(_usersKoleksiyon)
          .doc(userId)
          .set(yeniKullanici.toJson());

      // Otomatik girişi engellemek için çıkış yap
      await _auth.signOut();

    } on FirebaseAuthException catch (e) {
      // Firebase hatasını Türkçe mesaja çevir ve fırlat
      throw HataMesajlari.getir(e.code);
    } catch (e) {
      // Genel hata
      throw 'Kayıt olurken bir hata oluştu: $e';
    }
  }

  /// Kullanıcı girişi yapar
  /// 
  /// Parametreler:
  /// - eposta: E-posta adresi
  /// - sifre: Şifre
  /// 
  /// Başarılı olursa kullanıcı giriş yapmış olur
  /// Hata olursa Türkçe hata mesajıyla exception fırlatır
  Future<void> girisYap({
    required String eposta,
    required String sifre,
  }) async {
    try {
      // Firebase Auth ile giriş yap
      await _auth.signInWithEmailAndPassword(
        email: eposta,
        password: sifre,
      );
    } on FirebaseAuthException catch (e) {
      // Firebase hatasını Türkçe mesaja çevir ve fırlat
      throw HataMesajlari.getir(e.code);
    } catch (e) {
      // Genel hata
      throw 'Giriş yaparken bir hata oluştu: $e';
    }
  }

  /// Kullanıcı çıkışı yapar
  Future<void> cikisYap() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Çıkış yaparken bir hata oluştu: $e';
    }
  }

  /// Şifre sıfırlama e-postası gönderir
  /// 
  /// Parametreler:
  /// - eposta: Şifresi sıfırlanacak e-posta adresi
  /// 
  /// Firebase otomatik olarak şifre sıfırlama linki gönderir
  Future<void> sifreSifirla(String eposta) async {
    try {
      await _auth.sendPasswordResetEmail(email: eposta);
    } on FirebaseAuthException catch (e) {
      // Firebase hatasını Türkçe mesaja çevir ve fırlat
      throw HataMesajlari.getir(e.code);
    } catch (e) {
      throw 'Şifre sıfırlama e-postası gönderilirken hata oluştu: $e';
    }
  }

  /// Firestore'dan kullanıcı bilgilerini getirir
  /// 
  /// Parametreler:
  /// - userId: Kullanıcı ID (Firebase Auth UID)
  /// 
  /// Döner: Kullanici nesnesi veya null
  Future<Kullanici?> kullaniciBilgileriniGetir(String userId) async {
    try {
      // Firestore'dan kullanıcı dokümanını getir
      DocumentSnapshot doc = await _firestore
          .collection(_usersKoleksiyon)
          .doc(userId)
          .get();

      // Döküman varsa Kullanici nesnesine çevir
      if (doc.exists) {
        return Kullanici.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Kullanıcı bilgileri getirilirken hata: $e');
      return null;
    }
  }

  /// Şu anki kullanıcının rolünü kontrol eder
  /// 
  /// Döner: 'Admin' veya 'User' veya null (giriş yapılmamışsa)
  Future<String?> kullaniciRolunuGetir() async {
    // Mevcut kullanıcı var mı kontrol et
    if (mevcutKullanici == null) {
      return null;
    }

    // Kullanıcı bilgilerini Firestore'dan getir
    Kullanici? kullanici = await kullaniciBilgileriniGetir(mevcutKullanici!.uid);
    
    // Rol bilgisini döndür
    return kullanici?.rol;
  }
}
