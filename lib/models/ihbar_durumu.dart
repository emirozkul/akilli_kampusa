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
        return IhbarDurumu.Acik;
      case 'Inceleniyor':
        return IhbarDurumu.Inceleniyor;
      case 'Cozuldu':
        return IhbarDurumu.Cozuldu;
      default:
        return IhbarDurumu.Acik;  // Varsayılan olarak Açık
    }
  }
}
