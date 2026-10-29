/// Privacy policy content for Homeledger.
///
/// Plain-English disclosure of data practices for offline Android use.
/// Must never include regulatory forbidden claim words.
library;

const String kPrivacyContactEmail = 'REPLACE_BEFORE_RELEASE';
const String kPrivacyPolicyLastUpdated = 'October 23, 2026';

class PrivacySection {
  final String heading;
  final String body;

  const PrivacySection({
    required this.heading,
    required this.body,
  });
}

const List<PrivacySection> kPrivacyPolicySections = [
  PrivacySection(
    heading: 'Storage on this device only',
    body:
        'Homeledger stores everything on this phone only. There is no account, no server, no analytics, and no ads.',
  ),
  PrivacySection(
    heading: 'No network transmission',
    body:
        'Nothing is sent anywhere by the app. Your information stays on your device.',
  ),
  PrivacySection(
    heading: 'Camera access',
    body:
        'The camera is used only when you scan a work sample. Pictures stay on this phone.',
  ),
  PrivacySection(
    heading: 'Backups and exports',
    body:
        'Backup files and PDF portfolios are created only when you tap Back up now or Create PDF. They leave the phone only through the Android share sheet and only to the app you choose.',
  ),
  PrivacySection(
    heading: 'No automatic cloud backup',
    body:
        'Because Android automatic backup is turned off, if you delete the app or lose the phone, your data is gone unless you made your own backup file.',
  ),
  PrivacySection(
    heading: 'Parents and carers only',
    body:
        'The app is for parents and carers. It does not ask children for any information.',
  ),
  PrivacySection(
    heading: 'How to delete your data',
    body:
        'How to delete your data: delete a child in Settings, or uninstall the app.',
  ),
  PrivacySection(
    heading: 'Contact',
    body:
        'If you have questions about this policy, contact $kPrivacyContactEmail.',
  ),
  PrivacySection(
    heading: 'Last updated',
    body:
        'Last updated: $kPrivacyPolicyLastUpdated. This is a records tool and not legal advice.',
  ),
];
