import 'package:flutter/material.dart';
import '../services/auth_servisi.dart';
import 'kayit_ekrani.dart';
import 'sifre_sifirlama_ekrani.dart';

/// Kullanıcı giriş ekranı
/// E-posta ve şifre ile giriş yapılır
class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  
  // Form anahtarı
  final _formAnahtari = GlobalKey<FormState>();
  
  // Auth servisi
  final AuthServisi _authServisi = AuthServisi();
  
  // Form kontrol edicileri
  final TextEditingController _epostaKontrol = TextEditingController();
  final TextEditingController _sifreKontrol = TextEditingController();
  
  // Yükleniyor durumu
  bool _yukleniyor = false;
  
  // Şifre görünürlüğü
  bool _sifreGizli = true;

  @override
  void dispose() {
    _epostaKontrol.dispose();
    _sifreKontrol.dispose();
    super.dispose();
  }

  /// Giriş yap butonuna tıklandığında çalışır
  Future<void> _girisYap() async {
    // Form validasyonunu kontrol et
    if (!_formAnahtari.currentState!.validate()) {
      return;
    }

    // Yüklenme durumunu başlat
    setState(() {
      _yukleniyor = true;
    });

    try {
      // Auth servisi ile giriş yap
      await _authServisi.girisYap(
        eposta: _epostaKontrol.text.trim(),
        sifre: _sifreKontrol.text,
      );

      // Başarılı - main.dart otomatik olarak yönlendirecek
      
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formAnahtari,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ve başlık
                // Logo ve başlık
                Icon(
                  Icons.location_city,
                  size: 100,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Akıllı Kampüs',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Kampüs İhbar Sistemi',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),

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
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Şifremi unuttum linki
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Şifre sıfırlama ekranına git
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SifreSifirlamaEkrani(),
                        ),
                      );
                    },
                    child: const Text('Şifremi Unuttum'),
                  ),
                ),
                const SizedBox(height: 10),

                  // ... (text widgets)

                // Giriş yap butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _yukleniyor ? null : _girisYap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _yukleniyor
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Giriş Yap',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Kayıt ol linki
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Hesabınız yok mu?'),
                    TextButton(
                      onPressed: () {
                        // Kayıt ekranına git
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const KayitEkrani(),
                          ),
                        );
                      },
                      child: const Text('Kayıt Ol'),
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
