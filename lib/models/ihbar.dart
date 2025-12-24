import 'package:cloud_firestore/cloud_firestore.dart';
import 'ihbar_tipi.dart';
import 'ihbar_durumu.dart';

/// İhbar modelini temsil eden sınıf
/// Kampüsteki bildirimleri saklar
class Ihbar {
  
  // İhbar özellikleri
  final String id;                // Firestore'daki benzersiz kimlik
  final String baslik;            // İhbar başlığı (kısa açıklama)
  final String aciklama;          // İhbar detaylı açıklaması
  final IhbarTipi tip;            // İhbar tipi (Acil, Arıza, vb.)
  final double enlem;             // Konum - Latitude (Enlem)
  final double boylam;            // Konum - Longitude (Boylam)
  final IhbarDurumu durum;        // İhbar durumu (Açık, İnceleniyor, Çözüldü)
  final String olusturanId;       // İhbarı oluşturan kullanıcının ID'si
  final DateTime tarih;           // İhbarın oluşturulma tarihi
  final List<String> takipEdenler; // İhbarı takip eden kullanıcıların ID listesi

  /// Constructor - Yeni bir ihbar nesnesi oluşturur
  Ihbar({
    required this.id,
    required this.baslik,
    required this.aciklama,
    required this.tip,
    required this.enlem,
    required this.boylam,
    required this.durum,
    required this.olusturanId,
    required this.tarih,
    this.takipEdenler = const [], // Varsayılan olarak boş liste
  });

  /// Firebase Firestore'dan gelen veriyi Ihbar nesnesine çevirir
  /// DocumentSnapshot'tan Ihbar objesi oluşturur
  factory Ihbar.fromFirestore(DocumentSnapshot doc) {
    // Firestore'dan gelen veriyi Map olarak al
    Map<String, dynamic> veri = doc.data() as Map<String, dynamic>;

    return Ihbar(
      id: doc.id,                                                    // Firestore document ID'si
      baslik: veri['baslik'] ?? '',                                  // Başlık (boşsa boş string)
      aciklama: veri['aciklama'] ?? '',                              // Açıklama
      tip: IhbarTipiExtension.fromString(veri['tip'] ?? 'Diger'),   // Tip (string'den enum'a)
      enlem: (veri['enlem'] ?? 0.0).toDouble(),                     // Enlem (double)
      boylam: (veri['boylam'] ?? 0.0).toDouble(),                   // Boylam (double)
      durum: IhbarDurumuExtension.fromString(veri['durum'] ?? 'Acik'), // Durum
      olusturanId: veri['olusturanId'] ?? '',                       // Oluşturan kullanıcı ID
      tarih: (veri['tarih'] as Timestamp).toDate(),                 // Timestamp'i DateTime'a çevir
      takipEdenler: List<String>.from(veri['takipEdenler'] ?? []),  // Takipçi listesini al
    );
  }

  /// Ihbar nesnesini Firebase'e kaydedilecek formata çevirir
  /// Map<String, dynamic> formatında döndürür
  Map<String, dynamic> toJson() {
    return {
      'baslik': baslik,
      'aciklama': aciklama,
      'tip': tip.isim,                              // Enum'u string'e çevir
      'enlem': enlem,
      'boylam': boylam,
      'durum': durum.name,                          // Enum'un adını kaydet (Acik, Cozuldu vs.)
      'olusturanId': olusturanId,
      'tarih': Timestamp.fromDate(tarih),           // DateTime'ı Timestamp'e çevir
      'takipEdenler': takipEdenler,                 // Takipçi listesini kaydet
    };
  }

  /// Ihbar nesnesinin kopyasını oluşturur
  /// Belirli alanları güncellemek için kullanılır
  Ihbar copyWith({
    String? id,
    String? baslik,
    String? aciklama,
    IhbarTipi? tip,
    double? enlem,
    double? boylam,
    IhbarDurumu? durum,
    String? olusturanId,
    DateTime? tarih,
    List<String>? takipEdenler,
  }) {
    return Ihbar(
      id: id ?? this.id,
      baslik: baslik ?? this.baslik,
      aciklama: aciklama ?? this.aciklama,
      tip: tip ?? this.tip,
      enlem: enlem ?? this.enlem,
      boylam: boylam ?? this.boylam,
      durum: durum ?? this.durum,
      olusturanId: olusturanId ?? this.olusturanId,
      tarih: tarih ?? this.tarih,
      takipEdenler: takipEdenler ?? this.takipEdenler,
    );
  }
}
