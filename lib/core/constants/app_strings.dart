/// Al Arsh — Arabic String Constants
/// All UI strings centralized for easy localization
abstract class AppStrings {
  // ── App ────────────────────────────────────
  static const String appName        = 'ZUVOXA';
  static const String appTagline     = 'نافس. إبدع. تألّق.';

  // ── Auth ───────────────────────────────────
  static const String enterEmail         = 'أدخل بريدك الإلكتروني';
  static const String emailHint          = 'example@domain.com';
  static const String enterPassword      = 'كلمة المرور'; // security-ignore-line
  static const String passwordHint       = 'أدخل كلمة المرور (6 أحرف على الأقل)';
  static const String login              = 'تسجيل الدخول';
  static const String signUp             = 'إنشاء حساب';
  static const String dontHaveAccount    = 'ليس لديك حساب؟ إنشاء حساب';
  static const String alreadyHaveAccount = 'لديك حساب؟ تسجيل الدخول';
  static const String passwordTooShort   = 'كلمة المرور قصيرة (6 أحرف على الأقل)';
  static const String emailRequired      = 'أدخل البريد الإلكتروني';
  static const String emailInvalid       = 'بريد إلكتروني غير صحيح';
  static const String setupUsername      = 'إنشاء حسابك';
  static const String chooseUsername     = 'اختر اسم المستخدم';
  static const String usernameHint       = 'username_ar';
  static const String displayNameLabel   = 'الاسم المعروض';
  static const String displayNameHint    = 'اسمك في التطبيق';
  static const String addPhoto           = 'إضافة صورة';
  static const String skipForNow         = 'تخطي الآن';
  static const String createAccount      = 'إنشاء الحساب';
  static const String usernameExists     = 'اسم المستخدم محجوز';
  static const String usernameInvalid    = 'يجب أن يحتوي على أحرف وأرقام فقط';
  static const String usernameTooShort   = 'يجب أن يكون 3 أحرف على الأقل';

  // ── Navigation ─────────────────────────────
  static const String navHome            = 'الرئيسية';
  static const String navRankings        = 'التصنيفات';
  static const String navUpload          = 'نشر';
  static const String navWinners         = 'المشاهير';
  static const String navProfile         = 'حسابي';

  // ── Feed ───────────────────────────────────
  static const String weeklyFeed         = 'منشورات الأسبوع';
  static const String voteNow            = 'صوّت';
  static const String voted              = 'صوّتت';
  static const String views              = 'مشاهدة';
  static const String votingClosed       = 'انتهى التصويت';
  static const String pullToRefresh      = 'اسحب للتحديث';
  static const String noPostsYet         = 'لا توجد منشورات بعد';
  static const String beFirst            = 'كن أول من ينشر هذا الأسبوع!';
  static const String anonymousPrefix    = 'منشئ #';

  // ── Upload ─────────────────────────────────
  static const String uploadPost         = 'نشر محتوى';
  static const String chooseMedia        = 'اختر صورة أو فيديو';
  static const String addCaption         = 'أضف وصفاً (اختياري)';
  static const String captionHint        = 'شاركنا فكرتك...';
  static const String selectCategory     = 'اختر الفئة';
  static const String uploadProgress     = 'جارٍ الرفع...';
  static const String submitting         = 'جارٍ النشر...';
  static const String publishPost        = 'نشر';
  static const String videoTooLong       = 'الفيديو يجب أن يكون أقل من 60 ثانية';
  static const String uploading          = 'جارٍ الرفع...';
  static const String uploadSuccess      = 'تم نشر المحتوى بنجاح!';
  static const String uploadFailed       = 'فشل النشر، حاول مجدداً';

  // ── Categories ─────────────────────────────
  static const List<String> categories = [
    'موهبة', 'كوميديا', 'تجارة', 'تحدي', 'فكرة', 'أخرى'
  ];

  // ── Rankings ───────────────────────────────
  static const String rankingsTitle      = 'التصنيفات الأسبوعية';
  static const String tierBlueLabel      = 'دوري الصاعدين';
  static const String tierGoldLabel      = 'دوري النخبة';
  static const String tierRedLabel       = 'دوري الملوك';
  static const String votingClosesIn     = 'ينتهي التصويت بعد';
  static const String announcementIn     = 'الإعلان عن الفائزين بعد';
  static const String rank               = 'المركز';
  static const String score              = 'النقاط';

