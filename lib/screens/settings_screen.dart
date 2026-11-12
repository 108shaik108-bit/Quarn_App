import 'package:flutter/material.dart';
import 'package:quran_flutter/quran_flutter.dart';

import '../services/app_settings.dart';
import 'legal_document_screen.dart';
import 'prayer_tab_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Color get background => AppSettings.isDark ? const Color(0xFF101814) : const Color(0xFFFFF5E2);
  Color get card => AppSettings.isDark ? const Color(0xFF1B2922) : const Color(0xFFFFFAEF);
  Color get green => AppSettings.isDark ? const Color(0xFF9BD0AF) : const Color(0xFF07502D);
  Color get muted => AppSettings.isDark ? const Color(0xFFB4C7BA) : const Color(0xFF52735F);
  Color get gold => AppSettings.isDark ? const Color(0xFFE0B96B) : const Color(0xFFC49A45);

  String get themeLabel {
    switch (AppSettings.themeMode.value) {
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
      case ThemeMode.system: return 'Use device setting';
    }
  }

  Future<void> _chooseTheme() async {
    final value = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choose appearance'),
        children: [
          _themeOption(ctx, ThemeMode.light, 'Light'),
          _themeOption(ctx, ThemeMode.dark, 'Dark'),
          _themeOption(ctx, ThemeMode.system, 'Use device setting'),
        ],
      ),
    );
    if (value != null) {
      await AppSettings.setThemeMode(value);
      if (mounted) setState(() {});
    }
  }

  Widget _themeOption(BuildContext ctx, ThemeMode value, String label) {
    return RadioListTile<ThemeMode>(
      value: value,
      groupValue: AppSettings.themeMode.value,
      activeColor: green,
      title: Text(label),
      onChanged: (v) => Navigator.pop(ctx, v),
    );
  }

  Future<void> _chooseLanguage() async {
    final value = await showDialog<QuranLanguage>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quran translation language'),
        content: SizedBox(
          width: 320,
          height: 420,
          child: ListView(
            children: QuranLanguage.values.map((language) => ListTile(
              title: Text(language.value),
              trailing: language == AppSettings.language.value
                  ? Icon(Icons.check_circle, color: green)
                  : null,
              onTap: () => Navigator.pop(ctx, language),
            )).toList(),
          ),
        ),
      ),
    );
    if (value != null) {
      await AppSettings.setLanguage(value);
      if (mounted) setState(() {});
    }
  }

  void _openLegal(String title, List<({String heading, String body})> sections) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => LegalDocumentScreen(title: title, sections: sections),
    ));
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: green,
        elevation: 0,
        title: Text('Settings', style: TextStyle(color: green, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _section('APP PREFERENCES'),
          _tile(Icons.palette_outlined, 'Appearance', themeLabel, _chooseTheme),
          _tile(Icons.translate_rounded, 'Quran translation', AppSettings.language.value.value, _chooseLanguage),
          const SizedBox(height: 18),
          _section('PRAYER & NOTIFICATIONS'),
          _tile(Icons.notifications_active_outlined, 'Prayer notifications & Adhan', 'Manage prayer alerts, Adhan and schedules', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PrayerTabScreen()));
          }),
          const SizedBox(height: 18),
          _section('PRIVACY & INFORMATION'),
          _tile(Icons.privacy_tip_outlined, 'Privacy Policy', 'How this app handles information', () {
            _openLegal('Privacy Policy', AppLegalContent.privacy);
          }),
          _tile(Icons.description_outlined, 'Terms of Use', 'Important terms for using the app', () {
            _openLegal('Terms of Use', AppLegalContent.terms);
          }),
          _tile(Icons.info_outline_rounded, 'About Quarn App', 'About this Quran companion', () {
            showAboutDialog(
              context: context,
              applicationName: 'Quarn App',
              applicationVersion: '1.0.0',
              applicationLegalese: 'A companion for your Quran journey.',
            );
          }),
          const SizedBox(height: 24),
          Center(child: Text('Quarn App • Version 1.0.0', style: TextStyle(color: muted, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 9, left: 4),
    child: Text(title, style: TextStyle(color: muted, fontSize: 12, letterSpacing: 1.4, fontWeight: FontWeight.bold)),
  );

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) => Card(
    color: card,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 9),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: gold.withOpacity(0.25))),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: const Color(0xFFE9EAB4), borderRadius: BorderRadius.circular(13)),
        child: Icon(icon, color: green),
      ),
      title: Text(title, style: TextStyle(color: green, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: muted, fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: gold),
    ),
  );
}
