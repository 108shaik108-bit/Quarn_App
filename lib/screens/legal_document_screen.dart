import 'package:flutter/material.dart';

import '../services/app_settings.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.title, required this.sections});

  final String title;
  final List<({String heading, String body})> sections;

  @override
  Widget build(BuildContext context) {
    final dark = AppSettings.isDark;
    final background = dark ? const Color(0xFF101814) : const Color(0xFFFFF5E2);
    final textColor = dark ? const Color(0xFFE7EFE9) : const Color(0xFF263B2E);
    final accent = dark ? const Color(0xFF9BD0AF) : const Color(0xFF07502D);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: background,
        foregroundColor: accent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Quarn App • Last updated: 9 November 2026',
              style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          for (final section in sections) ...[
            Text(section.heading,
                style: TextStyle(color: accent, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(section.body,
                style: TextStyle(color: textColor, height: 1.55, fontSize: 14)),
            const SizedBox(height: 18),
          ],
          SelectableText('Contact: 108shaik@gmail.com',
              style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class AppLegalContent {
  static const privacy = <({String heading, String body})>[
    (heading: 'Overview', body: 'Quarn App is designed to keep profile details and reading preferences on your device. The current version does not provide user accounts or a developer-operated cloud profile.'),
    (heading: 'Information stored on your device', body: 'The app may store your display name, Quran ayah bookmarks, reading progress and streak, selected translation language, appearance preference, prayer location choice and coordinates, and Adhan preferences. These are stored locally using device app storage and are not currently sent to a Quarn App server.'),
    (heading: 'Location', body: 'If you choose GPS location, the app requests device location permission and uses coordinates to calculate local prayer times and Qibla direction. You can choose a city manually instead. Location is not required to read the Quran. The selected coordinates are stored on your device to remember your choice and support prayer alarm scheduling. You can revoke permission in device settings.'),
    (heading: 'Notifications and audio', body: 'Ring Adhan is off by default. If enabled, the app may request notification and exact-alarm permissions and schedule prayer-time alarms on your device. Included Adhan audio is played for previews or scheduled alarms. Microphone access is not needed.'),
    (heading: 'Sharing and third parties', body: 'The current version has no developer-operated account system, advertising SDK, analytics SDK, or backend receiving locally stored profile, bookmark, reading-progress, or location information. The app relies on operating-system and Flutter package services for location, compass, audio, alarms, notifications, and local storage. If analytics, ads, crash reporting, cloud sync, or other network services are added, this policy and the Play Console Data safety declaration must be updated.'),
    (heading: 'Retention and deletion', body: 'Locally stored information remains on your device until you clear it using Clear My Local Data, clear app storage, or uninstall the app. This can remove your name, bookmarks, reading progress, settings, and saved location. The in-app clear-data action also cancels scheduled Adhan alarms.'),
    (heading: 'Children and security', body: 'The app does not knowingly collect children’s personal information through a developer-operated account or server. Local information is protected according to your device and operating system; keep your device updated and secured.'),
    (heading: 'Changes', body: 'This policy may change as features and data practices change. The public policy page should be updated whenever the app’s practices change.'),
  ];

  static const terms = <({String heading, String body})>[
    (heading: 'Purpose', body: 'Quarn App is an informational Quran and Islamic-practice companion. It is not a substitute for qualified religious scholarship, professional advice, or authoritative local guidance.'),
    (heading: 'Quran text and translations', body: 'We aim to present Quran text and translations carefully. Translation wording may differ between translators and editions. Consult trusted scholars and recognized sources where interpretation or religious rulings matter. Please report apparent content errors.'),
    (heading: 'Prayer times', body: 'Prayer times are calculated from your selected location and calculation settings. They may differ from local mosque timetables because of calculation methods, settings, rounding, altitude, location accuracy, or local practice. Verify important prayer times with a trusted local mosque or authority.'),
    (heading: 'Qibla direction', body: 'Qibla direction depends on accurate location and device compass sensors. Magnetic interference and sensor calibration can affect readings. Treat the displayed direction as a guide and verify it when necessary.'),
    (heading: 'Adhan alarms', body: 'Adhan alarms are optional and disabled by default. Delivery and sound depend on permissions, battery settings, operating-system restrictions, and device hardware. We cannot guarantee an alarm will always trigger at the exact time or in every condition.'),
    (heading: 'Acceptable use and availability', body: 'Use the app for lawful personal purposes. Do not misuse or disrupt it or infringe others’ rights. Features may change or be discontinued. We aim for reliable service but do not guarantee uninterrupted or error-free operation.'),
    (heading: 'Disclaimer', body: 'The app is provided on an “as is” and “as available” basis to the extent permitted by law. Nothing in these terms excludes rights or liabilities that cannot legally be excluded.'),
  ];
}
