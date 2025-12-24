/// Firebase Authentication hata kodlarını Türkçe mesajlara çeviren yardımcı sınıf
/// Kullanıcıya anlaşılır hata mesajları göstermek için kullanılır
class HataMesajlari {
  
  /// Firebase Auth hata kodunu alır ve Türkçe mesaj döndürür
  /// 
  /// Parametreler:
  /// - hataKodu: Firebase'den gelen hata kodu (örn: 'user-not-found')
  /// 
  /// Döner: Türkçe hata mesajı
  static String getir(String hataKodu) {
    switch (hataKodu) {
      // Giriş hataları
      case 'user-not-found':
        return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı.';
      
      case 'wrong-password':
        return 'Hatalı şifre girdiniz. Lütfen tekrar deneyin.';
      
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      
      // Kayıt hataları
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      
      case 'weak-password':
        return 'Şifreniz çok zayıf. En az 6 karakter olmalıdır.';
      
      case 'invalid-email':
        return 'Geçersiz e-posta adresi. Lütfen kontrol edin.';
      
      // Genel hatalar
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      
      case 'too-many-requests':
        return 'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin.';
      
      case 'operation-not-allowed':
        return 'Bu işlem şu anda yapılamıyor.';
      
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmıştır.';
      
      // Şifre sıfırlama hataları
      case 'missing-email':
        return 'Lütfen e-posta adresinizi girin.';
      
      case 'invalid-action-code':
        return 'Şifre sıfırlama kodu geçersiz veya süresi dolmuş.';
      
      // Varsayılan hata mesajı
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}
