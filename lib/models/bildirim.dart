import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcılara gösterilecek bildirimleri temsil eden model
class Bildirim {
  final String id;
  final String baslik;
  final String mesaj;
  final String ihbarId; // İlgili ihbarın ID'si
  final DateTime tarih;
  final bool okunduMu;

  Bildirim({
    required this.id,
    required this.baslik,
    required this.mesaj,
    required this.ihbarId,
    required this.tarih,
    this.okunduMu = false,
  });

  /// Firestore'dan gelen veriyi modele çevirir
  factory Bildirim.fromFirestore(DocumentSnapshot doc) {
    final veriler = doc.data() as Map<String, dynamic>;
    return Bildirim(
      id: doc.id,
      baslik: veriler['baslik'] ?? '',
      mesaj: veriler['mesaj'] ?? '',
      ihbarId: veriler['ihbarId'] ?? '',
      tarih: (veriler['tarih'] as Timestamp).toDate(),
      okunduMu: veriler['okunduMu'] ?? false,
    );
  }

  /// Modeli Firestore'a kaydetmek için Map'e çevirir
  Map<String, dynamic> toJson() {
    return {
      'baslik': baslik,
      'mesaj': mesaj,
      'ihbarId': ihbarId,
      'tarih': Timestamp.fromDate(tarih),
      'okunduMu': okunduMu,
    };
  }
}
