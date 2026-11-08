import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/surah_data.dart';
import '../services/bookmark_service.dart';
import 'bookmarks_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color cream = Color(0xFFFFF5E2);
  static const Color card = Color(0xFFFFFAEF);
  static const Color green = Color(0xFF07502D);
  static const Color mutedGreen = Color(0xFF52735F);
  static const Color gold = Color(0xFFC49A45);

  static const String _nameKey = 'profile_display_name';
  String _displayName = 'Quran Reader';
  int _bookmarkCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await BookmarkService.getBookmarks();
    if (!mounted) return;
    setState(() {
      _displayName = prefs.getString(_nameKey) ?? 'Quran Reader';
      _bookmarkCount = bookmarks.length;
      _loading = false;
    });
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: card,
        title: const Text('Your name', style: TextStyle(color: green)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 35,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: gold),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: mutedGreen)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    if (!mounted) return;
    setState(() => _displayName = name);
  }

  Future<void> _openBookmarks() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookmarksScreen()),
    );
    await _loadProfile();
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: card,
        title: Text(title, style: const TextStyle(color: green)),
        content: Text(message, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close', style: TextStyle(color: green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAyahs = surahs.fold<int>(0, (sum, item) => sum + item.ayahs);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(color: green, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: green))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: green,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: green.withOpacity(0.14),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE9EAB4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: green,
                          size: 38,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Assalamu Alaikum',
                              style: TextStyle(
                                color: Color(0xFFE9D19A),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Your Quran journey',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit name',
                        onPressed: _editName,
                        icon: const Icon(Icons.edit_outlined,
                            color: Color(0xFFE9D19A)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'MY QURAN JOURNEY',
                  style: TextStyle(
                    color: mutedGreen,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        icon: Icons.menu_book_rounded,
                        title: '114',
                        subtitle: 'Surahs',
                        tint: const Color(0xFFE9EAB4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        icon: Icons.bookmark_rounded,
                        title: '$_bookmarkCount',
                        subtitle: 'Saved ayahs',
                        tint: const Color(0xFFFCE8D8),
                        onTap: _openBookmarks,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'PERSONAL SETTINGS',
                  style: TextStyle(
                    color: mutedGreen,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _settingTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Personal information',
                  subtitle: 'Change the name shown on your profile',
                  onTap: _editName,
                ),
                _settingTile(
                  icon: Icons.location_on_outlined,
                  title: 'Prayer settings',
                  subtitle: 'Karachi method • Standard Asr (Ahl-e-Hadith)',
                  onTap: () => _showInfo(
                    'Prayer settings',
                    'Your Prayer tab currently uses the Karachi calculation method and Standard (Shafi\'i) Asr calculation. You can select your city or use GPS from the Prayer tab.',
                  ),
                ),
                _settingTile(
                  icon: Icons.translate_rounded,
                  title: 'Language',
                  subtitle: 'English translation',
                  onTap: () => _showInfo(
                    'Language',
                    'English translation is currently selected. More translation and interface language choices can be added in a future update.',
                  ),
                ),
                _settingTile(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Light theme',
                  onTap: () => _showInfo(
                    'Appearance',
                    'Quarn App currently uses its cream, emerald and gold light theme. Theme switching can be added when the app-wide theme setting is ready.',
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'ABOUT',
                  style: TextStyle(
                    color: mutedGreen,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _settingTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About Quarn App',
                  subtitle: 'A companion for your Quran journey',
                  onTap: () => _showInfo(
                    'About Quarn App',
                    'Quarn App is being built to make Quran reading and daily Islamic practice simple and beautiful.\n\nQuran text and translations are provided through the app\'s Quran data package.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Text(
                    'Version 1.0.0  •  $totalAyahs Quran ayahs',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: mutedGreen, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color tint,
    VoidCallback? onTap,
  }) {
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: green, size: 23),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: green,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: mutedGreen, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: card,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEEDFC4)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EAB4),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: green),
        ),
        title: Text(
          title,
          style: const TextStyle(color: green, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: mutedGreen, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: gold),
      ),
    );
  }
}
