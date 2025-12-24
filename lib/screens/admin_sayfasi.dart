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

  @override
  void initState() {
    super.initState();
    // Kullanıcı bilgisini getir
    _kullaniciGetir = _authServisi.kullaniciBilgileriniGetir(_authServisi.aktifKullaniciId!);
  }

  @override
  void dispose() {
    // Controller'ı temizle (Bellek sızıntısını önlemek için)
    _aramaKontrolcusu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        // Renkler temadan gelecek
      ),
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
                // Profil Başlığı - Özelleştirilmiş Tasarım
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
                      
                      // İsim ve E-posta (Çakışmayı önlemek için ayrı satırlar)
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
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('İhbar Yönetimi'),
                  selected: true,
                  onTap: () {
                    Navigator.pop(context); // Menüyü kapat
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Haritayı Gör'),
                  onTap: () {
                    Navigator.pop(context); // Menüyü kapat
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const KampusHaritaSayfasi()),
                    );
                  },
                ),
                
                // Acil Durum Bildir
                ListTile(
                  leading: const Icon(Icons.notification_important, color: Colors.red),
                  title: const Text('Acil Durum Bildir', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context); // Menüyü kapat
                    _acilDurumBildirDialog();
                  },
                ),

                const Divider(),

                // Çıkış Yap
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await _authServisi.cikisYap();
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Üst Bilgi ve Filtreler
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant, // Tema uyumlu arka plan
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'İhbar Yönetimi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    // color: Colors.orange, // Sabit renk yerine tema varsayılanı veya primary
                  ),
                ),
                const SizedBox(height: 12),

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
                  // Metin değiştiğinde aramayı tetikler
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
              // Veritabanından gelen temel veri akışı (Varsa durum filtresiyle)
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

                // Gelen ham liste
                final tumIhbarlar = snapshot.data ?? [];
                
                // Arama filtresini uygula
                // Hem başlıkta hem de açıklamada arama yapar
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
      ),
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
        title: Text(
          ihbar.baslik,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
          mesaj: mesajKontrol.text.trim()
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
}
