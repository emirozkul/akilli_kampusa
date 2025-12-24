/// İhbar durumlarını tanımlayan enum
/// Bir ihbarın işlenme aşamasını gösterir
enum IhbarDurumu {
  Acik,         // Yeni oluşturulmuş, henüz incelenmemiş
  Inceleniyor,  // İnceleme aşamasında
  Cozuldu       // Çözülmüş, tamamlanmış
}

/// IhbarDurumu enum'ı için yardımcı fonksiyonlar içeren extension
extension IhbarDurumuExtension on IhbarDurumu {
  
  /// İhbar durumunun Türkçe adını döndürür
  /// Kullanım: IhbarDurumu.Acik.isim => "Açık"
  String get isim {
    switch (this) {
      case IhbarDurumu.Acik:
        return 'Açık';
      case IhbarDurumu.Inceleniyor:
        return 'İnceleniyor';
      case IhbarDurumu.Cozuldu:
        return 'Çözüldü';
    }
  }

  /// String değerden IhbarDurumu enum'ına dönüştürür
  /// Firebase'den gelen veriyi çevirmek için kullanılır
  static IhbarDurumu fromString(String durum) {
    switch (durum) {
      case 'Acik':
      case 'Açık': // Eski/Görünen isim desteği
        return IhbarDurumu.Acik;
      case 'Inceleniyor':
      case 'İnceleniyor':
        return IhbarDurumu.Inceleniyor;
      case 'Cozuldu':
      case 'Çözüldü':
        return IhbarDurumu.Cozuldu;
      default:
        return IhbarDurumu.Acik;  // Varsayılan olarak Açık
    }
  }
}
