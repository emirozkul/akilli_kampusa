import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ihbar.dart';
import '../models/ihbar_durumu.dart';

/// Firebase Firestore ile ihbar verilerini yöneten servis sınıfı
/// Tüm Firebase işlemleri bu sınıf üzerinden yapılır
class IhbarServisi {
  
  // Firestore koleksiyon referansı
  // 'ihbarlar' koleksiyonuna erişim sağlar
  final CollectionReference _ihbarlarKoleksiyonu = 
      FirebaseFirestore.instance.collection('ihbarlar');

  /// Tüm ihbarları gerçek zamanlı olarak dinler
  /// Stream döndürür, böylece Firebase'de değişiklik olduğunda otomatik güncellenir
  /// 
  /// Kullanım:
  /// ```dart
  /// StreamBuilder<List<Ihbar>>(
  ///   stream: ihbarServisi.tumIhbarlariGetir(),
  ///   builder: (context, snapshot) { ... }
  /// )
  /// ```
  Stream<List<Ihbar>> tumIhbarlariGetir() {
    // snapshot() ile koleksiyondaki değişiklikleri dinle
    return _ihbarlarKoleksiyonu
        .orderBy('tarih', descending: true)  // Tarihe göre sırala (en yeni önce)
        .snapshots()                          // Stream olarak dinle
        .map((snapshot) {                     // Her veri değişiminde çalışır
          // Tüm dökümanları Ihbar nesnesine çevir
          return snapshot.docs.map((doc) {
            return Ihbar.fromFirestore(doc);
          }).toList();
        });
  }

  /// Yeni bir ihbar ekler
  /// 
  /// Parametreler:
  /// - ihbar: Eklenecek ihbar nesnesi
  /// 
  /// Döner: Eklenen ihbarın ID'si (Future<String>)
  Future<String> ihbarEkle(Ihbar ihbar) async {
    try {
      // Ihbar nesnesini JSON'a çevir ve Firestore'a ekle
      DocumentReference docRef = await _ihbarlarKoleksiyonu.add(ihbar.toJson());
      
      // Eklenen dökümanın ID'sini döndür
      return docRef.id;
    } catch (hata) {
      // Hata durumunda konsola yazdır ve tekrar fırlat
      print('İhbar eklenirken hata oluştu: $hata');
      rethrow;
    }
  }

  /// Belirli bir ID'ye sahip ihbarı getirir
  /// 
  /// Parametreler:
  /// - id: İhbar ID'si
  /// 
  /// Döner: İhbar nesnesi (Future<Ihbar?>)
  Future<Ihbar?> ihbarGetir(String id) async {
    try {
      // Belirtilen ID'ye sahip dökümanı getir
      DocumentSnapshot doc = await _ihbarlarKoleksiyonu.doc(id).get();
      
      // Döküman varsa Ihbar nesnesine çevir
      if (doc.exists) {
        return Ihbar.fromFirestore(doc);
      }
      return null;
    } catch (hata) {
      print('İhbar getirilirken hata oluştu: $hata');
      return null;
    }
  }

  /// Mevcut bir ihbarı günceller
  /// 
  /// Parametreler:
  /// - id: Güncellenecek ihbarın ID'si
  /// - veri: Güncellenecek alanlar (Map formatında)
  /// 
  /// Örnek kullanım:
  /// ```dart
  /// ihbarServisi.ihbarGuncelle('abc123', {
  ///   'durum': 'Cozuldu',
  ///   'aciklama': 'Problem çözüldü'
  /// });
  /// ```
  Future<void> ihbarGuncelle(String id, Map<String, dynamic> veri) async {
    try {
      // Belirtilen ID'ye sahip dökümanı güncelle
      await _ihbarlarKoleksiyonu.doc(id).update(veri);
    } catch (hata) {
      print('İhbar güncellenirken hata oluştu: $hata');
      rethrow;
    }
  }

  /// İhbarı siler
  /// 
  /// Parametreler:
  /// - id: Silinecek ihbarın ID'si
  Future<void> ihbarSil(String id) async {
    try {
      // Belirtilen ID'ye sahip dökümanı sil
      await _ihbarlarKoleksiyonu.doc(id).delete();
    } catch (hata) {
      print('İhbar silinirken hata oluştu: $hata');
      rethrow;
    }
  }

  /// Belirli bir tipe göre ihbarları getirir
  /// 
  /// Parametreler:
  /// - tip: Filtrelenecek ihbar tipi (örn: "Acil")
  /// 
  /// Döner: Filtrelenmiş ihbar listesi (Stream)
  Stream<List<Ihbar>> tipineGoreIhbarlariGetir(String tip) {
    return _ihbarlarKoleksiyonu
        .where('tip', isEqualTo: tip)         // Tipe göre filtrele
        .orderBy('tarih', descending: true)   // Tarihe göre sırala
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Ihbar.fromFirestore(doc);
          }).toList();
        });
  }

  /// Belirli bir duruma göre ihbarları getirir
  /// 
  /// Parametreler:
  /// - durum: Filtrelenecek ihbar durumu (örn: "Acik")
  /// 
  /// Döner: Filtrelenmiş ihbar listesi (Stream)
  Stream<List<Ihbar>> durumaGoreIhbarlariGetir(String durum) {
    return _ihbarlarKoleksiyonu
        .where('durum', isEqualTo: durum)     // Duruma göre filtrele
        .orderBy('tarih', descending: true)   // Tarihe göre sırala
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Ihbar.fromFirestore(doc);
          }).toList();
        });
  }
  /// İhbarı takip et
  /// Kullanıcıyı ihbarın takipçileri listesine ekler
  Future<void> ihbarTakipEt(String ihbarId, String userId) async {
    try {
      await _ihbarlarKoleksiyonu.doc(ihbarId).update({
        'takipEdenler': FieldValue.arrayUnion([userId])
      });
    } catch (hata) {
      print('İhbar takip edilirken hata oluştu: $hata');
      rethrow;
    }
  }

  /// İhbar takibini bırak
  /// Kullanıcıyı ihbarın takipçileri listesinden çıkarır
  Future<void> ihbarTakibiBirak(String ihbarId, String userId) async {
    try {
      await _ihbarlarKoleksiyonu.doc(ihbarId).update({
        'takipEdenler': FieldValue.arrayRemove([userId])
      });
    } catch (hata) {
      print('İhbar takibi bırakılırken hata oluştu: $hata');
      rethrow;
    }
  }



  /// İhbar durumunu günceller (Admin Paneli için)
  /// Durum değiştiğinde (gelecekte) bildirim gönderilmesini tetikler
  Future<void> durumGuncelle(String ihbarId, IhbarDurumu yeniDurum) async {
    try {
      await _ihbarlarKoleksiyonu.doc(ihbarId).update({
        'durum': yeniDurum.isim,
      });
      
      // TODO: Gerçek bir bildirim sistemi (Firebase Cloud Messaging) buraya entegre edilebilir.
      // Şimdilik sadece konsola yazıyoruz.
      print('İhbar ($ihbarId) durumu güncellendi: ${yeniDurum.isim}. Takipçilere bildirim gönderiliyor...');
      
    } catch (hata) {
      print('Durum güncellenirken hata oluştu: $hata');
      rethrow;
    }
  }
}
