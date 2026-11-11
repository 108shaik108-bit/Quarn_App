import 'package:flutter/material.dart';

import '../services/app_settings.dart';
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

  static Color get cream => AppSettings.isDark ? Color(0xFF101814) : Color(0xFFFFF5E2);
  static Color get cardCream => AppSettings.isDark ? Color(0xFF1B2922) : Color(0xFFFFFAEF);
  static Color get green => AppSettings.isDark ? Color(0xFF9BD0AF) : Color(0xFF07502D);
  static Color get mutedGreen => AppSettings.isDark ? Color(0xFFB4C7BA) : Color(0xFF52735F);
  static Color get gold => AppSettings.isDark ? Color(0xFFE0B96B) : Color(0xFFC49A45);

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Rebuild this screen when the app theme changes.
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
              SliverToBoxAdapter(
                child: _EmptySearchResult(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
              ),
          ] else if (selectedContentTab == 1) ...[
            if (filteredJuzNumbers.isEmpty)
              SliverToBoxAdapter(
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
            SliverToBoxAdapter(
              child: PrayerTabScreen(),
            ),
          ],

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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              // Compact Surah number badge.
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9EAB4),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${surah.number}',
                  style: TextStyle(
                    color: green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Keep both Surah names visible in the available card width.
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      surah.nameArabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: green,
                        fontSize: 17,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      surah.nameEnglish,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: green,
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Smaller Ayah count so it does not squeeze out the names.
              SizedBox(
                width: 42,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${surah.ayahs}',
                      maxLines: 1,
                      style: TextStyle(
                        color: const Color(0xFF8B672D),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ayahs',
                      maxLines: 1,
                      style: TextStyle(
                        color: green,
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _juzCard(int juzNumber) {
    final surahNumbers = juzSurahs[juzNumber - 1];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardCream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0D8A9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text(
                  'Juz $juzNumber',
                  style: TextStyle(
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
                  child: Text('Read Juz', style: TextStyle(color: green)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (surahNumbers.isNotEmpty)
            GridView.count(
              crossAxisCount: 2,
              mainAxisExtent: 112,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: surahNumbers
                  .map((number) => _surahCard(surahs[number - 1]))
                  .toList(),
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
      decoration: BoxDecoration(
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
                            builder: (_) => ConnectScreen(),
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
                            builder: (_) => BookmarksScreen(),
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
                            builder: (_) => ProfileScreen(),
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
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        vertical: 9,
                        horizontal: 3,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Color(0xFFE9EAB4)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icons[index],
                            color: selected
                                ? Color(0xFF07502D)
                                : Colors.black87,
                            size: 29,
                          ),
                          SizedBox(height: 4),
                          Text(
                            labels[index],
                            maxLines: 1,
                            style: TextStyle(
                              color: selected
                                  ? Color(0xFF07502D)
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
                    color: Color(0xFFC49A45),
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
    return Padding(
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
