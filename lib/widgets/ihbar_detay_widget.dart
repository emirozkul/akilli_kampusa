import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ihbar.dart';
import '../models/ihbar_tipi.dart';
import '../models/ihbar_durumu.dart';

import '../services/ihbar_servisi.dart';
import '../services/auth_servisi.dart';
import '../screens/ihbar_detay_sayfasi.dart';

/// İhbar detaylarını gösteren widget
/// Bottom sheet içinde kullanılır
class IhbarDetayWidget extends StatefulWidget {
  
  // Gösterilecek ihbar
  final Ihbar ihbar;
  // Tam ekran modunda mı açıldı? (Bottom sheet değilse butonu gizle)
  final bool fullscreen;

  /// Constructor - İhbar nesnesini alır
  const IhbarDetayWidget({
    super.key,
    required this.ihbar,
    this.fullscreen = false,
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
  bool _isAdmin = false;
  String? _aktifKullaniciId;
  bool _yukleniyor = false;
  
  // Düzenleme modu state'i
  bool _duzenlemeModu = false;
  late TextEditingController _baslikController;
  late TextEditingController _aciklamaController;
  
  // Resim Gösterimi
  int _aktifResimIndex = 0;

  @override
  void initState() {
    super.initState();
    _baslikController = TextEditingController(text: widget.ihbar.baslik);
    _aciklamaController = TextEditingController(text: widget.ihbar.aciklama);
    _baslangicKontrolleri();
  }

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  // Başlangıçta takip durumu ve yetkiyi kontrol et
  Future<void> _baslangicKontrolleri() async {
    _aktifKullaniciId = _authServisi.aktifKullaniciId;
    
    // Admin kontrolü
    String? rol = await _authServisi.kullaniciRolunuGetir();
    
    if (mounted) {
      setState(() {
        // Rol kontrolünü büyük/küçük harf duyarsız yap
        _isAdmin = rol?.toLowerCase() == 'admin';
        if (_aktifKullaniciId != null) {
           _takipEdiyor = widget.ihbar.takipEdenler.contains(_aktifKullaniciId);
        }
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

  // Değişiklikleri Kaydet
  Future<void> _degisiklikleriKaydet() async {
    setState(() {
      _yukleniyor = true;
    });

    try {
      await _ihbarServisi.ihbarGuncelle(widget.ihbar.id, {
        'baslik': _baslikController.text.trim(),
        'aciklama': _aciklamaController.text.trim(),
      });

      if (mounted) {
        setState(() {
          _duzenlemeModu = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İhbar güncellendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme hatası: $e')),
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
    
              // Üst Satır: İhbar Tipi ve Aksiyonlar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _tipRozetiniOlustur(guncelIhbar),
                  
                  // Sağ Taraf Butonları (Admin Düzenle + Takip)
                  Row(
                    children: [
                      // Admin için Düzenleme Modu Butonu
                      if (_isAdmin)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _duzenlemeModu ? Colors.blue.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _duzenlemeModu ? Icons.save : Icons.edit,
                              color: Colors.blue,
                            ),
                            tooltip: _duzenlemeModu ? 'Kaydet' : 'Düzenle',
                            onPressed: _duzenlemeModu ? _degisiklikleriKaydet : () {
                              setState(() {
                                _duzenlemeModu = true;
                                _baslikController.text = guncelIhbar.baslik;
                                _aciklamaController.text = guncelIhbar.aciklama;
                              });
                            },
                          ),
                        ),

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
                ],
              ),
              const SizedBox(height: 15),

              const SizedBox(height: 15),

              // İhbar Resimleri (Carousel)
              if (guncelIhbar.resimUrlleri.isNotEmpty)
                Column(
                  children: [
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        itemCount: guncelIhbar.resimUrlleri.length,
                        onPageChanged: (index) {
                          setState(() {
                            _aktifResimIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _galeriyiAc(context, guncelIhbar.resimUrlleri, index);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(guncelIhbar.resimUrlleri[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Nokta Göstergeleri (Sadece birden fazla resim varsa)
                    if (guncelIhbar.resimUrlleri.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(guncelIhbar.resimUrlleri.length, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _aktifResimIndex == index 
                                    ? Colors.blue 
                                    : Colors.grey[300],
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
    
              // Başlık Alanı (Düzenleme Moduna Göre Değişir)
              if (_duzenlemeModu)
                TextFormField(
                  controller: _baslikController,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'İhbar Başlığı',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                )
              else
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
    
              // Açıklama Alanı (Düzenleme Moduna Göre Değişir)
              if (_duzenlemeModu)
                TextFormField(
                  controller: _aciklamaController,
                  maxLines: 4,
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  decoration: const InputDecoration(
                    labelText: 'Detaylı Açıklama',
                    border: OutlineInputBorder(),
                  ),
                )
              else
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
              
              // Eğer tam ekran değilse (Bottom Sheet ise) Detay Butonunu göster
              if (!widget.fullscreen) ...[
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Detay sayfasına git
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IhbarDetaySayfasi(ihbar: guncelIhbar),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Detayı Gör'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
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

  /// Tam Ekran Galeri
  void _galeriyiAc(BuildContext context, List<String> resimler, int baslangicIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Resimler (PageView)
             SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: PageView.builder(
                controller: PageController(initialPage: baslangicIndex),
                itemCount: resimler.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer( // Zoom için
                    child: Image.network(
                      resimler[index],
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),
            
            // Kapat Butonu
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
} // Class sonu

