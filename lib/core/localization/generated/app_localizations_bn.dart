// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'MINOVA';

  @override
  String get chooseLanguage => 'আপনার ভাষা বেছে নিন';

  @override
  String get continueButton => 'এগিয়ে যান';

  @override
  String get english => 'English';

  @override
  String get hindi => 'হিন্দি';

  @override
  String get odia => 'ওড়িয়া';

  @override
  String get telugu => 'তেলুগু';

  @override
  String get bengali => 'বাংলা';

  @override
  String get marathi => 'মারাঠি';

  @override
  String get chhattisgarhi => 'ছত্তিশগড়ি';

  @override
  String get santali => 'সাঁওতালি';

  @override
  String get loginTitle => 'মাইনসেফে লগইন করুন';

  @override
  String get employeeId => 'কর্মী / অপারেটর আইডি';

  @override
  String get password => 'পাসওয়ার্ড';

  @override
  String get employeeIdHint => 'যেমন MS-8821';

  @override
  String get login => 'লগইন করুন';

  @override
  String get loginFailed => 'লগইন হয়নি। তথ্য পরীক্ষা করুন।';

  @override
  String get home => 'হোম';

  @override
  String get report => 'রিপোর্ট';

  @override
  String get records => 'রেকর্ড';

  @override
  String get profile => 'প্রোফাইল';

  @override
  String get startReport => 'রিপোর্ট শুরু করুন';

  @override
  String get startReportHint => 'পরিদর্শন শুরু করুন বা সমস্যা জানান';

  @override
  String goodMorning(Object name) {
    return 'নমস্কার, $name';
  }

  @override
  String mine(Object name) {
    return 'খনি: $name';
  }

  @override
  String get internet => 'ইন্টারনেট';

  @override
  String get available => 'চালু আছে';

  @override
  String get offline => 'ইন্টারনেট নেই';

  @override
  String get location => 'অবস্থান';

  @override
  String get underground => 'মাটির নিচে';

  @override
  String get today => 'আজ';

  @override
  String get reports => 'রিপোর্ট';

  @override
  String get waitingToSend => 'পাঠানোর অপেক্ষায়';

  @override
  String get recentReports => 'সাম্প্রতিক রিপোর্ট';

  @override
  String get checkingConnection =>
      'সংযোগ পরীক্ষা করছি। রিপোর্ট এই ফোনে নিরাপদ আছে।';

  @override
  String get createReport => 'রিপোর্ট শুরু করুন';

  @override
  String get selectReportType => 'আপনি কী জানাতে চান তা বেছে নিন।';

  @override
  String get safetyInspection => 'নিরাপত্তা পরীক্ষা';

  @override
  String get safetyInspectionHint => 'যন্ত্রপাতি, মাটি ও বাতাস পরীক্ষা করুন';

  @override
  String get incident => 'ঘটনার রিপোর্ট';

  @override
  String get incidentHint => 'আঘাত, আগুন, গ্যাস লিক বা বিপদ জানান';

  @override
  String get attendance => 'শ্রমিক উপস্থিতি';

  @override
  String get observation => 'দেখা সমস্যা';

  @override
  String get document => 'নথি';

  @override
  String get autoSaveOn => 'ফোনে সুরক্ষিত হচ্ছে';

  @override
  String get profileSettings => 'প্রোফাইল ও সেটিংস';

  @override
  String get assignedMine => 'আপনার খনি';

  @override
  String get language => 'ভাষা';

  @override
  String get operationalControls => 'সেটিংস';

  @override
  String get undergroundMode => 'মাটির নিচের মোড';

  @override
  String get networkOnline => 'ইন্টারনেট চালু আছে';

  @override
  String get forcedOffline => 'ইন্টারনেট নেই। রিপোর্ট ফোনে থাকবে।';

  @override
  String get switchRole => 'ভূমিকা বদলান (ডেমো)';

  @override
  String get logout => 'লগআউট';

  @override
  String get reportSaved => 'রিপোর্ট এই ফোনে নিরাপদ আছে।';

  @override
  String get reportSent => 'রিপোর্ট পাঠানো হয়েছে';

  @override
  String get notSent => 'পাঠানো যায়নি। ইন্টারনেট এলে আবার চেষ্টা করুন।';

  @override
  String get lockedSubmitted => 'জমা হয়েছে। এই রিপোর্ট বদলানো যাবে না।';

  @override
  String get tryAgain => 'আবার চেষ্টা করুন';

  @override
  String get yes => 'হ্যাঁ';

  @override
  String get no => 'না';

  @override
  String get notApplicable => 'প্রযোজ্য নয়';

  @override
  String get cancel => 'বাতিল';

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get close => 'বন্ধ';

  @override
  String idRole(Object id, Object role) {
    return 'আইডি: $id · $role';
  }

  @override
  String todayReports(Object count) {
    return '$countটি রিপোর্ট';
  }

  @override
  String waitingReports(Object count) {
    return '$countটি বাকি';
  }
}