  // ── Winners Hall ───────────────────────────
  static const String winnersHall        = 'قاعة المشاهير';
  static const String weekWinner         = 'بطل الأسبوع';
  static const String week               = 'الأسبوع';
  static const String noWinnersYet       = 'لا يوجد فائزون بعد';

  // ── Profile ────────────────────────────────
  static const String myProfile          = 'حسابي';
  static const String totalPosts         = 'منشور';
  static const String totalVotes         = 'تصويت';
  static const String streakDays         = 'يوم متتالي';
  static const String bestRank           = 'أفضل مركز';
  static const String editProfile        = 'تعديل الملف';
  static const String myPosts            = 'منشوراتي';
  static const String levelProgress      = 'التقدم للمستوى التالي';
  static const String saveChanges        = 'حفظ التغييرات';

  // ── Notifications ──────────────────────────
  static const String notifications      = 'الإشعارات';
  static const String markAllRead        = 'تحديد الكل كمقروء';
  static const String noNotifications    = 'لا توجد إشعارات';
  static const String notifVoteReceived  = 'حصلت على تصويت!';
  static const String notifWeekWinner    = 'أنت بطل الأسبوع! 🎉';
  static const String notifLevelUp       = 'ترقية المستوى! ⬆️';
  static const String notifStreak        = 'سلسلة يومية! 🔥';

  // ── Admin ──────────────────────────────────
  static const String adminPanel         = 'لوحة الإدارة';
  static const String totalUsers         = 'مستخدمون';
  static const String activeWeek         = 'الأسبوع الحالي';
  static const String recalculateScores  = 'إعادة حساب النقاط';
  static const String announceWinners    = 'إعلان الفائزين';
  static const String reportedPosts      = 'منشورات مبلغ عنها';
  static const String banPost            = 'حظر';
  static const String keepPost           = 'إبقاء';
  static const String createWeek         = 'إنشاء أسبوع جديد';

  // ── Levels ─────────────────────────────────
  static const Map<String, String> levelDescriptions = {
    'مجهول'  : 'مستوى البداية',
    'موهبة'  : '100 تصويت أو 7 أيام متتالية',
    'صاعد'   : '500 تصويت أو فوز في الدوري الأزرق',
    'نجم'    : '2000 تصويت أو فوز في دوري النخبة',
    'ملك'    : 'فوز في دوري الملوك',
    'أسطورة' : '3 انتصارات في دوري الملوك',
  };

  // ── Errors ─────────────────────────────────
  static const String genericError      = 'حدث خطأ، يرجى المحاولة مجدداً';
  static const String networkError      = 'تحقق من اتصالك بالإنترنت';
  static const String banned            = 'تم حظر حسابك';
  static const String alreadyVoted      = 'لقد صوّتت هذا الأسبوع بالفعل';
  static const String cannotVoteOwn     = 'لا يمكنك التصويت على منشوراتك';
  static const String votingOver        = 'انتهت مرحلة التصويت';

  // ── Misc ───────────────────────────────────
  static const String cancel            = 'إلغاء';
  static const String confirm           = 'تأكيد';
  static const String loading           = 'جارٍ التحميل...';
  static const String retry             = 'إعادة المحاولة';
  static const String done              = 'تم';

  // ── Live Streaming ─────────────────────────
  static const String liveTitle         = 'مباشر';
  static const String navLive           = 'مباشر';
  static const String liveBroadcast     = 'ابدأ';
  static const String liveWatch         = 'شاهد';
  static const String liveLocked        = 'البث المباشر 🔒';
  static const String liveLockedDesc    = 'متاح فقط لأبطال دوري الملوك';
  static const String noLiveStreams     = 'لا يوجد بث مباشر حالياً';
  static const String liveStartTitle    = 'بدء البث المباشر';
  static const String liveStreamTitleHint = 'عنوان البث (اختياري)';
  static const String liveGoLive        = 'ابدأ البث الآن 🔴';
  static const String liveEnd           = 'إنهاء';
  static const String liveEnded         = 'انتهى البث';
  static const String liveEndConfirm    = 'إنهاء البث المباشر؟';
  static const String liveEndDesc       = 'هل تريد إنهاء البث؟ لن تتمكن من استئنافه.';
  static const String liveEndButton     = 'نعم، إنهاء';
  static const String liveBackToList    = 'العودة للقائمة';
  static const String liveChatHint      = 'اكتب تعليقاً...';
}

