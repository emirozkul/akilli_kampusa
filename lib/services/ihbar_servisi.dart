import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ihbar.dart';
import '../models/ihbar_durumu.dart';
import '../models/ihbar_durumu.dart';
import '../models/bildirim.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

/// Firebase Firestore ile ihbar verilerini yöneten servis sınıfı
/// Tüm Firebase işlemleri bu sınıf üzerinden yapılır
class IhbarServisi {
  
  // Firestore koleksiyon referansı
  // 'ihbarlar' koleksiyonuna erişim sağlar
  final CollectionReference _ihbarlarKoleksiyonu = 
      FirebaseFirestore.instance.collection('ihbarlar');
  
  // Storage referansı
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Resmi Storage'a yükler ve URL'ini döndürür
  Future<String> resimYukle(File resimDosyasi) async {
    try {
      // Benzersiz bir dosya adı oluştur
      String dosyaAdi = DateTime.now().millisecondsSinceEpoch.toString();
      // Basit bir path kullanalım (klasör olmadan) hatayı izole etmek için
      // veya klasör kullanılacaksa kuralların buna izin verdiğinden emin olunmalı
      Reference ref = _storage.ref().child('ihbar_resimleri').child('$dosyaAdi.jpg');
      
      // Metadata
      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      // putFile kullan (Standart yöntem)
      // await uploadTask diyerek sonucunu bekliyoruz
      UploadTask uploadTask = ref.putFile(resimDosyasi, metadata);

      // Hata dinleyicileri ekleyebiliriz ama await yeterli olmalı
      TaskSnapshot snapshot = await uploadTask.catchError((e) {
         throw e;
      });
      
      if (snapshot.state == TaskState.success) {
        String url = await snapshot.ref.getDownloadURL();
        return url;
      } else {
        throw 'Yükleme tamamlanmadı: ${snapshot.state}';
      }
    } on FirebaseException catch (e) {
      print('Firebase Storage Hatası: ${e.code} - ${e.message}');
      if (e.code == 'object-not-found') {
        throw 'Dosya yüklenemedi. Lütfen Firebase Storage "Rules" sekmesinden yazma izniniz olduğundan emin olun (allow write: if request.auth != null;).';
      } else if (e.code == 'unauthorized') {
        throw 'Yetkisiz erişim. Lütfen oturum açtığınızdan emin olun.';
      }
      throw 'Yükleme hatası: ${e.message}';
    } catch (e) {
      print('Genel Hata: $e');
      throw 'Bir hata oluştu: $e';
    }
  }

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
      // Önce mevcut ihbarı getir (Bildirim için takipçileri bulmamız lazım)
      DocumentSnapshot ihbarDoc = await _ihbarlarKoleksiyonu.doc(id).get();
      if (!ihbarDoc.exists) return;

      Ihbar eskiIhbar = Ihbar.fromFirestore(ihbarDoc);
      
      // Güncellemeyi yap
      await _ihbarlarKoleksiyonu.doc(id).update(veri);
      
      // Bildirim kontrolü (Başlık veya Tarih değiştiyse)
      bool bildirimGonder = false;
      String bildirimMesaji = '';
      
      if (veri.containsKey('baslik') && veri['baslik'] != eskiIhbar.baslik) {
        bildirimGonder = true;
        bildirimMesaji = '"${eskiIhbar.baslik}" başlıklı ihbarın başlığı değişti.';
      } else if (veri.containsKey('tarih')) {
        // Tarih değişimi (Nadir olur ama istendi)
        bildirimGonder = true;
        bildirimMesaji = '"${eskiIhbar.baslik}" başlıklı ihbarın tarihi güncellendi.';
      }
      
      // Bildirim gönder
      if (bildirimGonder) {
        Set<String> bildirimGidecekler = eskiIhbar.takipEdenler.toSet();
        if (eskiIhbar.olusturanId.isNotEmpty) {
          bildirimGidecekler.add(eskiIhbar.olusturanId);
        }

        // İşlemi yapan kişiye (kendisine) bildirim gönderme
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          bildirimGidecekler.remove(currentUserId);
        }
        
