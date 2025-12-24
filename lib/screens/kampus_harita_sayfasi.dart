import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/ihbar.dart';
import '../models/ihbar_tipi.dart';
import '../services/ihbar_servisi.dart';
import '../services/auth_servisi.dart';
import '../widgets/ihbar_detay_widget.dart';
import 'ihbar_ekle_sayfasi.dart';
import 'ayarlar_sayfasi.dart';
import 'takip_ettiklerim_sayfasi.dart';

import '../models/kullanici.dart'; // Kullanıcı modeli eklendi
import '../models/bildirim.dart'; // Bildirim modeli eklendi
import '../models/ihbar_durumu.dart'; // İhbar Durumu eklendi

/// Kampüs haritasını ve ihbarları gösteren ana sayfa
class KampusHaritaSayfasi extends StatefulWidget {
  const KampusHaritaSayfasi({super.key});

  @override
  State<KampusHaritaSayfasi> createState() => _KampusHaritaSayfasiState();
}

class _KampusHaritaSayfasiState extends State<KampusHaritaSayfasi> {
  
  // İhbar servisi nesnesi
  final IhbarServisi _ihbarServisi = IhbarServisi();
  final AuthServisi _authServisi = AuthServisi(); // Auth servisi instance

  // Harita kontrolcüsü (haritayı programatik olarak kontrol etmek için)
  final MapController _haritaKontrolcu = MapController();

  // Kampüs başlangıç konumu (Örnek: Ankara koordinatları)
  // NOT: Gerçek kampüs koordinatlarınızı buraya yazabilirsiniz
  final LatLng _kampusMerkezi = const LatLng(39.9, 32.85);

  // Başlangıç zoom seviyesi
  final double _baslangicZoom = 15.0;

  // Kullanıcı adını başlığa taşımak için state içinde tutalım
  String? _kullaniciAdi;
  
  // Kullanıcı bilgisini getiren Future
  late Future<Kullanici?> _kullaniciGetir;

  @override
  void initState() {
    super.initState();
    // Kullanıcı bilgisini getir
    _kullaniciGetir = _authServisi.kullaniciBilgileriniGetir(_authServisi.aktifKullaniciId!);
    
    // Kullanıcı adını ayrıca alıp başlığı güncellemek için
    _kullaniciGetir.then((kullanici) {
      if (kullanici != null && mounted) {
        setState(() {
          _kullaniciAdi = kullanici.ad;
        });
      }

    });

    // Bildirimleri dinle
    _bildirimleriDinle();
  }

  /// Kullanıcının bildirimlerini dinler ve SnackBar gösterir
  void _bildirimleriDinle() {
    final userId = _authServisi.aktifKullaniciId;
    if (userId != null) {
      _ihbarServisi.bildirimleriGetir(userId).listen((bildirimler) {
        // Son gelen bildirimi kontrol et (basit bir mantıkla)
        // Gerçek uygulamada okundu bilgisi veya zaman damgası kontrolü yapılmalı
        // Şimdilik sadece liste boş değilse ve son bildirim yeni ise gösterelim
        if (bildirimler.isNotEmpty && mounted) {
          final sonBildirim = bildirimler.first;
          
          // Debug için yazdıralım
          print('Son bildirim: ${sonBildirim.mesaj}, Zaman farkı: ${DateTime.now().difference(sonBildirim.tarih).inSeconds}');

          // Acil durumsa veya çok yeniyse göster
          // Acil durumlar için süre sınırını daha esnek tut (3 dakika)
          // Normal bildirimler için 30 saniye
          int sinirSaniye = sonBildirim.ihbarId == 'ACIL_DURUM' ? 180 : 30;
          
          if (DateTime.now().difference(sonBildirim.tarih).inSeconds < sinirSaniye) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    if (sonBildirim.ihbarId == 'ACIL_DURUM')
                      const Icon(Icons.warning, color: Colors.white)
                    else 
                      const Icon(Icons.notifications, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(child: Text(sonBildirim.mesaj)),
                  ],
                ),
                backgroundColor: sonBildirim.ihbarId == 'ACIL_DURUM' ? Colors.red : Colors.green,
                duration: Duration(seconds: sonBildirim.ihbarId == 'ACIL_DURUM' ? 10 : 4), // Acil durum daha uzun kalsın
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Tamam',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        }
      });
    }
  }

  // Arama işlemleri için kontrolcü ve değişken
  final TextEditingController _aramaKontrolcusu = TextEditingController();
  String _aramaMetni = '';

