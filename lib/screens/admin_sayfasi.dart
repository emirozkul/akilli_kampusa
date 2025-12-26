import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_servisi.dart';
import '../services/ihbar_servisi.dart';
import '../models/ihbar.dart';
import '../models/ihbar_durumu.dart';
import '../models/ihbar_tipi.dart';
import 'kampus_harita_sayfasi.dart';

import '../models/kullanici.dart'; // Kullanıcı modeli eklendi

/// Admin paneli sayfası
/// Sadece Admin rolüne sahip kullanıcılar bu sayfayı görür
class AdminSayfasi extends StatefulWidget {
  const AdminSayfasi({super.key});

  @override
  State<AdminSayfasi> createState() => _AdminSayfasiState();
}

class _AdminSayfasiState extends State<AdminSayfasi> {
  final AuthServisi _authServisi = AuthServisi();
  final IhbarServisi _ihbarServisi = IhbarServisi();
  
  // Filtreleme için seçilen durum (null ise hepsi)
  IhbarDurumu? _secilenFiltre;

  // Arama işlemleri için kontrolcü ve değişken
  final TextEditingController _aramaKontrolcusu = TextEditingController();
  String _aramaMetni = '';

  // Kullanıcı bilgisi future
  late Future<Kullanici?> _kullaniciGetir;

  // Seçili tab indeksi
  int _seciliSayfaIndex = 0;

  @override
  void initState() {
    super.initState();
    _kullaniciGetir = _authServisi.kullaniciBilgileriniGetir(_authServisi.aktifKullaniciId!);
  }

  @override
  void dispose() {
    _aramaKontrolcusu.dispose();
    super.dispose();
  }

