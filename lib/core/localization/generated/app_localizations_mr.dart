// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appName => 'MINOVA';

  @override
  String get chooseLanguage => 'तुमची भाषा निवडा';

  @override
  String get continueButton => 'पुढे जा';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिंदी';

  @override
  String get odia => 'ओडिया';

  @override
  String get telugu => 'तेलुगू';

  @override
  String get bengali => 'बंगाली';

  @override
  String get marathi => 'मराठी';

  @override
  String get chhattisgarhi => 'छत्तीसगढी';

  @override
  String get santali => 'संताली';

  @override
  String get loginTitle => 'माइनसेफमध्ये लॉगिन करा';

  @override
  String get employeeId => 'कर्मचारी / ऑपरेटर आयडी';

  @override
  String get password => 'पासवर्ड';

  @override
  String get employeeIdHint => 'उदा. MS-8821';

  @override
  String get login => 'लॉगिन करा';

  @override
  String get loginFailed => 'लॉगिन झाले नाही. माहिती तपासा.';

  @override
  String get home => 'मुख्यपृष्ठ';

  @override
  String get report => 'अहवाल';

  @override
  String get records => 'नोंदी';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get startReport => 'अहवाल सुरू करा';

  @override
  String get startReportHint => 'तपासणी सुरू करा किंवा समस्या कळवा';

  @override
  String goodMorning(Object name) {
    return 'नमस्कार, $name';
  }

  @override
  String mine(Object name) {
    return 'खाण: $name';
  }

  @override
  String get internet => 'इंटरनेट';

  @override
  String get available => 'उपलब्ध';

  @override
  String get offline => 'इंटरनेट नाही';

  @override
  String get location => 'स्थान';

  @override
  String get underground => 'भूमिगत';

  @override
  String get today => 'आज';

  @override
  String get reports => 'अहवाल';

  @override
  String get waitingToSend => 'पाठवायचे बाकी';

  @override
  String get recentReports => 'अलीकडील अहवाल';

  @override
  String get checkingConnection =>
      'कनेक्शन तपासत आहोत. अहवाल या फोनमध्ये सुरक्षित आहे.';

  @override
  String get createReport => 'अहवाल सुरू करा';

  @override
  String get selectReportType => 'तुम्हाला काय नोंदवायचे आहे ते निवडा.';

  @override
  String get safetyInspection => 'सुरक्षा तपासणी';

  @override
  String get safetyInspectionHint => 'उपकरणे, जमीन आणि हवा तपासा';

  @override
  String get incident => 'घटनेचा अहवाल';

  @override
  String get incidentHint => 'दुखापत, आग, गॅस गळती किंवा धोका कळवा';

  @override
  String get attendance => 'कामगार उपस्थिती';

  @override
  String get observation => 'दिसलेली समस्या';

  @override
  String get document => 'कागदपत्र';

  @override
  String get autoSaveOn => 'फोनमध्ये सुरक्षित होत आहे';

  @override
  String get profileSettings => 'प्रोफाइल आणि सेटिंग्ज';

  @override
  String get assignedMine => 'तुमची खाण';

  @override
  String get language => 'भाषा';

  @override
  String get operationalControls => 'सेटिंग्ज';

  @override
  String get undergroundMode => 'भूमिगत मोड';

  @override
  String get networkOnline => 'इंटरनेट उपलब्ध आहे';

  @override
  String get forcedOffline => 'इंटरनेट नाही. अहवाल फोनमध्ये राहील.';

  @override
  String get switchRole => 'भूमिका बदला (डेमो)';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get reportSaved => 'अहवाल या फोनमध्ये सुरक्षित आहे.';

  @override
  String get reportSent => 'अहवाल पाठवला';

  @override
  String get notSent => 'पाठवता आले नाही. इंटरनेट आल्यावर पुन्हा प्रयत्न करा.';

  @override
  String get lockedSubmitted => 'सादर झाले. हा अहवाल बदलता येणार नाही.';

  @override
  String get tryAgain => 'पुन्हा प्रयत्न करा';

  @override
  String get yes => 'होय';

  @override
  String get no => 'नाही';

  @override
  String get notApplicable => 'लागू नाही';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get save => 'जतन करा';

  @override
  String get close => 'बंद करा';

  @override
  String idRole(Object id, Object role) {
    return 'आयडी: $id · $role';
  }

  @override
  String todayReports(Object count) {
    return '$count अहवाल';
  }

  @override
  String waitingReports(Object count) {
    return '$count बाकी';
  }
}
