import 'package:flutter/material.dart';
import '../services/auth_servisi.dart';
import '../models/kullanici.dart';
import '../models/ihbar_tipi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcının uygulama ayarlarını yönettiği sayfa
/// Bildirim tercihleri buradan ayarlanır
class AyarlarSayfasi extends StatefulWidget {
  const AyarlarSayfasi({super.key});

  @override
  State<AyarlarSayfasi> createState() => _AyarlarSayfasiState();
}

class _AyarlarSayfasiState extends State<AyarlarSayfasi> {
  final AuthServisi _authServisi = AuthServisi();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Kullanıcının tercihleri (Başlangıçta boş)
  List<String> _seciliTercihler = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _kullaniciAyarlariniGetir();
  }

  /// Kullanıcının mevcut tercihlerini Firestore'dan çeker
  Future<void> _kullaniciAyarlariniGetir() async {
    final userId = _authServisi.aktifKullaniciId;
    if (userId != null) {
      final kullanici = await _authServisi.kullaniciBilgileriniGetir(userId);
      if (kullanici != null && mounted) {
        setState(() {
          _seciliTercihler = List.from(kullanici.bildirimTercihleri);
          _yukleniyor = false;
        });
      }
    }
  }

  /// Tercih değişikliğini Firestore'a kaydeder
  Future<void> _tercihGuncelle(String tip, bool eklensinMi) async {
    final userId = _authServisi.aktifKullaniciId;
    if (userId == null) return;

    // Yerel listeyi güncelle
    setState(() {
      if (eklensinMi) {
        if (!_seciliTercihler.contains(tip)) {
          _seciliTercihler.add(tip);
        }
      } else {
        _seciliTercihler.remove(tip);
      }
    });

    // Firestore'da güncelle
    try {
      await _firestore.collection('users').doc(userId).update({
        'bildirimTercihleri': _seciliTercihler,
      });
      
      // Başarılı olduğunda log veya kullanıcıya bilgi verilebilir
      debugPrint('Tercihler güncellendi: $tip -> $eklensinMi');
      
    } catch (e) {
      // Hata durumunda (Opsiyonel: Snackbar gösterilebilir)
      debugPrint('Güncelleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Ayarlar kaydedilemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        // Tema rengi otomatik gelecek (Main.dart'tan)
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Hangi konularda bildirim almak istersiniz?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                
                // İhbar tiplerini listele
                ...IhbarTipi.values.map((tip) {
                  final seciliMi = _seciliTercihler.contains(tip.isim);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: SwitchListTile(
                      // Sol tarafta ikon ve metin
                      secondary: CircleAvatar(
                        backgroundColor: tip.renk.withOpacity(0.2),
                        child: Icon(tip.ikon, color: tip.renk),
                      ),
                      title: Text(tip.isim),
                      subtitle: Text('${tip.isim} ile ilgili bildirimler'),
                      
                      // Switch durumu
                      value: seciliMi,
                      activeColor: Theme.of(context).primaryColor,
                      
                      // Değiştiğinde
                      onChanged: (yeniDeger) {
                        _tercihGuncelle(tip.isim, yeniDeger);
                      },
                    ),
                  );
                }),
                
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Değişiklikler otomatik kaydedilir.',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
    );
  }
}
