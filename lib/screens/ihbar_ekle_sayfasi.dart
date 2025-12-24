import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/ihbar.dart';
import '../services/ihbar_servisi.dart';
import '../services/auth_servisi.dart'; // Kullanıcı ID'si için
import '../models/ihbar_tipi.dart';
import '../models/ihbar_durumu.dart';

/// Kullanıcının yeni bir ihbar oluşturmasını sağlayan sayfa
class IhbarEkleSayfasi extends StatefulWidget {
  // Varsayılan konum (Haritada seçilen veya kullanıcının o anki konumu)
  // Şimdilik Ankara merkezli başlıyor
  final LatLng baslangicKonumu;

  const IhbarEkleSayfasi({
    super.key, 
    this.baslangicKonumu = const LatLng(39.9, 32.85),
  });

  @override
  State<IhbarEkleSayfasi> createState() => _IhbarEkleSayfasiState();
}

class _IhbarEkleSayfasiState extends State<IhbarEkleSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _baslikController = TextEditingController();
  final _aciklamaController = TextEditingController();
  
  // Seçilen ihbar tipi (Varsayılan: Diğer)
  IhbarTipi _secilenTip = IhbarTipi.Diger;
  
  // Haritada seçilen konum
  late LatLng _secilenKonum;
  
  // Yükleniyor mu?
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    _secilenKonum = widget.baslangicKonumu;
  }

  @override
  void dispose() {
    _baslikController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  /// İhbarı kaydeder
  Future<void> _ihbariKaydet() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _yukleniyor = true;
      });

      try {
        // Şu anki kullanıcı ID'sini al
        final kId = AuthServisi().aktifKullaniciId;
        
        if (kId == null) {
          throw 'Kullanıcı oturumu bulunamadı';
        }

        // Yeni ihbar nesnesi oluştur
        final yeniIhbar = Ihbar(
          id: '', // Firestore otomatik atayacak (serviste yönetilebilir ama modelde required)
          // NOT: Servis create ederken ID'yi yok sayıp yeni ID ile oluşturmalı veya
          // modelde ID'yi opsiyonel yapmalıydık. Ama şimdilik boş string verelim,
          // serviste .add() kullanınca ID değişecek.
          // DÜZELTME: IhbarServisi.ihbarEkle metodu parametre olarak Ihbar alıyor ve .toJson() çağırıyor.
          // Firestore .add() metodu yeni bir ID üretir. Bizim modeldeki 'id' alanı
          // Firestore'a kaydedilmiyor (toJson içinde yok), sadece okurken dolduruluyor.
          // Bu yüzden buraya boş string vermek güvenli.
          
          baslik: _baslikController.text,
          aciklama: _aciklamaController.text,
          tip: _secilenTip,
          enlem: _secilenKonum.latitude,
          boylam: _secilenKonum.longitude,
          durum: IhbarDurumu.Acik, // Yeni ihbar her zaman Açık başlar
          olusturanId: kId,
          tarih: DateTime.now(),
        );

        // Servis üzerinden kaydet
        await IhbarServisi().ihbarEkle(yeniIhbar);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İhbar başarıyla oluşturuldu')),
          );
          Navigator.pop(context); // Önceki sayfaya dön
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni İhbar Oluştur'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Başlık Alanı
                    TextFormField(
                      controller: _baslikController,
                      decoration: const InputDecoration(
                        labelText: 'İhbar Başlığı',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                        hintText: 'Örn: Kütüphane Kliması Bozuk',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen bir başlık girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Açıklama Alanı
                    TextFormField(
                      controller: _aciklamaController,
                      decoration: const InputDecoration(
                        labelText: 'Detaylı Açıklama',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Sorunu detaylıca açıklayın...',
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen açıklama girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tip Seçimi Dropdown
                    DropdownButtonFormField<IhbarTipi>(
                      value: _secilenTip,
                      decoration: const InputDecoration(
                        labelText: 'İhbar Tipi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: IhbarTipi.values.map((tip) {
                        return DropdownMenuItem(
                          value: tip,
                          child: Row(
                            children: [
                              Icon(tip.ikon, color: tip.renk, size: 20),
                              const SizedBox(width: 10),
                              Text(tip.isim),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _secilenTip = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Konum Seçimi Başlığı
                    const Text(
                      'Konum Seçini',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Haritadaki ikonu sürükleyerek konumu ayarlayabilirsiniz.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),

                    // Küçük Harita Önizlemesi
                    SizedBox(
                      height: 250,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: _secilenKonum,
                                initialZoom: 16,
                                onTap: (tapPosition, point) {
                                  setState(() {
                                    _secilenKonum = point;
                                  });
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.akilli_kampusa',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _secilenKonum,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Koordinat Bilgisi (İsteğe bağlı, bilgi amaçlı)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Seçilen Koordinat: ${_secilenKonum.latitude.toStringAsFixed(4)}, ${_secilenKonum.longitude.toStringAsFixed(4)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Kaydet Butonu
                    ElevatedButton.icon(
                      onPressed: _ihbariKaydet,
                      icon: const Icon(Icons.send),
                      label: const Text('İhbarı Gönder'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
