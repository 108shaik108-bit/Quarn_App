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
import 'notification_centre_screen.dart';
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
          SliverToBoxAdapter(
            child: QuranHeader(
              onNotificationsTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationCentreScreen(),
                  ),
                );
              },
            ),
          ),

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
                    crossAxisCount: 1,
                    mainAxisExtent: 96,
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
    final isDark = AppSettings.isDark;
    final goldColor = isDark
        ? const Color(0xFFE0B96B)
        : const Color(0xFF9A702C);
    final textColor = isDark
        ? const Color(0xFFFFE8B0)
        : const Color(0xFF2B2116);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openSurah(surah),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF293B31), Color(0xFF17231D)]
                  : const [Color(0xFFFFF8E8), Color(0xFFF2DDAF), Color(0xFFFFF4D9)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFB99550)
                  : const Color(0xFFC49A45),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6E4B17).withOpacity(isDark ? 0.10 : 0.13),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(isDark ? 0.025 : 0.55),
                blurRadius: 1,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: goldColor.withOpacity(isDark ? 0.13 : 0.12),
                  border: Border.all(color: goldColor.withOpacity(0.75), width: 1.2),
                ),
                alignment: Alignment.center,
                child: Text(
                  surah.number.toString(),
                  style: TextStyle(
                    color: goldColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.nameArabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 21,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      surah.nameEnglish,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withOpacity(0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(width: 22, height: 1, color: goldColor.withOpacity(0.8)),
                        const SizedBox(width: 6),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            border: Border.all(color: goldColor, width: 1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(width: 22, height: 1, color: goldColor.withOpacity(0.8)),
                        const SizedBox(width: 8),
                        Text(
                          '${surah.ayahs} Ayahs',
                          style: TextStyle(
                            color: goldColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: goldColor, size: 25),
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
              crossAxisCount: 1,
              mainAxisExtent: 96,
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
                            size: 26,
                          ),
                          SizedBox(height: 4),
                          Text(
                            labels[index],
                            maxLines: 1,
                            style: TextStyle(
                              color: selected
                                  ? Color(0xFF07502D)
                                  : Colors.black87,
                              fontSize: 10.5,
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
