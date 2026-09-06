// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MINOVA';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get continueButton => 'Continue';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get odia => 'Odia';

  @override
  String get telugu => 'Telugu';

  @override
  String get bengali => 'Bengali';

  @override
  String get marathi => 'Marathi';

  @override
  String get chhattisgarhi => 'Chhattisgarhi';

  @override
  String get santali => 'Santali';

  @override
  String get loginTitle => 'Login to MINOVA';

  @override
  String get employeeId => 'Employee / operator ID';

  @override
  String get password => 'Password';

  @override
  String get employeeIdHint => 'e.g. MS-8821';

  @override
  String get login => 'Log in';

  @override
  String get loginFailed => 'Login failed. Please check your details.';

  @override
  String get home => 'Home';

  @override
  String get report => 'REPORT';

  @override
  String get records => 'Records';

  @override
  String get profile => 'Profile';

  @override
  String get startReport => '+ START REPORT';

  @override
  String get startReportHint => 'Start an inspection or report a problem';

  @override
  String goodMorning(Object name) {
    return 'Good morning, $name';
  }

  @override
  String mine(Object name) {
    return 'Mine: $name';
  }

  @override
  String get internet => 'Internet';

  @override
  String get available => 'Available';

  @override
  String get offline => 'Internet is off';

  @override
  String get location => 'Location';

  @override
  String get underground => 'Underground';

  @override
  String get today => 'Today';

  @override
  String get reports => 'Reports';

  @override
  String get waitingToSend => 'Waiting to send';

  @override
  String get recentReports => 'Recent reports';

  @override
  String get checkingConnection =>
      'Checking connection. Your reports stay safe on this phone.';

  @override
  String get createReport => 'CREATE REPORT';

  @override
  String get selectReportType => 'Choose what you want to report.';

  @override
  String get safetyInspection => 'Statutory Safety Inspection';

  @override
  String get safetyInspectionHint => 'Check equipment, ground and ventilation';

  @override
  String get incident => 'EMERGENCY INCIDENT / ACCIDENT';

  @override
  String get incidentHint => 'Report an injury, fire, gas leak or other danger';

  @override
  String get attendance => 'Shift Attendance / Muster Roll';

  @override
  String get observation => 'Quick Observation & Gas Log';

  @override
  String get document => 'Statutory Compliance Document';

  @override
  String get autoSaveOn => 'Saved on this phone';

  @override
  String get profileSettings => 'Profile & Settings';

  @override
  String get assignedMine => 'Assigned mine';

  @override
  String get language => 'Language';

  @override
  String get operationalControls => 'Settings';

  @override
  String get undergroundMode => 'Underground mode';

  @override
  String get networkOnline => 'Internet is available';

  @override
  String get forcedOffline => 'Internet is off. Reports stay on this phone.';

  @override
  String get switchRole => 'Switch role (demo)';

  @override
  String get logout => 'Log out';

  @override
  String get reportSaved => 'Report saved on this phone.';

  @override
  String get reportSent => 'Report sent';

  @override
  String get notSent => 'Could not send. Try again when there is internet.';

  @override
  String get lockedSubmitted => 'Submitted. This report cannot be changed.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get notApplicable => 'Not applicable';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String idRole(Object id, Object role) {
    return 'ID: $id · $role';
  }

  @override
  String todayReports(Object count) {
    return '$count reports';
  }

  @override
  String waitingReports(Object count) {
    return '$count reports waiting for internet';
  }
}
