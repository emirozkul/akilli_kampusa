import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_servisi.dart';
import '../services/ihbar_servisi.dart';
import '../models/ihbar.dart';
import '../widgets/ihbar_detay_widget.dart';

/// Kullanıcının takip ettiği ihbarların listelendiği sayfa
class TakipEttiklerimSayfasi extends StatefulWidget {
  const TakipEttiklerimSayfasi({super.key});

  @override
  State<TakipEttiklerimSayfasi> createState() => _TakipEttiklerimSayfasiState();
}

class _TakipEttiklerimSayfasiState extends State<TakipEttiklerimSayfasi> {
  final IhbarServisi _ihbarServisi = IhbarServisi();
  final AuthServisi _authServisi = AuthServisi();

  @override
  Widget build(BuildContext context) {
    final aktifKullaniciId = _authServisi.aktifKullaniciId;

    if (aktifKullaniciId == null) {
      return const Scaffold(
        body: Center(child: Text('Giriş yapmalısınız')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Takip Ettiklerim'),
      ),
      body: StreamBuilder<List<Ihbar>>(
        // Takip edilenleri getiren servisi kullan
        stream: _ihbarServisi.takipEdilenleriGetir(aktifKullaniciId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final ihbarlar = snapshot.data ?? [];

          if (ihbarlar.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_border, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Henüz takip ettiğiniz bir ihbar yok.'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Haritaya Dön ve İhbarları İncele'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: ihbarlar.length,
            itemBuilder: (context, index) {
              final ihbar = ihbarlar[index];
              return _takipKartiOlustur(ihbar, aktifKullaniciId);
            },
          );
        },
      ),
    );
  }

  /// Liste elemanı kartı
  Widget _takipKartiOlustur(Ihbar ihbar, String userId) {
    final tarihFormati = DateFormat('dd MMM HH:mm', 'tr_TR');
    
    // Durum rengi
    Color durumRengi = Colors.grey;
    if (ihbar.durum.isim == 'Acik') durumRengi = Colors.red;
    if (ihbar.durum.isim == 'Inceleniyor') durumRengi = Colors.blue;
    if (ihbar.durum.isim == 'Cozuldu') durumRengi = Colors.green;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ihbar.tip.renk.withOpacity(0.2),
          child: Icon(ihbar.tip.ikon, color: ihbar.tip.renk),
        ),
        title: Text(
          ihbar.baslik,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                // Durum Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: durumRengi.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: durumRengi.withOpacity(0.5)),
                  ),
                  child: Text(
                    ihbar.durum.isim,
                    style: TextStyle(fontSize: 10, color: durumRengi, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(tarihFormati.format(ihbar.tarih), style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.bookmark_remove, color: Colors.red),
          tooltip: 'Takibi Bırak',
          onPressed: () async {
            // Takibi bırakma işlemi
             await _ihbarServisi.ihbarTakibiBirak(ihbar.id, userId);
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Takip bırakıldı')),
               );
             }
          },
        ),
        onTap: () {
          // Detayları göster (BottomSheet ile)
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => IhbarDetayWidget(ihbar: ihbar),
          );
        },
      ),
    );
  }
}