        WriteBatch batch = FirebaseFirestore.instance.batch();
        
        for (String userId in bildirimGidecekler) {
          DocumentReference bildirimRef = FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('bildirimler')
              .doc();

          Bildirim yeniBildirim = Bildirim(
            id: bildirimRef.id,
            baslik: 'İhbar Güncellendi',
            mesaj: bildirimMesaji,
            ihbarId: id,
            tarih: DateTime.now(),
          );

          batch.set(bildirimRef, yeniBildirim.toJson());
        }
        
        if (bildirimGidecekler.isNotEmpty) {
          await batch.commit();
        }
      }

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
      // 1. İhbar durumunu güncelle (Kod adını kaydet: Cozuldu vs.)
      await _ihbarlarKoleksiyonu.doc(ihbarId).update({
        'durum': yeniDurum.name,
      });

      // 2. İhbarı getir (Takipçileri bulmak için)
      DocumentSnapshot ihbarDoc = await _ihbarlarKoleksiyonu.doc(ihbarId).get();
      if (!ihbarDoc.exists) return;

      Ihbar ihbar = Ihbar.fromFirestore(ihbarDoc);
      // Takipçiler listesini al
      Set<String> bildirimGidecekler = ihbar.takipEdenler.toSet();
      
      // Oluşturan kişiyi de listeye ekle (eğer takip etmiyorsa bile)
      if (ihbar.olusturanId.isNotEmpty) {
        bildirimGidecekler.add(ihbar.olusturanId);
      }

      // İşlemi yapan kişiye (kendisine) bildirim gönderme
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        bildirimGidecekler.remove(currentUserId);
      }

      // 3. Takipçilere ve oluşturana bildirim oluştur
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      print('Bildirim gönderilecek kullanıcılar: $bildirimGidecekler'); // DEBUG

      for (String userId in bildirimGidecekler) {
        DocumentReference bildirimRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('bildirimler')
            .doc();

        Bildirim yeniBildirim = Bildirim(
          id: bildirimRef.id,
          baslik: 'İhbar Durumu Güncellendi',
          mesaj: '"${ihbar.baslik}" başlıklı ihbarın durumu "${yeniDurum.isim}" olarak güncellendi.',
          ihbarId: ihbarId,
          tarih: DateTime.now(),
        );

        batch.set(bildirimRef, yeniBildirim.toJson());
      }

      // Toplu yazma işlemini gerçekleştir
      if (bildirimGidecekler.isNotEmpty) {
        await batch.commit();
        print('${bildirimGidecekler.length} kullanıcıya bildirim gönderildi.');
      } else {
        print('Bildirim gönderilecek kimse yok.');
      }
      
    } catch (hata) {
      print('Durum güncellenirken hata oluştu: $hata');
      rethrow;
    }
  }
  /// Tüm kullanıcılara bildirim gönderir (Acil Durum Yayını)
  /// [gonderenId] parametresi ile göndericinin kendisine bildirim gitmesi engellenir
  Future<void> tumKullanicilaraBildirimGonder({required String baslik, required String mesaj, String? gonderenId}) async {
    try {
      // 1. Tüm kullanıcıları getir
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      
      // 2. Batch (toplu işlem) oluştur
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      int sayac = 0;
      
      for (DocumentSnapshot doc in usersSnapshot.docs) {
        String userId = doc.id;
        
        // Gönderen kişiye (kendisine) bildirim gönderme
        // Mevcut oturum açmış kullanıcı ID'si ile eşleşiyorsa atla
        // (AuthServisi'ne buradan erişemiyorsak parametre olarak alabiliriz ama
        //  basitlik adına şimdilik import etmeden AuthServisi burada kullanılmıyor.
        //  Ancak main.dart'ta AuthServisi kullanılıyor. 
        //  Burada FirebaseAuth.instance direkt kullanılabilir veya parametre eklenebilir.
        //  Parametre eklemek en temizi.)
        // Parametre eklenmediği için burada basitçe bir kontrol yapamayız, 
        // ancak metod imzasını değiştirelim.

        
        if (gonderenId != null && userId == gonderenId) {
          continue;
        }
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

