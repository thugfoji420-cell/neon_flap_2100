import 'package:flutter/foundation.dart';

import 'package:neon_flap1_game/core/constants/app_constants.dart';

@immutable
class LegalSection {
  const LegalSection({
    required this.heading,
    required this.body,
  });

  final String heading;
  final String body;
}

@immutable
class LegalDocument {
  const LegalDocument({
    required this.id,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final String id;
  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;
}

class LegalDocuments {
  const LegalDocuments._();

  static const privacyPolicy = LegalDocument(
    id: 'privacy',
    title: 'Privacy Policy',
    lastUpdated: 'July 20, 2026',
    sections: [
      LegalSection(
        heading: 'Overview',
        body:
            'Neon Flap 2100 is developed by Nexora Studios. This policy explains how the game handles data for offline guest play, Google Sign-In, Firebase cloud features, leaderboards, ads, purchases, and local settings.',
      ),
      LegalSection(
        heading: 'Guest Mode',
        body:
            'You can play without an account. Guest progress, player name, coins, selected character, owned characters, settings, achievements, local scores, and daily reward state are stored on this device using local storage. Guest data is not sent to Firebase unless you choose Sign in to Sync.',
      ),
      LegalSection(
        heading: 'Google Sign-In and Firebase',
        body:
            'If you sign in with Google, Firebase Authentication identifies your account. The game may store your chosen username, profile progress, coins, high score, selected character, owned characters, achievements, daily reward state, settings, cloud save data, and leaderboard rows in Cloud Firestore.',
      ),
      LegalSection(
        heading: 'Leaderboards and Cloud Save',
        body:
            'Online leaderboards display your player name, score, coin total, selected character, and leaderboard period. Cloud save keeps account progress available for the signed-in Google account. Offline guests use local personal progress only.',
      ),
      LegalSection(
        heading: 'Ads and Rewarded Ads',
        body:
            'The game uses Google AdMob. AdMob may process advertising identifiers, device information, approximate location, diagnostics, and ad interaction data according to Google policies. Rewarded-ad bonuses are granted only after the ad completion callback succeeds.',
      ),
      LegalSection(
        heading: 'Analytics and Crash Reporting',
        body:
            'The project includes Firebase and Crashlytics dependencies. When enabled by the app build and platform services, diagnostic data may be used to improve stability and investigate crashes. Technical failures are logged without intentionally exposing private data in the game UI.',
      ),
      LegalSection(
        heading: 'Purchases and Virtual Items',
        body:
            'Coins and character unlocks are game items. They have no cash value. Google account progress may sync character ownership and coin balances; guest progress stays on the device unless synchronized.',
      ),
      LegalSection(
        heading: 'Children’s Privacy',
        body:
            'The game is not designed to knowingly collect personal information from children beyond the platform services used for sign-in, ads, purchases, or diagnostics. If you believe a child provided personal data, contact us so we can review deletion options.',
      ),
      LegalSection(
        heading: 'Security and Retention',
        body:
            'We use Firebase and platform services to protect account data. No system can be guaranteed perfectly secure. Guest data remains until you delete the app, clear app storage, or use the local deletion option. Cloud data remains until deleted through account deletion or normal retention processes.',
      ),
      LegalSection(
        heading: 'Your Choices',
        body:
            'You may play as a guest, sign in with Google, change your player name, delete local guest data, or request account/cloud data deletion. You can also control app permissions and ad personalization through your device and Google settings.',
      ),
      LegalSection(
        heading: 'Contact',
        body:
            'For privacy requests, contact Nexora Studios at [Support Email]. Legal entity: [Developer Legal Name]. Country/region: [Country].',
      ),
      LegalSection(
        heading: 'Updates',
        body:
            'We may update this policy as Neon Flap 2100 changes. The latest in-app version applies from its last-updated date. App version: ${AppConstants.appVersion}.',
      ),
    ],
  );

  static const termsOfService = LegalDocument(
    id: 'terms',
    title: 'Terms of Service',
    lastUpdated: 'July 20, 2026',
    sections: [
      LegalSection(
        heading: 'Acceptance',
        body:
            'By playing Neon Flap 2100, you agree to these terms. If you do not agree, do not use the game.',
      ),
      LegalSection(
        heading: 'Accounts and Guest Play',
        body:
            'You may play as an offline guest or sign in with Google for cloud features. You are responsible for activity on your account and for keeping access to your Google account secure.',
      ),
      LegalSection(
        heading: 'Usernames',
        body:
            'Player names must follow the game validation rules. We may reject, reset, or remove usernames that impersonate others, are abusive, misleading, or violate platform rules.',
      ),
      LegalSection(
        heading: 'License',
        body:
            'Nexora Studios grants you a limited, revocable, non-transferable license to play the game for personal entertainment. You may not copy, sell, reverse engineer, or exploit the game except where allowed by law.',
      ),
      LegalSection(
        heading: 'Fair Play',
        body:
            'Do not cheat, manipulate leaderboards, abuse rewards, automate gameplay, tamper with local saves, attack services, or interfere with other players.',
      ),
      LegalSection(
        heading: 'Coins, Characters, Rewards, and Purchases',
        body:
            'Virtual coins, rewarded-ad bonuses, character unlocks, and similar items are for in-game use only and have no real-money value. Reward availability, pricing, and balance may change for tuning, fraud prevention, or service reasons.',
      ),
      LegalSection(
        heading: 'Ads',
        body:
            'The game may show banner, interstitial, app-open, and rewarded ads. Rewarded bonuses require successful ad completion. If an ad fails, normal gameplay rewards remain available where supported.',
      ),
      LegalSection(
        heading: 'Service Availability',
        body:
            'Offline gameplay is supported, but online features such as Google Sign-In, global leaderboards, cloud save, purchases, and ads depend on third-party services and internet connectivity. Services may be unavailable or change.',
      ),
      LegalSection(
        heading: 'Intellectual Property',
        body:
            'Neon Flap 2100, its code, UI, characters, visuals, audio arrangement, and branding are owned by Nexora Studios or their respective licensors.',
      ),
      LegalSection(
        heading: 'Suspension and Termination',
        body:
            'We may restrict or terminate access to online features if we detect abuse, cheating, unlawful conduct, or violations of these terms. You may stop using the game at any time.',
      ),
      LegalSection(
        heading: 'Disclaimers and Liability',
        body:
            'The game is provided “as is” without warranties to the fullest extent permitted by law. Nexora Studios is not liable for indirect, incidental, or consequential damages where such limits are allowed.',
      ),
      LegalSection(
        heading: 'Governing Law and Contact',
        body:
            'Governing law: [Country]. Contact: [Support Email]. Legal entity: [Developer Legal Name].',
      ),
    ],
  );

  static const dataDeletion = LegalDocument(
    id: 'data_deletion',
    title: 'Data Deletion Instructions',
    lastUpdated: 'July 20, 2026',
    sections: [
      LegalSection(
        heading: 'Guest Data',
        body:
            'Guest data is stored only on this device. You can delete it from this page using Delete Local Guest Data, or by clearing app storage/uninstalling the game. This removes local guest progress and does not affect a Google account.',
      ),
      LegalSection(
        heading: 'Google Account and Cloud Data',
        body:
            'Signed-in users can request in-app deletion of account-linked records. The app attempts to remove user-owned documents including players, leaderboard, leaderboard_weekly, leaderboard_monthly, cloud_save, inventory, achievements, daily_rewards, settings, and the username index where available.',
      ),
      LegalSection(
        heading: 'Recent Sign-In Requirement',
        body:
            'Firebase may require recent Google authentication before deleting the Authentication account. If re-authentication is cancelled or fails, cloud deletion may not complete.',
      ),
      LegalSection(
        heading: 'Support Requests',
        body:
            'If in-app deletion is unavailable, contact Nexora Studios at [Support Email] with your player name and Google account details needed to identify the account. Do not send passwords.',
      ),
      LegalSection(
        heading: 'Limits',
        body:
            'Deletion applies to Neon Flap 2100 data controlled by this app. Third-party services such as Google, AdMob, Google Play, or device backups may keep records according to their own policies.',
      ),
    ],
  );
}