  @override
  void dispose() {
    // Controller'ı temizle
    _aramaKontrolcusu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Üst başlık çubuğu
      appBar: AppBar(
        title: Text(_kullaniciAdi != null ? 'Merhaba, $_kullaniciAdi 👋' : 'Kampüs Haritası'),
        // Renkler temadan gelecek
      ),

      // Yan Menü (Drawer)
      drawer: Drawer(
        child: FutureBuilder<Kullanici?>(
          future: _kullaniciGetir,
          builder: (context, snapshot) {
            String adSoyad = 'Yükleniyor...';
            String eposta = '';
            String bolum = '';
            String avatarHarf = '?';

            if (snapshot.hasData && snapshot.data != null) {
              final kullanici = snapshot.data!;
              adSoyad = kullanici.tamIsim;
              eposta = kullanici.eposta;
              bolum = kullanici.bolum;
              avatarHarf = kullanici.ad.isNotEmpty ? kullanici.ad[0].toUpperCase() : '?';
            }

            return Column(
              children: [
                // Profil Başlığı - Özelleştirilmiş Tasarım (Çakışmayı önlemek için)
                Container(
                  color: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          avatarHarf,
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold, 
                            color: Theme.of(context).primaryColor
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // İsim ve E-posta
                      Text(
                        adSoyad,
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eposta,
                        style: const TextStyle(
                          fontSize: 14, 
                          color: Colors.white70
                        ),
                      ),
                      if (bolum.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          bolum,
                          style: const TextStyle(
                            fontSize: 12, 
                            color: Colors.white60,
                            fontStyle: FontStyle.italic
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Menü Öğeleri
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Harita'),
                  onTap: () {
                    Navigator.pop(context); // Menüyü kapat
                  },
                ),
                
                // Takip Ettiklerim
                ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: const Text('Takip Ettiklerim'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TakipEttiklerimSayfasi()),
                    );
                  },
                ),

                // Ayarlar
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Ayarlar'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AyarlarSayfasi()),
                    );
                  },
                ),
                // Buraya "İhbarlarım" gibi yeni menüler eklenebilir

                const Divider(),

                // Çıkış Yap
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    // Çıkış yap
                    await _authServisi.cikisYap();
                    // Giriş ekranına yönlendirilecek (main.dart otomatik yapacak)
                  },
                ),
              ],
            );
          },
        ),
      ),

      // Ana içerik: Arama Barı ve Harita
      body: Column(
        children: [
          // Arama Çubuğu (Harita üzerinde sabit)
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: TextField(
              controller: _aramaKontrolcusu,
              decoration: InputDecoration(
                hintText: 'Haritada ihbar ara...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onChanged: (deger) {
                setState(() {
                  _aramaMetni = deger.toLowerCase();
                });
              },
            ),
          ),
          // Genişleyen Harita Alanı
          Expanded(
            child: StreamBuilder<List<Ihbar>>(
              // Firebase'den gerçek zamanlı ihbar verilerini dinle
              stream: _ihbarServisi.tumIhbarlariGetir(),
              builder: (context, snapshot) {
                // Veri yüklenirken loading göster
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Hata varsa göster
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 10),
                        Text(
                          'Hata: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Veri yoksa boş liste kullan
                final tumIhbarlar = snapshot.data ?? [];

                // Arama Filtresi Uygula
                final filtrelenmisIhbarlar = tumIhbarlar.where((ihbar) {
                  // Eğer arama metni boşsa hepsini göster
                  if (_aramaMetni.isEmpty) return true;
                  
                  // Başlık veya açıklamada ara
                  return ihbar.baslik.toLowerCase().contains(_aramaMetni) || 
                         ihbar.aciklama.toLowerCase().contains(_aramaMetni);
                }).toList();

                // İhbarlardan marker listesi oluştur
                final markerlar = _markerlariOlustur(filtrelenmisIhbarlar);

                // Harita widget'ını döndür
                return FlutterMap(
                  mapController: _haritaKontrolcu,
                  options: MapOptions(
                    // Başlangıç konumu ve zoom
                    initialCenter: _kampusMerkezi,
                    initialZoom: _baslangicZoom,
                    
                    // Minimum ve maksimum zoom seviyeleri
                    minZoom: 10.0,
                    maxZoom: 18.0,

                    // Harita sınırları (isteğe bağlı)
                    // Kampüs dışına çıkılmasını engellemek için kullanılabilir
                  ),
                  children: [
                    // OpenStreetMap tile layer'ı
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.akilli_kampusa',
                      
                      // Maksimum zoom seviyesi
                      maxZoom: 19,
                    ),

                    // Marker layer'ı (İhbar işaretleyicileri)
                    MarkerLayer(
                      markers: markerlar,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      
      // Yeni İhbar Ekleme Butonu
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // İhbar ekleme sayfasına git
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const IhbarEkleSayfasi(
                // Varsayılan olarak kampüs merkezini gönderiyoruz
                // İleride kullanıcının o anki konumu da olabilir
                baslangicKonumu: LatLng(39.9, 32.85),
              ),
            ),
          );
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add_location_alt, color: Colors.white),
        tooltip: 'İhbar Et',
      ),

      // Alt kısımda ihbar sayısını gösteren bilgi çubuğu
      bottomNavigationBar: StreamBuilder<List<Ihbar>>(
        stream: _ihbarServisi.tumIhbarlariGetir(),
        builder: (context, snapshot) {
          final ihbarSayisi = snapshot.data?.length ?? 0;
          
          return Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Toplam $ihbarSayisi ihbar gösteriliyor',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// İhbar listesinden marker listesi oluşturur
  /// Her ihbar için haritada bir marker oluşturulur
  List<Marker> _markerlariOlustur(List<Ihbar> ihbarlar) {
    return ihbarlar.map((ihbar) {
      return Marker(
        // Marker konumu (ihbarın koordinatları)
        point: LatLng(ihbar.enlem, ihbar.boylam),
        
        // Marker boyutu
        width: 40,
        height: 40,

        // Marker widget'ı
        child: GestureDetector(
          // Marker'a tıklandığında ihbar detayını göster
          onTap: () => _ihbarDetayiniGoster(ihbar),
          
          child: Container(
            // İhbar tipine göre renkli dairesel marker
            decoration: BoxDecoration(
              color: ihbar.durum == IhbarDurumu.Cozuldu ? Colors.green : ihbar.tip.renk,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              // Gölge efekti
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            // İkon
            child: Icon(
              ihbar.durum == IhbarDurumu.Cozuldu ? Icons.check : ihbar.tip.ikon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();
  }

  /// İhbar detayını bottom sheet olarak gösterir
  /// Kullanıcı marker'a tıkladığında çağrılır
  void _ihbarDetayiniGoster(Ihbar ihbar) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,  // İçerik boyutuna göre ayarla
      backgroundColor: Colors.transparent,  // Köşeleri yuvarlamak için
      builder: (context) {
        return IhbarDetayWidget(ihbar: ihbar);
      },
    );
  }
}