  // Çıkış yapma işlemi
  Future<void> _cikisYap() async {
    try {
      await _authServisi.cikisYap();
      // Navigator.pop kullanmıyoruz, çünkü main.dart stream'i sayfayı değiştirecek.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yapılamadı: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Çıkış Yap',
            onPressed: () => _cikisYap(), 
          ),
        ],
      ),
      // Alt Navigasyon Çubuğu
      bottomNavigationBar: NavigationBar(
        selectedIndex: _seciliSayfaIndex,
        onDestinationSelected: (index) {
          setState(() {
            _seciliSayfaIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'İhbarlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Harita',
          ),
        ],
      ),
      // Sayfa içeriği
      body: IndexedStack(
        index: _seciliSayfaIndex,
        children: [
          // Sayfa 0: İhbar Yönetimi Listesi
          _buildIhbarYonetimiSayfasi(),
          
          // Sayfa 1: Harita Görünümü
          // Harita sayfasını doğrudan gömmek yerine, onu ayrı bir context'te açmak daha iyi olabilir
          // Ancak "Navbar kayboluyor" sorununu çözmek için burada göstermeyi deneyelim.
          // KampusHaritaSayfasi bir Scaffold döndürüyor, bu yüzden iç içe Scaffold sorun olabilir.
          // Basitlik için burada direkt widget'ı çağırıyoruz, 
          // ama KampusHaritaSayfasi'nın Scaffold'ını kaldırmak gerekebilir.
          // Şimdilik KampusHaritaSayfasi'nı olduğu gibi kullanacağız.
          const KampusHaritaSayfasi(),
        ],
      ),
      floatingActionButton: _seciliSayfaIndex == 0 ? FloatingActionButton(
        onPressed: _acilDurumBildirDialog,
        backgroundColor: Colors.red,
        child: const Icon(Icons.notification_important, color: Colors.white),
        tooltip: 'Acil Durum Yayını',
      ) : null, // Harita sayfasında kendi FAB'ı olabilir
    );
  }

  /// İhbar Yönetimi Sayfası İçeriği (Eski Body)
  Widget _buildIhbarYonetimiSayfasi() {
    return Column(
        children: [
          // Üst Bilgi ve Filtreler
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Arama Çubuğu (Search Bar)
                TextField(
                  controller: _aramaKontrolcusu,
                  decoration: InputDecoration(
                    hintText: 'İhbarlarda ara (Başlık veya Açıklama)...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onChanged: (yeniDeger) {
                    setState(() {
                      _aramaMetni = yeniDeger.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Filtreleme Chip'leri
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // "Tümü" Filtresi
                      FilterChip(
                        label: const Text('Tümü'),
                        selected: _secilenFiltre == null,
                        onSelected: (bool selected) {
                          setState(() {
                            _secilenFiltre = null;
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                      const SizedBox(width: 8),
                      
                      // Diğer Durum Filtreleri
                      ...IhbarDurumu.values.map((durum) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(durum.isim),
                            selected: _secilenFiltre == durum,
                            onSelected: (bool selected) {
                              setState(() {
                                _secilenFiltre = selected ? durum : null;
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // İhbar Listesi
          Expanded(
            child: StreamBuilder<List<Ihbar>>(
              stream: _secilenFiltre == null
                  ? _ihbarServisi.tumIhbarlariGetir()
                  : _ihbarServisi.durumaGoreIhbarlariGetir(_secilenFiltre!.isim),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata oluştu: ${snapshot.error}'),
                  );
                }

                final tumIhbarlar = snapshot.data ?? [];
                
                final filtrelenmisListe = tumIhbarlar.where((ihbar) {
                  final baslikKucuk = ihbar.baslik.toLowerCase();
                  final aciklamaKucuk = ihbar.aciklama.toLowerCase();
                  
                  return baslikKucuk.contains(_aramaMetni) || 
                         aciklamaKucuk.contains(_aramaMetni);
                }).toList();

                if (filtrelenmisListe.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _aramaMetni.isEmpty ? 'Henüz ihbar yok' : 'Sonuç bulunamadı',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtrelenmisListe.length,
                  itemBuilder: (context, index) {
                    final ihbar = filtrelenmisListe[index];
                    return _ihbarKartiOlustur(ihbar);
                  },
                );
              },
            ),
          ),
        ],
      );
  }

  // Liste elemanı kartı
  Widget _ihbarKartiOlustur(Ihbar ihbar) {
    // Tarih formatı
    final tarihFormati = DateFormat('dd MMM HH:mm', 'tr_TR');
    
    // Durum rengi belirle
    Color durumRengi;
    switch (ihbar.durum) {
      case IhbarDurumu.Acik:
        durumRengi = Colors.red;
        break;
      case IhbarDurumu.Inceleniyor:
        durumRengi = Colors.blue;
        break;
      case IhbarDurumu.Cozuldu:
        durumRengi = Colors.green;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: ihbar.tip.renk.withOpacity(0.2),
          child: Icon(ihbar.tip.ikon, color: ihbar.tip.renk, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                ihbar.baslik,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Admin için Düzenleme Butonu
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              tooltip: 'İhbarı Düzenle',
              onPressed: () => _adminIhbarDuzenleDialog(ihbar),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: durumRengi.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: durumRengi.withOpacity(0.5)),
              ),
              child: Text(
                ihbar.durum.isim,
                style: TextStyle(fontSize: 12, color: durumRengi, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tarihFormati.format(ihbar.tarih),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Açıklama
                const Text(
                  'Açıklama:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(ihbar.aciklama),
                const SizedBox(height: 12),
                
                // Konum
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${ihbar.enlem.toStringAsFixed(5)}, ${ihbar.boylam.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Takipçi Sayısı
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${ihbar.takipEdenler.length} Takipçi',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                
                const Divider(height: 24),
                
                // Aksiyon Butonları (Durum Değiştirme)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Durum Güncelle:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: IhbarDurumu.values.map((yeniDurum) {
                    // Mevcut durum ile aynıysa devre dışı veya seçili göster
                    bool secili = ihbar.durum == yeniDurum;
                    
                    return ActionChip(
                      label: Text(yeniDurum.isim),
                      avatar: secili ? const Icon(Icons.check, size: 16) : null,
                      backgroundColor: secili ? Colors.grey[300] : Colors.white,
                      onPressed: secili 
                        ? null 
                        : () => _durumGuncelleDialog(ihbar, yeniDurum),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 8),
                
                // Silme Butonu
                OutlinedButton.icon(
                  onPressed: () => _silmeOnayiAl(ihbar),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('İhbarı Sil', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Durum güncelleme onayı ve işlemi
  Future<void> _durumGuncelleDialog(Ihbar ihbar, IhbarDurumu yeniDurum) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durum Güncelle'),
        content: Text(
          '"${ihbar.baslik}" başlıklı ihbarın durumunu "${yeniDurum.isim}" olarak güncellemek istiyor musunuz?\n\n'
          'Bu işlem takipçilere bildirim gönderecektir.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );

    if (onay == true) {
      try {
        await _ihbarServisi.durumGuncelle(ihbar.id, yeniDurum);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Durum "${yeniDurum.isim}" olarak güncellendi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  // Silme onayı ve işlemi
  Future<void> _silmeOnayiAl(Ihbar ihbar) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İhbarı Sil'),
        content: Text(
          '"${ihbar.baslik}" başlıklı ihbarı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (onay == true) {
      try {
        await _ihbarServisi.ihbarSil(ihbar.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İhbar silindi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  // Acil Durum Bildirim Diyaloğu
  Future<void> _acilDurumBildirDialog() async {
    final mesajKontrol = TextEditingController(text: 'KAMPÜSTE ACİL DURUM! Lütfen güvenli bölgelere geçiniz.');
    
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text('ACİL DURUM YAYINI'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu mesaj TÜM KULLANICILARA gönderilecektir. Emin misiniz?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: mesajKontrol,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bildirim Mesajı',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('HERKESE GÖNDER', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (onay == true) {
      if (mesajKontrol.text.trim().isEmpty) return;

      try {
        await _ihbarServisi.tumKullanicilaraBildirimGonder(
          baslik: '⚠️ ACİL DURUM ⚠️', 
          mesaj: mesajKontrol.text.trim(),
          gonderenId: _authServisi.aktifKullaniciId, // Kendi kendine bildirim gitmesin
        );
        
        if (mounted) {
          showDialog(
            context: context, 
            builder: (ctx) => AlertDialog(
              title: const Text('Başarılı'),
              content: const Text('Acil durum bildirimi tüm kullanıcılara gönderildi.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam'))
              ],
            )
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
  // Admin İhbar Düzenleme Diyaloğu
  Future<void> _adminIhbarDuzenleDialog(Ihbar ihbar) async {
    final baslikKontrol = TextEditingController(text: ihbar.baslik);
    final aciklamaKontrol = TextEditingController(text: ihbar.aciklama);

    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İhbarı Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: baslikKontrol,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: aciklamaKontrol,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (onay == true) {
      if (baslikKontrol.text.trim().isEmpty || aciklamaKontrol.text.trim().isEmpty) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Başlık ve açıklama boş olamaz')),
          );
        }
        return;
      }

      try {
        await _ihbarServisi.ihbarGuncelle(ihbar.id, {
          'baslik': baslikKontrol.text.trim(),
          'aciklama': aciklamaKontrol.text.trim(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İhbar başarıyla güncellendi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }
}
