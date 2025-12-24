import 'package:flutter/material.dart';
import '../services/auth_servisi.dart';
import 'giris_ekrani.dart';

/// Yeni kullanıcı kaydı ekranı
/// Ad, Soyad, E-posta, Şifre ve Bölüm bilgilerini alır
class KayitEkrani extends StatefulWidget {
  const KayitEkrani({super.key});

  @override
  State<KayitEkrani> createState() => _KayitEkraniState();
}

class _KayitEkraniState extends State<KayitEkrani> {
  
  // Form anahtarı (validasyon için)
  final _formAnahtari = GlobalKey<FormState>();
  
  // Auth servisi
  final AuthServisi _authServisi = AuthServisi();
  
  // Form kontrol edicileri
  final TextEditingController _adKontrol = TextEditingController();
  final TextEditingController _soyadKontrol = TextEditingController();
  final TextEditingController _epostaKontrol = TextEditingController();
  final TextEditingController _sifreKontrol = TextEditingController();
  final TextEditingController _bolumKontrol = TextEditingController();
  
  // Yükleniyor durumu
  bool _yukleniyor = false;
  
  // Şifre görünürlüğü
  bool _sifreGizli = true;

  @override
  void dispose() {
    // Bellek sızıntısını önlemek için kontrol edicileri temizle
    _adKontrol.dispose();
    _soyadKontrol.dispose();
    _epostaKontrol.dispose();
    _sifreKontrol.dispose();
    _bolumKontrol.dispose();
    super.dispose();
  }

  /// Kayıt ol butonuna tıklandığında çalışır
  Future<void> _kayitOl() async {
    // Form validasyonunu kontrol et
    if (!_formAnahtari.currentState!.validate()) {
      return;
    }

    // Yüklenme durumunu başlat
    setState(() {
      _yukleniyor = true;
    });

    try {
      // Auth servisi ile kayıt ol
      await _authServisi.kayitOl(
        ad: _adKontrol.text.trim(),
        soyad: _soyadKontrol.text.trim(),
        eposta: _epostaKontrol.text.trim(),
        sifre: _sifreKontrol.text,
        bolum: _bolumKontrol.text.trim(),
      );

      // Başarılı - Kullanıcı oluşturuldu ve çıkış yapıldı
      // Giriş ekranına yönlendir ve mesaj göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarılı! Lütfen giriş yapınız.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Giriş ekranına geri dön (pop)
        // pushReplacement kullanırsak stack'te yeni bir Giriş Ekranı oluşur ve
        // alttaki AuthKontrol'ün yönlendirmesini göremeyiz.
        Navigator.pop(context);
      }
      
    } catch (hata) {
      // Hata mesajını göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(hata.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Yüklenme durumunu bitir
      if (mounted) {
        setState(() {
          _yukleniyor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formAnahtari,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Başlık ve açıklama
                const Icon(
                  Icons.person_add,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Yeni Hesap Oluştur',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Kampüs ihbar sistemine hoş geldiniz',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),

                // Ad alanı
                TextFormField(
                  controller: _adKontrol,
                  decoration: const InputDecoration(
                    labelText: 'Ad',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (deger) {
                    if (deger == null || deger.trim().isEmpty) {
                      return 'Lütfen adınızı girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Soyad alanı
                TextFormField(
                  controller: _soyadKontrol,
                  decoration: const InputDecoration(
                    labelText: 'Soyad',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (deger) {
                    if (deger == null || deger.trim().isEmpty) {
                      return 'Lütfen soyadınızı girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // E-posta alanı
                TextFormField(
                  controller: _epostaKontrol,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (deger) {
                    if (deger == null || deger.trim().isEmpty) {
                      return 'Lütfen e-posta adresinizi girin';
                    }
                    if (!deger.contains('@')) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Şifre alanı
                TextFormField(
                  controller: _sifreKontrol,
                  obscureText: _sifreGizli,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _sifreGizli ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _sifreGizli = !_sifreGizli;
                        });
                      },
                    ),
                  ),
                  validator: (deger) {
                    if (deger == null || deger.isEmpty) {
                      return 'Lütfen şifrenizi girin';
                    }
                    if (deger.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Bölüm alanı
                TextFormField(
                  controller: _bolumKontrol,
                  decoration: const InputDecoration(
                    labelText: 'Bölüm',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                    hintText: 'Örn: Bilgisayar Mühendisliği',
                  ),
                  validator: (deger) {
                    if (deger == null || deger.trim().isEmpty) {
                      return 'Lütfen bölümünüzü girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Kayıt ol butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _yukleniyor ? null : _kayitOl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _yukleniyor
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Kayıt Ol',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Giriş ekranına git
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Zaten hesabınız var mı?'),
                    TextButton(
                      onPressed: () {
                        // Giriş ekranına git
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GirisEkrani(),
                          ),
                        );
                      },
                      child: const Text('Giriş Yap'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
