import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ihbar.dart';
import '../models/ihbar_durumu.dart';
import '../models/bildirim.dart';

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

  /// Belirli bir ID'ye sahip ihbarı Stream olarak getirir
  /// 
  /// Parametreler:
  /// - id: İhbar ID'si
  /// 
  /// Döner: İhbar nesnesi (Stream<Ihbar>)
  Stream<Ihbar> tekIhbarGetirStream(String id) {
    return _ihbarlarKoleksiyonu.doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return Ihbar.fromFirestore(doc);
      }
      // Doküman silindiyse veya bulunamazsa hata fırlatılabilir veya dummy dönebilir
      // Burada boş kontrolü yapılması gerekebilir
      throw Exception('İhbar bulunamadı');
    });
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

  /// Kullanıcının takip ettiği ihbarları getirir
  /// 'takipEdenler' dizisinde ilgili userId'yi arar
  Stream<List<Ihbar>> takipEdilenleriGetir(String userId) {
    return _ihbarlarKoleksiyonu
        .where('takipEdenler', arrayContains: userId) // userId takipçiler listesinde var mı?
        .orderBy('tarih', descending: true)
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



  /// Kullanıcının bildirimlerini getirir (Tarihe göre sıralı)
  Stream<List<Bildirim>> bildirimleriGetir(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bildirimler')
        .orderBy('tarih', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Bildirim.fromFirestore(doc);
      }).toList();
    });
  }

  /// İhbar durumunu günceller (Admin Paneli için)
  /// Durum değiştiğinde (gelecekte) bildirim gönderilmesini tetikler
  Future<void> durumGuncelle(String ihbarId, IhbarDurumu yeniDurum) async {
    try {
      // 1. İhbar durumunu güncelle
      await _ihbarlarKoleksiyonu.doc(ihbarId).update({
        'durum': yeniDurum.isim,
      });

      // 2. İhbarı getir (Takipçileri bulmak için)
      DocumentSnapshot ihbarDoc = await _ihbarlarKoleksiyonu.doc(ihbarId).get();
      if (!ihbarDoc.exists) return;

      Ihbar ihbar = Ihbar.fromFirestore(ihbarDoc);
      List<String> takipciler = ihbar.takipEdenler;

      // 3. Takipçilere bildirim oluştur
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String userId in takipciler) {
        DocumentReference bildirimRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('bildirimler')
            .doc();

        Bildirim yeniBildirim = Bildirim(
          id: bildirimRef.id,
          baslik: 'İhbar Durumu Güncellendi',
          mesaj: '"${ihbar.baslik}" başlıklı ihbarınızın durumu "${yeniDurum.isim}" olarak güncellendi.',
          ihbarId: ihbarId,
          tarih: DateTime.now(),
        );

        batch.set(bildirimRef, yeniBildirim.toJson());
      }

      // Toplu yazma işlemini gerçekleştir
      if (takipciler.isNotEmpty) {
        await batch.commit();
        print('${takipciler.length} kullanıcıya bildirim gönderildi.');
      }
      
    } catch (hata) {
      print('Durum güncellenirken hata oluştu: $hata');
      rethrow;
    }
  }
  /// Tüm kullanıcılara bildirim gönderir (Acil Durum Yayını)
  Future<void> tumKullanicilaraBildirimGonder({required String baslik, required String mesaj}) async {
    try {
      // 1. Tüm kullanıcıları getir
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      
      // 2. Batch (toplu işlem) oluştur
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      int sayac = 0;
      
      for (DocumentSnapshot doc in usersSnapshot.docs) {
        String userId = doc.id;
        
        // Bildirim referansı
        DocumentReference bildirimRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('bildirimler')
            .doc();

        // Bildirim nesnesi
        Bildirim yeniBildirim = Bildirim(
          id: bildirimRef.id,
          baslik: baslik,
          mesaj: mesaj,
          ihbarId: 'ACIL_DURUM', // Özel ID
          tarih: DateTime.now(),
        );

        // Batch'e ekle
        batch.set(bildirimRef, yeniBildirim.toJson());
        
        sayac++;
        
        // Firestore batch limiti (her 500 işlemde bir commit gerekir)
        if (sayac % 450 == 0) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
        }
      }

      // Kalanları gönder
      if (sayac > 0) {
        await batch.commit();
      }
      
      print('$sayac kullanıcıya acil durum bildirimi gönderildi.');
      
    } catch (hata) {
      print('Acil durum bildirimi gönderilirken hata: $hata');
      rethrow;
    }
  }
}

