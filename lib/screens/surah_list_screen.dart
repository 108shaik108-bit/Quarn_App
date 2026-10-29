import 'package:flutter/material.dart';
import '../data/surah_data.dart';

class SurahListScreen extends StatelessWidget {
  const SurahListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D3B2E), // deep Islamic green
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3B2E),
        elevation: 0,
        title: const Text(
          "القرآن الكريم",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: surahs.length,
        itemBuilder: (context, index) {
          final s = surahs[index];
          return Card(
            color: const Color(0xFF14532D),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFD4AF37), // gold
                child: Text(
                  "${s.number}",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                s.nameEnglish,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "${s.ayahs} Ayahs • ${s.isMakki ? 'Makki' : 'Madani'}",
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: Text(
                s.nameArabic,
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}