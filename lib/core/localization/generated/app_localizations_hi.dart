// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'MINOVA';

  @override
  String get chooseLanguage => 'अपनी भाषा चुनें';

  @override
  String get continueButton => 'आगे बढ़ें';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिंदी';

  @override
  String get odia => 'ओडिया';

  @override
  String get telugu => 'तेलुगु';

  @override
  String get bengali => 'बंगाली';

  @override
  String get marathi => 'मराठी';

  @override
  String get chhattisgarhi => 'छत्तीसगढ़ी';

  @override
  String get santali => 'संताली';

  @override
  String get loginTitle => 'माइनसेफ में लॉगिन करें';

  @override
  String get employeeId => 'कर्मचारी / ऑपरेटर आईडी';

  @override
  String get password => 'पासवर्ड';

  @override
  String get employeeIdHint => 'जैसे MS-8821';

  @override
  String get login => 'लॉगिन करें';

  @override
  String get loginFailed => 'लॉगिन नहीं हुआ। अपनी जानकारी जाँचें।';

  @override
  String get home => 'होम';

  @override
  String get report => 'रिपोर्ट';

  @override
  String get records => 'रिकॉर्ड';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get startReport => 'रिपोर्ट शुरू करें';

  @override
  String get startReportHint => 'जाँच शुरू करें या समस्या बताएँ';

  @override
  String goodMorning(Object name) {
    return 'नमस्ते, $name';
  }

  @override
  String mine(Object name) {
    return 'खदान: $name';
  }

  @override
  String get internet => 'इंटरनेट';

  @override
  String get available => 'उपलब्ध';

  @override
  String get offline => 'इंटरनेट नहीं है';

  @override
  String get location => 'लोकेशन';

  @override
  String get underground => 'जमीन के नीचे';

  @override
  String get today => 'आज';

  @override
  String get reports => 'रिपोर्ट';

  @override
  String get waitingToSend => 'भेजने के लिए बाकी';

  @override
  String get recentReports => 'हाल की रिपोर्ट';

  @override
  String get checkingConnection =>
      'कनेक्शन देख रहे हैं। आपकी रिपोर्ट इस फोन में सुरक्षित है।';

  @override
  String get createReport => 'रिपोर्ट शुरू करें';

  @override
  String get selectReportType => 'बताएँ कि आपको क्या दर्ज करना है।';

  @override
  String get safetyInspection => 'सुरक्षा जाँच';

  @override
  String get safetyInspectionHint => 'उपकरण, जमीन और हवा की जाँच करें';

  @override
  String get incident => 'घटना की रिपोर्ट';

  @override
  String get incidentHint => 'चोट, आग, गैस रिसाव या खतरे की जानकारी दें';

  @override
  String get attendance => 'कामगार उपस्थिति';

  @override
  String get observation => 'देखी गई समस्या';

  @override
  String get document => 'दस्तावेज़';

  @override
  String get autoSaveOn => 'फोन में सुरक्षित हो रहा है';

  @override
  String get profileSettings => 'प्रोफ़ाइल और सेटिंग्स';

  @override
  String get assignedMine => 'आपकी खदान';

  @override
  String get language => 'भाषा';

  @override
  String get operationalControls => 'सेटिंग्स';

  @override
  String get undergroundMode => 'जमीन के नीचे का मोड';

  @override
  String get networkOnline => 'इंटरनेट उपलब्ध है';

  @override
  String get forcedOffline => 'इंटरनेट नहीं है। रिपोर्ट फोन में सुरक्षित है।';

  @override
  String get switchRole => 'भूमिका बदलें (डेमो)';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get reportSaved => 'रिपोर्ट इस फोन में सुरक्षित है।';

  @override
  String get reportSent => 'रिपोर्ट भेज दी गई';

  @override
  String get notSent =>
      'रिपोर्ट नहीं भेजी जा सकी। इंटरनेट आने पर फिर कोशिश करें।';

  @override
  String get lockedSubmitted =>
      'रिपोर्ट जमा हो गई। अब बदलाव नहीं किया जा सकता।';

  @override
  String get tryAgain => 'फिर कोशिश करें';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get notApplicable => 'लागू नहीं';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get close => 'बंद करें';

  @override
  String idRole(Object id, Object role) {
    return 'आईडी: $id · $role';
  }

  @override
  String todayReports(Object count) {
    return '$count रिपोर्ट';
  }

  @override
  String waitingReports(Object count) {
    return '$count बाकी';
  }
}
