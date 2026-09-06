import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_hne.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_or.dart';
import 'app_localizations_sat.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
    Locale('hne'),
    Locale('mr'),
    Locale('or'),
    Locale('sat'),
    Locale('te'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MINOVA'**
  String get appName;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @odia.
  ///
  /// In en, this message translates to:
  /// **'Odia'**
  String get odia;

  /// No description provided for @telugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get telugu;

  /// No description provided for @bengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali'**
  String get bengali;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get marathi;

  /// No description provided for @chhattisgarhi.
  ///
  /// In en, this message translates to:
  /// **'Chhattisgarhi'**
  String get chhattisgarhi;

  /// No description provided for @santali.
  ///
  /// In en, this message translates to:
  /// **'Santali'**
  String get santali;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login to MINOVA'**
  String get loginTitle;

  /// No description provided for @employeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee / operator ID'**
  String get employeeId;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @employeeIdHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. MS-8821'**
  String get employeeIdHint;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your details.'**
  String get loginFailed;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'REPORT'**
  String get report;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @startReport.
  ///
  /// In en, this message translates to:
  /// **'+ START REPORT'**
  String get startReport;

  /// No description provided for @startReportHint.
  ///
  /// In en, this message translates to:
  /// **'Start an inspection or report a problem'**
  String get startReportHint;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String goodMorning(Object name);

  /// No description provided for @mine.
  ///
  /// In en, this message translates to:
  /// **'Mine: {name}'**
  String mine(Object name);

  /// No description provided for @internet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get internet;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Internet is off'**
  String get offline;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @underground.
  ///
  /// In en, this message translates to:
  /// **'Underground'**
  String get underground;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @waitingToSend.
  ///
  /// In en, this message translates to:
  /// **'Waiting to send'**
  String get waitingToSend;

  /// No description provided for @recentReports.
  ///
  /// In en, this message translates to:
  /// **'Recent reports'**
  String get recentReports;

  /// No description provided for @checkingConnection.
  ///
  /// In en, this message translates to:
  /// **'Checking connection. Your reports stay safe on this phone.'**
  String get checkingConnection;

  /// No description provided for @createReport.
  ///
  /// In en, this message translates to:
  /// **'CREATE REPORT'**
  String get createReport;

  /// No description provided for @selectReportType.
  ///
  /// In en, this message translates to:
  /// **'Choose what you want to report.'**
  String get selectReportType;

  /// No description provided for @safetyInspection.
  ///
  /// In en, this message translates to:
  /// **'Statutory Safety Inspection'**
  String get safetyInspection;

  /// No description provided for @safetyInspectionHint.
  ///
  /// In en, this message translates to:
  /// **'Check equipment, ground and ventilation'**
  String get safetyInspectionHint;

  /// No description provided for @incident.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY INCIDENT / ACCIDENT'**
  String get incident;

  /// No description provided for @incidentHint.
  ///
  /// In en, this message translates to:
  /// **'Report an injury, fire, gas leak or other danger'**
  String get incidentHint;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Shift Attendance / Muster Roll'**
  String get attendance;

  /// No description provided for @observation.
  ///
  /// In en, this message translates to:
  /// **'Quick Observation & Gas Log'**
  String get observation;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Statutory Compliance Document'**
  String get document;

  /// No description provided for @autoSaveOn.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone'**
  String get autoSaveOn;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileSettings;

  /// No description provided for @assignedMine.
  ///
  /// In en, this message translates to:
  /// **'Assigned mine'**
  String get assignedMine;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @operationalControls.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get operationalControls;

  /// No description provided for @undergroundMode.
  ///
  /// In en, this message translates to:
  /// **'Underground mode'**
  String get undergroundMode;

  /// No description provided for @networkOnline.
  ///
  /// In en, this message translates to:
  /// **'Internet is available'**
  String get networkOnline;

  /// No description provided for @forcedOffline.
  ///
  /// In en, this message translates to:
  /// **'Internet is off. Reports stay on this phone.'**
  String get forcedOffline;

  /// No description provided for @switchRole.
  ///
  /// In en, this message translates to:
  /// **'Switch role (demo)'**
  String get switchRole;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @reportSaved.
  ///
  /// In en, this message translates to:
  /// **'Report saved on this phone.'**
  String get reportSaved;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get reportSent;

  /// No description provided for @notSent.
  ///
  /// In en, this message translates to:
  /// **'Could not send. Try again when there is internet.'**
  String get notSent;

  /// No description provided for @lockedSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted. This report cannot be changed.'**
  String get lockedSubmitted;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @notApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable'**
  String get notApplicable;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @idRole.
  ///
  /// In en, this message translates to:
  /// **'ID: {id} · {role}'**
  String idRole(Object id, Object role);

  /// No description provided for @todayReports.
  ///
  /// In en, this message translates to:
  /// **'{count} reports'**
  String todayReports(Object count);

  /// No description provided for @waitingReports.
  ///
  /// In en, this message translates to:
  /// **'{count} reports waiting for internet'**
  String waitingReports(Object count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'hi',
    'hne',
    'mr',
    'or',
    'sat',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'hne':
      return AppLocalizationsHne();
    case 'mr':
      return AppLocalizationsMr();
    case 'or':
      return AppLocalizationsOr();
    case 'sat':
      return AppLocalizationsSat();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
