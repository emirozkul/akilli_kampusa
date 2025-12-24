import 'package:flutter/material.dart';
import '../services/auth_servisi.dart';

/// Şifre sıfırlama ekranı
/// Kullanıcıya e-posta ile şifre sıfırlama linki gönderir
class SifreSifirlamaEkrani extends StatefulWidget {
  const SifreSifirlamaEkrani({super.key});

  @override
  State<SifreSifirlamaEkrani> createState() => _SifreSifirlamaEkraniState();
}

class _SifreSifirlamaEkraniState extends State<SifreSifirlamaEkrani> {
  
  // Form anahtarı
  final _formAnahtari = GlobalKey<FormState>();
  
  // Auth servisi
  final AuthServisi _authServisi = AuthServisi();
  
  // E-posta kontrol edicisi
  final TextEditingController _epostaKontrol = TextEditingController();
  
  // Yükleniyor durumu
  bool _yukleniyor = false;

  @override
  void dispose() {
    _epostaKontrol.dispose();
    super.dispose();
  }

  /// Şifre sıfırlama e-postası gönder
  Future<void> _sifreSifirlamaGonder() async {
    // Form validasyonunu kontrol et
    if (!_formAnahtari.currentState!.validate()) {
      return;
    }

    // Yüklenme durumunu başlat
    setState(() {
      _yukleniyor = true;
    });

    try {
      // Auth servisi ile şifre sıfırlama e-postası gönder
      await _authServisi.sifreSifirla(_epostaKontrol.text.trim());

      // Başarılı mesaj göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre sıfırlama e-postası gönderildi. Lütfen e-postanızı kontrol edin.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        // Giriş ekranına geri dön
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
        title: const Text('Şifre Sıfırlama'),
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
                // İkon
                const Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),

                // Başlık
                const Text(
                  'Şifrenizi mi unuttunuz?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Açıklama
                const Text(
                  'E-posta adresinizi girin. Size şifre sıfırlama bağlantısı gönderelim.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

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
                const SizedBox(height: 24),

                // Gönder butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _yukleniyor ? null : _sifreSifirlamaGonder,
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
                            'Şifre Sıfırlama E-postası Gönder',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Geri dön
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Giriş Ekranına Dön'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
