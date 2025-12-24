import 'package:flutter/material.dart';

/// İhbar tiplerini tanımlayan enum
/// Her ihbar tipi için farklı renk ve ikon kullanılır
enum IhbarTipi {
  Acil,       // Acil durumlar için (kırmızı)
  Ariza,      // Arıza bildirimleri için (turuncu)
  Kayip,      // Kayıp eşya bildirimleri için (mavi)
  Oneri,      // Öneri ve geri bildirimler için (yeşil)
  Diger       // Diğer bildirimler için (gri)
}

/// IhbarTipi enum'ı için yardımcı fonksiyonlar içeren extension
extension IhbarTipiExtension on IhbarTipi {
  
  /// İhbar tipinin Türkçe adını döndürür
  /// Kullanım: IhbarTipi.Acil.isim => "Acil"
  String get isim {
    switch (this) {
      case IhbarTipi.Acil:
        return 'Acil';
      case IhbarTipi.Ariza:
        return 'Arıza';
      case IhbarTipi.Kayip:
        return 'Kayıp';
      case IhbarTipi.Oneri:
        return 'Öneri';
      case IhbarTipi.Diger:
        return 'Diğer';
    }
  }

  /// İhbar tipine uygun rengi döndürür
  /// Haritada marker rengi olarak kullanılır
  Color get renk {
    switch (this) {
      case IhbarTipi.Acil:
        return Colors.red;        // Kırmızı - Acil durumlar
      case IhbarTipi.Ariza:
        return Colors.orange;     // Turuncu - Arızalar
      case IhbarTipi.Kayip:
        return Colors.blue;       // Mavi - Kayıp eşyalar
      case IhbarTipi.Oneri:
        return Colors.green;      // Yeşil - Öneriler
      case IhbarTipi.Diger:
        return Colors.grey;       // Gri - Diğer
    }
  }

  /// İhbar tipine uygun ikonu döndürür
  /// Marker üzerinde gösterilir
  IconData get ikon {
    switch (this) {
      case IhbarTipi.Acil:
        return Icons.error;           // Hata işareti - Acil
      case IhbarTipi.Ariza:
        return Icons.build;           // Tamir işareti - Arıza
      case IhbarTipi.Kayip:
        return Icons.search;          // Arama işareti - Kayıp
      case IhbarTipi.Oneri:
        return Icons.lightbulb;       // Ampul işareti - Öneri
      case IhbarTipi.Diger:
        return Icons.info;            // Bilgi işareti - Diğer
    }
  }

  /// String değerden IhbarTipi enum'ına dönüştürür
  /// Firebase'den gelen veriyi çevirmek için kullanılır
  static IhbarTipi fromString(String tip) {
    switch (tip) {
      case 'Acil':
        return IhbarTipi.Acil;
      case 'Ariza':
        return IhbarTipi.Ariza;
      case 'Kayip':
        return IhbarTipi.Kayip;
      case 'Oneri':
        return IhbarTipi.Oneri;
      case 'Diger':
      default:
        return IhbarTipi.Diger;
    }
  }
}
