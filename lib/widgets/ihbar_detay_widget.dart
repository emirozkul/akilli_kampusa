import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ihbar.dart';
import '../models/ihbar_tipi.dart';
import '../models/ihbar_durumu.dart';

import '../services/ihbar_servisi.dart';
import '../services/auth_servisi.dart';

/// İhbar detaylarını gösteren widget
/// Bottom sheet içinde kullanılır
class IhbarDetayWidget extends StatefulWidget {
  
  // Gösterilecek ihbar
  final Ihbar ihbar;

  /// Constructor - İhbar nesnesini alır
  const IhbarDetayWidget({
    super.key,
    required this.ihbar,
  });

  @override
  State<IhbarDetayWidget> createState() => _IhbarDetayWidgetState();
}

class _IhbarDetayWidgetState extends State<IhbarDetayWidget> {
  // Servisler
  final IhbarServisi _ihbarServisi = IhbarServisi();
  final AuthServisi _authServisi = AuthServisi();
  
  // Takip durumu
  bool _takipEdiyor = false;
  String? _aktifKullaniciId;
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    _takipDurumunuKontrolEt();
  }

  // Başlangıçta takip durumunu kontrol et
  void _takipDurumunuKontrolEt() {
    _aktifKullaniciId = _authServisi.aktifKullaniciId;
    if (_aktifKullaniciId != null) {
      // Ihbar modelindeki takipçi listesinde var mı?
      setState(() {
        _takipEdiyor = widget.ihbar.takipEdenler.contains(_aktifKullaniciId);
      });
    }
  }

  // Takip et / Takibi bırak işlemi
  Future<void> _takipIslemi() async {
    if (_aktifKullaniciId == null) return;
    
    setState(() {
      _yukleniyor = true;
    });

    try {
      if (_takipEdiyor) {
        // Takibi bırak
        await _ihbarServisi.ihbarTakibiBirak(widget.ihbar.id, _aktifKullaniciId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İhbar takibi bırakıldı')),
          );
        }
      } else {
        // Takip et
        await _ihbarServisi.ihbarTakipEt(widget.ihbar.id, _aktifKullaniciId!);
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İhbar takip ediliyor')),
          );
        }
      }

      // UI güncelle
      if (mounted) {
        setState(() {
          _takipEdiyor = !_takipEdiyor;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Ihbar>(
      stream: _ihbarServisi.tekIhbarGetirStream(widget.ihbar.id),
      initialData: widget.ihbar, // İlk yüklemede mevcut veriyi kullan
      builder: (context, snapshot) {
        
        // Hata veya veri yoksa (silinmişse)
        if (snapshot.hasError || !snapshot.hasData) {
           return Container(
            padding: const EdgeInsets.all(20),
            child: const Text('Bu ihbar artık mevcut değil veya bir hata oluştu.'),
           );
        }

        final guncelIhbar = snapshot.data!;

        return Container(
          // Bottom sheet için padding ve dekorasyon
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            // İçeriği minimum boyutta tut
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst çubuk
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
    
              // Üst Satır: İhbar Tipi ve Takip Butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _tipRozetiniOlustur(guncelIhbar),
                  
                  // Takip Butonu
                  IconButton(
                    onPressed: _yukleniyor ? null : _takipIslemi,
                    icon: _yukleniyor 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2)
                        )
                      : Icon(
                          _takipEdiyor ? Icons.favorite : Icons.favorite_border,
                          color: _takipEdiyor ? Colors.red : Colors.grey,
                          size: 28,
                        ),
                    tooltip: _takipEdiyor ? 'Takibi Bırak' : 'Takip Et',
                  ),
                ],
              ),
              const SizedBox(height: 15),
    
              // Başlık
              Text(
                guncelIhbar.baslik,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
    
              // Durum
              _durumuGoster(guncelIhbar),
              const SizedBox(height: 15),
    
              // Açıklama
              Text(
                guncelIhbar.aciklama,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),
    
              // Tarih bilgisi
              _tarihBilgisiniGoster(guncelIhbar),
              const SizedBox(height: 10),
    
              // Konum bilgisi
              _konumBilgisiniGoster(guncelIhbar),
              
              const SizedBox(height: 10),
              // Takipçilere özel bilgi notu
              if (_takipEdiyor)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.notifications_active, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bu ihbarı takip ediyorsunuz. Durum değiştiğinde bildirim alacaksınız.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      }
    );
  }

  /// İhbar tipi rozetini oluşturur
  /// Renkli bir container içinde tip adı ve ikonu gösterir
  Widget _tipRozetiniOlustur(Ihbar ihbar) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ihbar.tip.renk.withOpacity(0.2),  // Açık renkli arka plan
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ihbar.tip.renk,                   // Koyu renkli kenarlık
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ihbar.tip.ikon,
            size: 18,
            color: ihbar.tip.renk,
          ),
          const SizedBox(width: 6),
          Text(
            ihbar.tip.isim,
            style: TextStyle(
              color: ihbar.tip.renk,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// İhbar durumunu gösterir
  /// Durum bilgisini renkli bir satırda gösterir
  Widget _durumuGoster(Ihbar ihbar) {
    // Duruma göre renk seç
    Color durumRengi;
    switch (ihbar.durum.name) {
      case 'Acik':
        durumRengi = Colors.orange;
        break;
      case 'Inceleniyor':
        durumRengi = Colors.blue;
        break;
      case 'Cozuldu':
        durumRengi = Colors.green;
        break;
      default:
        durumRengi = Colors.grey;
    }

    return Row(
      children: [
        // Durum göstergesi (daire)
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: durumRengi,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Durum: ${ihbar.durum.isim}',
          style: TextStyle(
            fontSize: 14,
            color: durumRengi,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Tarih bilgisini kullanıcı dostu formatta gösterir
  /// Örnek: "24 Aralık 2025 - 15:30"
  Widget _tarihBilgisiniGoster(Ihbar ihbar) {
    // Tarih formatını oluştur (Türkçe)
    final tarihFormati = DateFormat('dd MMMM yyyy - HH:mm', 'tr_TR');
    final tarihMetni = tarihFormati.format(ihbar.tarih);

    return Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          tarihMetni,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Konum bilgisini gösterir
  /// Enlem ve boylam değerlerini gösterir
  Widget _konumBilgisiniGoster(Ihbar ihbar) {
    return Row(
      children: [
        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          'Konum: ${ihbar.enlem.toStringAsFixed(4)}, ${ihbar.boylam.toStringAsFixed(4)}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
} // Class sonu

