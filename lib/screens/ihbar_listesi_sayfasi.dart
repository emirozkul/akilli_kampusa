import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ihbar.dart';
import '../models/ihbar_tipi.dart';
import '../models/ihbar_durumu.dart';
import '../services/ihbar_servisi.dart';
import '../services/auth_servisi.dart';
import 'ihbar_detay_sayfasi.dart';

class IhbarListesiSayfasi extends StatefulWidget {
  const IhbarListesiSayfasi({super.key});

  @override
  State<IhbarListesiSayfasi> createState() => _IhbarListesiSayfasiState();
}

class _IhbarListesiSayfasiState extends State<IhbarListesiSayfasi> {
  final IhbarServisi _ihbarServisi = IhbarServisi();
  final AuthServisi _authServisi = AuthServisi();
  final TextEditingController _searchController = TextEditingController();

  // Filtre Durumları
  String _aramaMetni = '';
  IhbarTipi? _secilenTip;
  bool _sadeceAcik = false;
  bool _sadeceTakip = false;
  String _siralama = 'En Yeni'; // Seçenekler: En Yeni, En Eski, A-Z, Z-A

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _authServisi.aktifKullaniciId;
    _searchController.addListener(() {
      setState(() {
        _aramaMetni = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtreleme ve Sıralama Mantığı
  List<Ihbar> _filtreleVeSirala(List<Ihbar> ihbarlar) {
    return ihbarlar.where((ihbar) {
      // 1. Arama Filtresi
      final icerikUyumu = ihbar.baslik.toLowerCase().contains(_aramaMetni) ||
          ihbar.aciklama.toLowerCase().contains(_aramaMetni);
      if (!icerikUyumu) return false;

      // 2. Tip Filtresi
      if (_secilenTip != null && ihbar.tip != _secilenTip) return false;

      // 3. "Sadece Açık" Filtresi (Açık veya İnceleniyor)
      if (_sadeceAcik) {
        if (ihbar.durum == IhbarDurumu.Cozuldu) return false;
      }

      // 4. "Takip Edilenler" Filtresi
      if (_sadeceTakip && _currentUserId != null) {
        if (!ihbar.takipEdenler.contains(_currentUserId)) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        // Sıralama
        switch (_siralama) {
          case 'En Yeni':
            return b.tarih.compareTo(a.tarih);
          case 'En Eski':
            return a.tarih.compareTo(b.tarih);
          case 'A-Z':
            return a.baslik.compareTo(b.baslik);
          case 'Z-A':
            return b.baslik.compareTo(a.baslik);
          default:
            return b.tarih.compareTo(a.tarih);
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          // ÜST KISIM: Arama ve Filtreler
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.deepPurple.shade50,
            child: Column(
              children: [
                // Arama Çubuğu
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Başlık veya açıklama ara...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filtre Chip'leri (Yatay Kaydırılabilir)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Sıralama Butonu
                      PopupMenuButton<String>(

                        tooltip: 'Sırala',
                        onSelected: (value) => setState(() => _siralama = value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'En Yeni', child: Text('En Yeni')),
                          const PopupMenuItem(value: 'En Eski', child: Text('En Eski')),
                          const PopupMenuItem(value: 'A-Z', child: Text('Başlık A-Z')),
                          const PopupMenuItem(value: 'Z-A', child: Text('Başlık Z-A')),
                        ],
                        child: Chip(
                          label: Text(_siralama),
                          avatar: const Icon(Icons.sort, size: 18),
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Sadece Açık Filtresi
                      FilterChip(
                        label: const Text('Sadece Açık'),
                        selected: _sadeceAcik,
                        onSelected: (val) => setState(() => _sadeceAcik = val),
                        checkmarkColor: Colors.white,
                        selectedColor: Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: _sadeceAcik ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Takip Edilenler Filtresi
                      FilterChip(
                        label: const Text('Takip Ettiklerim'),
                        selected: _sadeceTakip,
                        onSelected: (val) => setState(() => _sadeceTakip = val),
                        checkmarkColor: Colors.white,
                        selectedColor: Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: _sadeceTakip ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tip Filtresi (Dropdown Mantığı ile çalışan Chip)
                       PopupMenuButton<IhbarTipi?>(
                        tooltip: 'İhbar Tipi',
                        onSelected: (value) => setState(() => _secilenTip = value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: null, child: Text('Tümü')),
                          ...IhbarTipi.values.map((tip) => PopupMenuItem(
                            value: tip, 
                            child: Row(children: [
                              Icon(tip.ikon, color: tip.renk, size: 18),
                              const SizedBox(width: 8),
                              Text(tip.isim)
                            ])
                          )),
                        ],
                        child: Chip(
                          label: Text(_secilenTip?.isim ?? 'Tüm Tipler'),
                          avatar: Icon(
                            _secilenTip?.ikon ?? Icons.filter_list, 
                            size: 18, 
                            color: _secilenTip?.renk ?? Colors.black
                          ),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // LISTE KISMI
          Expanded(
            child: StreamBuilder<List<Ihbar>>(
              stream: _ihbarServisi.tumIhbarlariGetir(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Bir hata oluştu.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tumIhbarlar = snapshot.data ?? [];
                final gosterilecekIhbarlar = _filtreleVeSirala(tumIhbarlar);

                if (gosterilecekIhbarlar.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Kriterlere uygun ihbar bulunamadı.'),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: gosterilecekIhbarlar.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final ihbar = gosterilecekIhbarlar[index];
                    return _ihbarKartiOlustur(ihbar, context);
                  },
                );
              },
            ),
          ),
        ],
    );
  }

  Widget _ihbarKartiOlustur(Ihbar ihbar, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Karta tıklanınca detay sayfasına git
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IhbarDetaySayfasi(ihbar: ihbar),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Satır: İkon, Başlık, Tarih
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İhbar Tipi İkonu
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ihbar.tip.renk.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(ihbar.tip.ikon, color: ihbar.tip.renk),
                  ),
                  const SizedBox(width: 12),
                  
                  // Başlık ve Açıklama
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ihbar.baslik,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ihbar.aciklama,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  
                  // Durum Bagde'i
                  _durumBadge(ihbar.durum),
                ],
              ),
              const SizedBox(height: 12),
              
              // Alt Satır: Tarih
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(ihbar.tarih),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _durumBadge(IhbarDurumu durum) {
    Color renk;
    switch (durum) {
      case IhbarDurumu.Acik: renk = Colors.orange; break;
      case IhbarDurumu.Inceleniyor: renk = Colors.blue; break;
      case IhbarDurumu.Cozuldu: renk = Colors.green; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withOpacity(0.5)),
      ),
      child: Text(
        durum.isim,
        style: TextStyle(color: renk, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
