import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/auth_servisi.dart';
import '../models/kullanici.dart';
import '../models/ihbar_tipi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcının profil ve uygulama ayarlarını yönettiği sayfa
class AyarlarSayfasi extends StatefulWidget {
  const AyarlarSayfasi({super.key});

  @override
  State<AyarlarSayfasi> createState() => _AyarlarSayfasiState();
}

class _AyarlarSayfasiState extends State<AyarlarSayfasi> {
  final AuthServisi _authServisi = AuthServisi();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // Form anahtarı
  final _formKey = GlobalKey<FormState>();

  // Controller'lar
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _soyadController = TextEditingController();
  final TextEditingController _bolumController = TextEditingController();
  final TextEditingController _yasController = TextEditingController();

  // Durum değişkenleri
  bool _yukleniyor = true;
  List<String> _seciliTercihler = [];
  String? _profilResmiUrl; // Mevcut URL (Varsa)
  File? _secilenResim;     // Yeni seçilen resim (Henüz yüklenmediyse)

  @override
  void initState() {
    super.initState();
    _kullaniciBilgileriniGetir();
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _bolumController.dispose();
    _yasController.dispose();
    super.dispose();
  }

  /// Kullanıcı bilgilerini ve ayarlarını getir
  Future<void> _kullaniciBilgileriniGetir() async {
    final userId = _authServisi.aktifKullaniciId;
    if (userId != null) {
      final kullanici = await _authServisi.kullaniciBilgileriniGetir(userId);
      if (kullanici != null && mounted) {
        setState(() {
          _adController.text = kullanici.ad;
          _soyadController.text = kullanici.soyad;
          _bolumController.text = kullanici.bolum;
          _yasController.text = kullanici.yas > 0 ? kullanici.yas.toString() : '';
          _profilResmiUrl = kullanici.profilResmiUrl;
          _seciliTercihler = List.from(kullanici.bildirimTercihleri);
          _yukleniyor = false;
        });
      }
    }
  }

  /// Galeriden veya kameradan resim seç
  Future<void> _resimSec() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _secilenResim = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim seçilirken hata: $e')),
      );
    }
  }

  /// Değişiklikleri kaydet
  Future<void> _kaydet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _yukleniyor = true;
    });

    try {
      final userId = _authServisi.aktifKullaniciId;
      if (userId == null) throw 'Kullanıcı oturumu yok';

      // Güncellenecek veriler
      Map<String, dynamic> guncelVeriler = {
        'ad': _adController.text.trim(),
        'soyad': _soyadController.text.trim(),
        'bolum': _bolumController.text.trim(),
        'yas': int.tryParse(_yasController.text.trim()) ?? 0,
        // bildirimTercihleri zaten anlık güncelleniyor ama buraya da ekleyebiliriz
      };

      // Resim yükleme simülasyonu (Gerçek Firebase Storage yoksa URL olarak path'i veya base64'ü kaydedemeyiz, 
      // ancak burada "Resim Seçildi" mesajı verip geçeceğiz veya yerel path'i kaydedeceğiz. 
      // Gerçek uygulamada Firebase Storage'a yükleyip URL almamız gerekir.)
      // Kullanıcı talebinde "Storage" kurulumu belirtilmediği için şimdilik sadece seçilen resmi lokalde gösteriyoruz 
      // veya basitçe 'profilResmiUrl' alanına dummy bir url atayabiliriz.
      // Ancak "Image Picker" istendiği için seçilen resmi bir şekilde işlemeliyiz.
      // Basitlik adına: Eğer resim seçildiyse bunu Firebase Storage'a yükleme kodu buraya gelir.
      // Şimdilik sadece uyarı verelim.
      if (_secilenResim != null) {
        // TODO: Firebase Storage entegrasyonu
        // String yeniUrl = await _resimYukle(_secilenResim!);
        // guncelVeriler['profilResmiUrl'] = yeniUrl;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not: Resim yükleme sunucusu henüz aktif değil, sadece profil bilgileri güncellendi.')),
        );
      }

      await _authServisi.kullaniciBilgileriniGuncelle(userId, guncelVeriler);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi')),
        );
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

  /// Tercih değişikliğini Firestore'a kaydeder (Anlık)
  Future<void> _tercihGuncelle(String tip, bool eklensinMi) async {
    final userId = _authServisi.aktifKullaniciId;
    if (userId == null) return;

    setState(() {
      if (eklensinMi) {
        if (!_seciliTercihler.contains(tip)) {
          _seciliTercihler.add(tip);
        }
      } else {
        _seciliTercihler.remove(tip);
      }
    });

    try {
      await _firestore.collection('users').doc(userId).update({
        'bildirimTercihleri': _seciliTercihler,
      });
    } catch (e) {
      print('Tercih güncellenemedi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil ve Ayarlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _yukleniyor ? null : _kaydet,
            tooltip: 'Kaydet',
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Profil Resmi ---
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _secilenResim != null
                                ? FileImage(_secilenResim!)
                                : (_profilResmiUrl != null && _profilResmiUrl!.isNotEmpty
                                    ? NetworkImage(_profilResmiUrl!) as ImageProvider
                                    : null),
                            child: (_secilenResim == null && (_profilResmiUrl == null || _profilResmiUrl!.isEmpty))
                                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                onPressed: _resimSec,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Profil Bilgileri Formu ---
                    const Text('Kişisel Bilgiler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _adController,
                            decoration: const InputDecoration(
                              labelText: 'Ad',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _soyadController,
                            decoration: const InputDecoration(
                              labelText: 'Soyad',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? 'Gerekli' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _yasController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Yaş',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_month),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _bolumController,
                            decoration: const InputDecoration(
                              labelText: 'Bölüm',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.school),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    // --- Bildirim Ayarları (Eski İçerik) ---
                    const Text('Bildirim Tercihleri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Hangi konularda bildirim almak istersiniz?', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),

                    ...IhbarTipi.values.map((tip) {
                      final seciliMi = _seciliTercihler.contains(tip.isim);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: SwitchListTile(
                          secondary: CircleAvatar(
                            backgroundColor: tip.renk.withOpacity(0.2),
                            child: Icon(tip.ikon, color: tip.renk),
                          ),
                          title: Text(tip.isim),
                          value: seciliMi,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (val) => _tercihGuncelle(tip.isim, val),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
}
