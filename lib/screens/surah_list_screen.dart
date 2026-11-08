import 'package:flutter/material.dart';

import '../data/surah_data.dart';
import '../data/surah_meanings.dart';
import '../data/juz_data.dart';
import '../widgets/quran_header.dart';
import '../widgets/glowing_door_card.dart';
import 'surah_reader_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  String searchQuery = '';
  bool showSurahs = true;

  static const Color cream = Color(0xFFFFF7E9);
  static const Color cardCream = Color(0xFFFFFCF5);
  static const Color green = Color(0xFF07502D);
  static const Color mutedGreen = Color(0xFF52735F);
  static const Color gold = Color(0xFFC49A45);

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();

    final filteredSurahs = surahs.where((surah) {
      return surah.nameEnglish.toLowerCase().contains(query) ||
          surah.nameArabic.contains(searchQuery.trim()) ||
          '${surah.number}'.contains(query);
    }).toList();

    final filteredJuzNumbers = List.generate(30, (index) => index + 1)
        .where((juz) {
      if (query.isEmpty) return true;
      return juzSurahs[juz - 1].any((number) {
        final surah = surahs[number - 1];
        return surah.nameEnglish.toLowerCase().contains(query) ||
            surah.nameArabic.contains(searchQuery.trim()) ||
            '$number'.contains(query);
      });
    }).toList();

    return Scaffold(
      backgroundColor: cream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: QuranHeader(),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: GlowingDoorCard(
                onSearch: (value) {
                  setState(() => searchQuery = value);
                },
                onTabChanged: (isSurah) {
                  setState(() => showSurahs = isSurah);
                },
              ),
            ),
          ),

          if (showSurahs)
            if (filteredSurahs.isEmpty)
              const SliverToBoxAdapter(
                child: _EmptySearchResult(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 112,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _surahCard(filteredSurahs[index]),
                    childCount: filteredSurahs.length,
                  ),
                ),
              )
          else
            if (filteredJuzNumbers.isEmpty)
              const SliverToBoxAdapter(
                child: _EmptySearchResult(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _juzCard(filteredJuzNumbers[index]),
                    childCount: filteredJuzNumbers.length,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _surahCard(Surah surah) {
    return Material(
      color: cardCream,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openSurah(surah),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9DCC2)),
            boxShadow: [
              BoxShadow(
                color: green.withOpacity(0.045),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 29,
                    height: 29,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1E9),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${surah.number}',
                      style: const TextStyle(
                        color: green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      surah.nameArabic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: green,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                surah.nameEnglish,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${surah.ayahs} Ayahs  •  ${surah.isMakki ? 'Makki' : 'Madani'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: mutedGreen, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _juzCard(int juzNumber) {
    final surahNumbers = juzSurahs[juzNumber - 1];
    final chipWidth = (MediaQuery.of(context).size.width - 64) / 2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9DCC2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Juz $juzNumber',
                style: const TextStyle(
                  color: green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: surahNumbers.isEmpty
                    ? null
                    : () => _openSurah(surahs[surahNumbers.first - 1]),
                child: const Text(
                  'Read Juz',
                  style: TextStyle(color: green, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: surahNumbers.map((number) {
              final surah = surahs[number - 1];
              return SizedBox(
                width: chipWidth,
                child: Material(
                  color: const Color(0xFFF4F0E5),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _openSurah(surah),
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: Row(
                        children: [
                          Text(
                            '$number',
                            style: const TextStyle(
                              color: green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  surah.nameEnglish,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  meanings[number - 1],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: mutedGreen,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _openSurah(Surah surah) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurahReaderScreen(surah: surah),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.search_off, color: Color(0xFF52735F), size: 38),
          SizedBox(height: 10),
          Text(
            'No results found',
            style: TextStyle(
              color: Color(0xFF07502D),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try another Surah name or number.',
            style: TextStyle(color: Color(0xFF52735F), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
