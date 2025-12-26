import 'package:flutter/material.dart';
import '../models/ihbar.dart';
import '../widgets/ihbar_detay_widget.dart';

/// İhbarın tüm detaylarını tam sayfa gösteren widget
class IhbarDetaySayfasi extends StatelessWidget {
  final Ihbar ihbar;

  const IhbarDetaySayfasi({super.key, required this.ihbar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İhbar Detayı'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: IhbarDetayWidget(
          ihbar: ihbar,
          fullscreen: true, // Tam ekran modunda açıyoruz
        ),
      ),
    );
  }
}
