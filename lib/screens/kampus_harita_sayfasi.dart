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
import 'ihbar_listesi_sayfasi.dart'; // İhbar Listesi eklendi

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

  // Uygulama açılış zamanı (Eski bildirimleri elemek için)
  // Saat farkı yüzünden kaçırmamak için 1 dakika öncesini baz alalım
  // Bu süre hem saati bozuk cihazları kurtarır hem de uygulamanın hemen yeniden başlatılması
  // durumunda bildirim tekrarını en aza indirir.
  final DateTime _baslangicZamani = DateTime.now().subtract(const Duration(minutes: 1));
  
  // Gösterilen bildirimleri takip etmek için Set
  final Set<String> _gosterilenBildirimIdleri = {};

  /// Kullanıcının bildirimlerini dinler ve SnackBar gösterir
  void _bildirimleriDinle() {
    final userId = _authServisi.aktifKullaniciId;
    if (userId != null) {
      _ihbarServisi.bildirimleriGetir(userId).listen((bildirimler) {
        if (!mounted) return;

        // Yeni bildirimleri filtrele ve göster
        final yeniBildirimler = bildirimler.where((b) {
          // Açılış zamanından öncekileri yine de filtrele (Güvenlik için)
          // Ama asıl koruma _gosterilenBildirimIdleri ile sağlanıyor
          return b.tarih.isAfter(_baslangicZamani);
        }).toList();
        
        // Eskiden yeniye sırala
        final siraliBildirimler = yeniBildirimler.reversed.toList();
        
        for (var bildirim in siraliBildirimler) {
          // Bildirim daha önce gösterildi mi?
          if (_gosterilenBildirimIdleri.contains(bildirim.id)) {
            continue;
          }
          
          // Gösterildi olarak işaretle
          _gosterilenBildirimIdleri.add(bildirim.id);
           
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (bildirim.ihbarId == 'ACIL_DURUM')
                        const Icon(Icons.warning, color: Colors.white)
                      else 
                        const Icon(Icons.notifications, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(child: Text(bildirim.mesaj)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Zaman Barı (Progress Bar)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 0.0),
                    duration: Duration(seconds: bildirim.ihbarId == 'ACIL_DURUM' ? 10 : 4),
                    onEnd: () {
                      // Süre bittiğinde bar tamamen dolduğunda (0'a indiğinde)
                      // Bildirimi kapat
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      );
                    },
                  ),
                ],
              ),
              backgroundColor: bildirim.ihbarId == 'ACIL_DURUM' ? Colors.red : Colors.green,
              // Süreyi sonsuz yapıyoruz ki kontrol tamamen progress bar'da olsun
              duration: const Duration(days: 1),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Tamam',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Sadece şu anki bildirimi kapat, kuyruğu silme
                },
              ),
            ),
          );
        }
      });
    }
  }

  // Arama işlemleri için kontrolcü ve değişken
  final TextEditingController _aramaKontrolcusu = TextEditingController();
  String _aramaMetni = '';

  // Filtreleme için seçili tipler (Boşsa hepsi seçili demektir)
  List<IhbarTipi> _seciliFiltreler = [];

  // Filtre Seçim Dialogu
  Future<void> _filtreDialogGoster() async {
    await showDialog(
      context: context,
      builder: (context) {
        // Dialog içinde state yönetimi için StatefulBuilder kullanıyoruz
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Filtrele'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: IhbarTipi.values.map((tip) {
                    final secili = _seciliFiltreler.contains(tip);
                    return CheckboxListTile(
                      title: Row(
                        children: [
                          Icon(tip.ikon, color: tip.renk, size: 20),
                          const SizedBox(width: 8),
                          Text(tip.isim),
                        ],
                      ),
                      value: secili,
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == true) {
                            _seciliFiltreler.add(tip);
                          } else {
                            _seciliFiltreler.remove(tip);
                          }
                        });
                        // Ana ekranı da güncelle ki anlık değişimi görebilelim (opsiyonel)
                        this.setState(() {}); 
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Temizle (Hepsini göster)
                    setState(() {
                      _seciliFiltreler.clear();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Temizle'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Uygula'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    // Controller'ı temizle
    _aramaKontrolcusu.dispose();
    super.dispose();
  }

  // Seçili sayfa indeksi (0: Harita, 1: Liste)
  int _seciliSayfaIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Üst başlık çubuğu
      appBar: AppBar(
        title: Text(
          _seciliSayfaIndex == 0 
              ? (_kullaniciAdi != null ? 'Merhaba, $_kullaniciAdi 👋' : 'Kampüs Haritası')
              : 'İhbar Listesi',
        ),
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
                
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Harita'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _seciliSayfaIndex = 0);
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.format_list_bulleted),
                  title: const Text('İhbar Listesi'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _seciliSayfaIndex = 1);
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
  // Profilin güncellenip güncellenmediğini anlamak için
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AyarlarSayfasi()),
                    );
                    // Sayfadan dönüldüğünde kullanıcı bilgisini güncelle
                    // AyarlarSayfasi'ndan çıkıldığında her zaman yenileyelim
                    if (mounted) {
                      setState(() {
                        _kullaniciGetir = _authServisi.kullaniciBilgileriniGetir(_authServisi.aktifKullaniciId!);
                        _kullaniciGetir.then((kullanici) {
                          if (kullanici != null && mounted) {
                            setState(() {
                              _kullaniciAdi = kullanici.ad;
                            });
                          }
                        });
                      });
                    }
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

      // Ana içerik: Harita ve Liste arasında geçiş
      body: IndexedStack(
        index: _seciliSayfaIndex,
        children: [
          _buildHaritaIcerigi(), // Sayfa 0: Harita
          const IhbarListesiSayfasi(), // Sayfa 1: Liste
        ],
      ),
      
      // Yeni İhbar Ekleme Butonu (Her iki sayfada da görünür)
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

      // Alt Navigasyon Çubuğu
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _seciliSayfaIndex,
        onTap: (index) {
          setState(() {
            _seciliSayfaIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Harita',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted),
            label: 'Liste',
          ),
        ],
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }

  /// Harita sayfasının içeriği (Mevcut kodun taşınmış hali)
  Widget _buildHaritaIcerigi() {
    return Column(
      children: [
        // Arama Çubuğu (Harita üzerinde sabit)
        // Arama Çubuğu ve Filtre (Harita üzerinde sabit)
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aramaKontrolcusu,
                  textCapitalization: TextCapitalization.sentences,
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
              const SizedBox(width: 8),
              // Filtre Butonu
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                     BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list, 
                    color: _seciliFiltreler.isNotEmpty ? Theme.of(context).primaryColor : Colors.grey[700]
                  ),
                  onPressed: _filtreDialogGoster,
                  tooltip: 'Filtrele',
                ),
              ),
            ],
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
              // Arama ve Tip Filtresi Uygula
              final filtrelenmisIhbarlar = tumIhbarlar.where((ihbar) {
                // 1. Metin Araması
                bool metinUyumu = true;
                if (_aramaMetni.isNotEmpty) {
                  metinUyumu = ihbar.baslik.toLowerCase().contains(_aramaMetni) || 
                               ihbar.aciklama.toLowerCase().contains(_aramaMetni);
                }

                // 2. Tip Filtresi (Liste boşsa hepsi, doluysa sadece seçililer)
                bool tipUyumu = true;
                if (_seciliFiltreler.isNotEmpty) {
                  tipUyumu = _seciliFiltreler.contains(ihbar.tip);
                }
                
                return metinUyumu && tipUyumu;
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
