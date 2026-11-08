import 'package:flutter/material.dart';

import '../data/surah_data.dart';
import '../data/surah_meanings.dart';
import '../data/juz_data.dart';
import '../widgets/quran_header.dart';
import '../widgets/glowing_door_card.dart';
import 'surah_reader_screen.dart';
import 'prayer_tab_screen.dart';
import 'bookmarks_screen.dart';
import 'connect_screen.dart';
import 'profile_screen.dart';
class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  String searchQuery = '';
 int selectedContentTab = 0;
  int selectedNavIndex = 0;

  static const Color cream = Color(0xFFFFF5E2);
  static const Color cardCream = Color(0xFFFFFAEF);
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
          SliverToBoxAdapter(child: QuranHeader()),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: GlowingDoorCard(
                onSearch: (value) => setState(() => searchQuery = value),
                onTabChanged: (index) {
                  setState(() {
                    selectedContentTab = index;
                    searchQuery = '';
                  });
                },
              ),
            ),
          ),

          if (selectedContentTab == 0) ...[
            if (filteredSurahs.isEmpty)
              const SliverToBoxAdapter(
                child: _EmptySearchResult(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 104,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _surahCard(filteredSurahs[index]),
                    childCount: filteredSurahs.length,
                  ),
                ),
              ),
          ] else if (selectedContentTab == 1) ...[
            if (filteredJuzNumbers.isEmpty)
              const SliverToBoxAdapter(
                child: _EmptySearchResult(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 18),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _juzCard(filteredJuzNumbers[index]),
                    childCount: filteredJuzNumbers.length,
                  ),
                ),
              ),
          ] else ...[
            const SliverToBoxAdapter(
              child: PrayerTabScreen(),
            ),
          ],

          if (selectedContentTab != 2)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                child: _continueReadingCard(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _bottomNavigationBar(),
    );
  }

  Widget _surahCard(Surah surah) {
    return Material(
      color: cardCream,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openSurah(surah),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0D8A9)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B672D).withOpacity(0.10),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
     
          children: [
            // Surah number badge
            Container(
              width: 43,
              height: 43,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE9EAB4),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${surah.number}',
                style: const TextStyle(
                  color: green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // English and Arabic names
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameArabic,
                    textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8B672D),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                 const SizedBox(height: 13),
                  Text(
                    surah.nameEnglish,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: green,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Ayah count on the right
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${surah.ayahs}',
                  style: const TextStyle(
                    color:  Color(0xFF8B672D),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Ayahs',
                  style: TextStyle(
                    color: green,
                    fontSize: 19,
                  ),
                ),
              ],
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
        border: Border.all(color: const Color(0xFFF0D8A9)),
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
                child: const Text('Read Juz', style: TextStyle(color: green)),
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
                          Text('$number', style: const TextStyle(color: green, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(surah.nameEnglish, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: green, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(meanings[number - 1], maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: mutedGreen, fontSize: 10)),
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

  Widget _continueReadingCard() {
    final firstSurah = surahs.first;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardCream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0D8A9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B672D).withOpacity(0.10),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE9EAB4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded, color: green, size: 37),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continue Reading',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: green, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Al-Fatihah  •  Start reading',
                  style: TextStyle(color: Colors.black87, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _openSurah(firstSurah),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              elevation: 3,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Resume'),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }


Widget _bottomNavigationBar() {
  const labels = ['Home', 'Connect', 'Bookmarks', 'Profile'];

  const icons = [
    Icons.home_rounded,
    Icons.favorite_border_rounded,
    Icons.bookmark_rounded,
    Icons.person_outline_rounded,
  ];

  return SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFAEF),
        border: Border(
          top: BorderSide(color: Color(0xFFE8D7B7)),
        ),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedNavIndex == index;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      if (index == 1) {
                        setState(() => selectedNavIndex = index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ConnectScreen(),
                          ),
                        ).then((_) {
                          if (mounted) {
                            setState(() => selectedNavIndex = 0);
                          }
                        });
                        return;
                      }

                      if (index == 2) {
                        setState(() => selectedNavIndex = index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BookmarksScreen(),
                          ),
                        ).then((_) {
                          if (mounted) {
                            setState(() => selectedNavIndex = 0);
                          }
                        });
                        return;
                      }

                      if (index == 3) {
                        setState(() => selectedNavIndex = index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        ).then((_) {
                          if (mounted) {
                            setState(() => selectedNavIndex = 0);
                          }
                        });
                        return;
                      }

                      if (index == 0) {
                        setState(() => selectedNavIndex = 0);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${labels[index]} section is coming soon.',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        vertical: 9,
                        horizontal: 3,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFE9EAB4)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icons[index],
                            color: selected
                                ? const Color(0xFF07502D)
                                : Colors.black87,
                            size: 29,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[index],
                            maxLines: 1,
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFF07502D)
                                  : Colors.black87,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (index != 3)
                  Container(
                    width: 1,
                    height: 52,
                    color: const Color(0xFFC49A45),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                  ),
              ],
            ),
          );
        }),
      ),
    ),
  );
}


  void _openSurah(Surah surah) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SurahReaderScreen(surah: surah)),
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
          Text('No results found', style: TextStyle(color: Color(0xFF07502D), fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Try another Surah name or number.', style: TextStyle(color: Color(0xFF52735F), fontSize: 12)),
        ],
      ),
    );
  }
}
