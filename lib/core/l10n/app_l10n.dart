import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_strings.dart';
import '../constants/app_strings_en.dart';
import '../theme/locale_provider.dart';

// ── Unified Localization Class ────────────────────────────────────────────────
/// Returns the correct string (Arabic or English) based on the current locale.
/// Usage: final s = ref.watch(appL10nProvider);  then use s.login, s.navHome, etc.
class AppL10n {
  final bool isArabic;
  const AppL10n({required this.isArabic});

  // ── App ───────────────────────────────────────
  String get appName     => AppStrings.appName;
  String get appTagline  => isArabic ? AppStrings.appTagline  : AppStringsEn.appTagline;

  // ── Auth ──────────────────────────────────────
  String get enterEmail         => isArabic ? AppStrings.enterEmail         : AppStringsEn.enterEmail;
  String get emailHint          => AppStrings.emailHint; // same in both
  String get enterPassword      => isArabic ? AppStrings.enterPassword      : AppStringsEn.enterPassword;
  String get passwordHint       => isArabic ? AppStrings.passwordHint       : AppStringsEn.passwordHint;
  String get login              => isArabic ? AppStrings.login              : AppStringsEn.login;
  String get signUp             => isArabic ? AppStrings.signUp             : AppStringsEn.signUp;
  String get dontHaveAccount    => isArabic ? AppStrings.dontHaveAccount    : AppStringsEn.dontHaveAccount;
  String get alreadyHaveAccount => isArabic ? AppStrings.alreadyHaveAccount : AppStringsEn.alreadyHaveAccount;
  String get passwordTooShort   => isArabic ? AppStrings.passwordTooShort   : AppStringsEn.passwordTooShort;
  String get emailRequired      => isArabic ? AppStrings.emailRequired      : AppStringsEn.emailRequired;
  String get emailInvalid       => isArabic ? AppStrings.emailInvalid       : AppStringsEn.emailInvalid;
  String get setupUsername      => isArabic ? AppStrings.setupUsername      : AppStringsEn.setupUsername;
  String get chooseUsername     => isArabic ? AppStrings.chooseUsername     : AppStringsEn.chooseUsername;
  String get usernameHint       => isArabic ? AppStrings.usernameHint       : AppStringsEn.usernameHint;
  String get displayNameLabel   => isArabic ? AppStrings.displayNameLabel   : AppStringsEn.displayNameLabel;
  String get displayNameHint    => isArabic ? AppStrings.displayNameHint    : AppStringsEn.displayNameHint;
  String get addPhoto           => isArabic ? AppStrings.addPhoto           : AppStringsEn.addPhoto;
  String get skipForNow         => isArabic ? AppStrings.skipForNow         : AppStringsEn.skipForNow;
  String get createAccount      => isArabic ? AppStrings.createAccount      : AppStringsEn.createAccount;
  String get usernameExists     => isArabic ? AppStrings.usernameExists     : AppStringsEn.usernameExists;
  String get usernameInvalid    => isArabic ? AppStrings.usernameInvalid    : AppStringsEn.usernameInvalid;
  String get usernameTooShort   => isArabic ? AppStrings.usernameTooShort   : AppStringsEn.usernameTooShort;

  // ── Navigation ────────────────────────────────
  String get navHome      => isArabic ? AppStrings.navHome      : AppStringsEn.navHome;
  String get navRankings  => isArabic ? AppStrings.navRankings  : AppStringsEn.navRankings;
  String get navUpload    => isArabic ? AppStrings.navUpload    : AppStringsEn.navUpload;
  String get navWinners   => isArabic ? AppStrings.navWinners   : AppStringsEn.navWinners;
  String get navProfile   => isArabic ? AppStrings.navProfile   : AppStringsEn.navProfile;
  String get navLive      => isArabic ? AppStrings.navLive      : AppStringsEn.navLive;
  String get navMessages  => isArabic ? 'رسائل'                 : 'Messages';

  // ── Feed ──────────────────────────────────────
  String get weeklyFeed     => isArabic ? AppStrings.weeklyFeed     : AppStringsEn.weeklyFeed;
  String get voteNow        => isArabic ? AppStrings.voteNow        : AppStringsEn.voteNow;
  String get voted          => isArabic ? AppStrings.voted          : AppStringsEn.voted;
  String get views          => isArabic ? AppStrings.views          : AppStringsEn.views;
  String get votingClosed   => isArabic ? AppStrings.votingClosed   : AppStringsEn.votingClosed;
  String get pullToRefresh  => isArabic ? AppStrings.pullToRefresh  : AppStringsEn.pullToRefresh;
  String get noPostsYet     => isArabic ? AppStrings.noPostsYet     : AppStringsEn.noPostsYet;
  String get beFirst        => isArabic ? AppStrings.beFirst        : AppStringsEn.beFirst;
  String get anonymousPrefix => isArabic ? AppStrings.anonymousPrefix : AppStringsEn.anonymousPrefix;
  String get votingClosesIn => isArabic ? AppStrings.votingClosesIn : AppStringsEn.votingClosesIn;
  String get announcementIn => isArabic ? AppStrings.announcementIn : AppStringsEn.announcementIn;

  // ── Feed inline strings ───────────────────────
  String get voteNowLabel       => isArabic ? 'صوّت الآن'        : 'Vote Now';
  String get votedLabel         => isArabic ? 'تم التصويت'       : 'Voted';
  String get usedVoteLabel      => isArabic ? 'استنفذت صوتك'     : 'Already voted';
  String get noActiveWeeks      => isArabic ? 'لا توجد أسابيع نشطة' : 'No active weeks';
  String get reportPost         => isArabic ? 'إبلاغ (Report)'   : 'Report';
  String get reportedMsg        => isArabic ? 'تم الإبلاغ عن المنشور، سيتم مراجعته.' : 'Post reported, it will be reviewed.';
  String get likeError          => isArabic ? 'خطأ في الإعجاب'   : 'Error liking post';
  String get notifications      => isArabic ? AppStrings.notifications : AppStringsEn.notifications;
  String get cannotFollowAnon   => isArabic ? 'لا يمكن المتابعة أثناء فترة التصويت المجهول' : 'Cannot follow during anonymous voting period';

  // ── Upload ────────────────────────────────────
  String get uploadPost     => isArabic ? AppStrings.uploadPost     : AppStringsEn.uploadPost;
  String get chooseMedia    => isArabic ? AppStrings.chooseMedia    : AppStringsEn.chooseMedia;
  String get addCaption     => isArabic ? AppStrings.addCaption     : AppStringsEn.addCaption;
  String get captionHint    => isArabic ? AppStrings.captionHint    : AppStringsEn.captionHint;
  String get selectCategory => isArabic ? AppStrings.selectCategory : AppStringsEn.selectCategory;
  String get uploadProgress => isArabic ? AppStrings.uploadProgress : AppStringsEn.uploadProgress;
  String get submitting     => isArabic ? AppStrings.submitting     : AppStringsEn.submitting;
  String get publishPost    => isArabic ? AppStrings.publishPost    : AppStringsEn.publishPost;
  String get videoTooLong   => isArabic ? AppStrings.videoTooLong   : AppStringsEn.videoTooLong;
  String get uploading      => isArabic ? AppStrings.uploading      : AppStringsEn.uploading;
  String get uploadSuccess  => isArabic ? AppStrings.uploadSuccess  : AppStringsEn.uploadSuccess;
  String get uploadFailed   => isArabic ? AppStrings.uploadFailed   : AppStringsEn.uploadFailed;

  // ── Categories ────────────────────────────────
  List<String> get categories => isArabic ? AppStrings.categories : AppStringsEn.categories;
  List<String> get categoriesWithAll => isArabic
      ? ['الكل', ...AppStrings.categories]
      : ['All', ...AppStringsEn.categories];

  // ── Rankings ──────────────────────────────────
  String get rankingsTitle   => isArabic ? AppStrings.rankingsTitle   : AppStringsEn.rankingsTitle;
  String get tierBlueLabel   => isArabic ? AppStrings.tierBlueLabel   : AppStringsEn.tierBlueLabel;
  String get tierGoldLabel   => isArabic ? AppStrings.tierGoldLabel   : AppStringsEn.tierGoldLabel;
  String get tierRedLabel    => isArabic ? AppStrings.tierRedLabel    : AppStringsEn.tierRedLabel;
  String get rank            => isArabic ? AppStrings.rank            : AppStringsEn.rank;
  String get score           => isArabic ? AppStrings.score           : AppStringsEn.score;

  // ── Winners Hall ──────────────────────────────
  String get winnersHall  => isArabic ? AppStrings.winnersHall  : AppStringsEn.winnersHall;
  String get weekWinner   => isArabic ? AppStrings.weekWinner   : AppStringsEn.weekWinner;
  String get week         => isArabic ? AppStrings.week         : AppStringsEn.week;
  String get noWinnersYet => isArabic ? AppStrings.noWinnersYet : AppStringsEn.noWinnersYet;

  // ── Profile ───────────────────────────────────
  String get myProfile      => isArabic ? AppStrings.myProfile      : AppStringsEn.myProfile;
  String get totalPosts     => isArabic ? AppStrings.totalPosts      : AppStringsEn.totalPosts;
  String get totalVotes     => isArabic ? AppStrings.totalVotes      : AppStringsEn.totalVotes;
  String get streakDays     => isArabic ? AppStrings.streakDays      : AppStringsEn.streakDays;
  String get bestRank       => isArabic ? AppStrings.bestRank        : AppStringsEn.bestRank;
  String get editProfile    => isArabic ? AppStrings.editProfile     : AppStringsEn.editProfile;
  String get myPosts        => isArabic ? AppStrings.myPosts         : AppStringsEn.myPosts;
  String get levelProgress  => isArabic ? AppStrings.levelProgress   : AppStringsEn.levelProgress;
  String get saveChanges    => isArabic ? AppStrings.saveChanges      : AppStringsEn.saveChanges;
  String get maxLevelMsg    => isArabic ? 'وصلت للمستوى الأعلى 🏆'   : 'Maximum level reached 🏆';
  String get noPostsOwn     => isArabic ? 'لم تنشر بعد — شارك أول محتوى!' : 'No posts yet — share your first content!';
  String get noPostsOther   => isArabic ? 'لا توجد منشورات بعد'     : 'No posts yet';
  String get userNotFound   => isArabic ? 'المستخدم غير موجود'      : 'User not found';
  String get adminPanel     => isArabic ? AppStrings.adminPanel       : AppStringsEn.adminPanel;
  String get adminPanelMenu => isArabic ? 'لوحة الإدارة'             : 'Admin Panel';
  String get messageBtn     => isArabic ? 'رسالة'                    : 'Message';
  String get errorMsg       => isArabic ? 'خطأ'                      : 'Error';

  // ── Notifications ─────────────────────────────
  String get markAllRead       => isArabic ? AppStrings.markAllRead       : AppStringsEn.markAllRead;
  String get noNotifications   => isArabic ? AppStrings.noNotifications   : AppStringsEn.noNotifications;
  String get notifVoteReceived => isArabic ? AppStrings.notifVoteReceived : AppStringsEn.notifVoteReceived;
  String get notifWeekWinner   => isArabic ? AppStrings.notifWeekWinner   : AppStringsEn.notifWeekWinner;
  String get notifLevelUp      => isArabic ? AppStrings.notifLevelUp      : AppStringsEn.notifLevelUp;
  String get notifStreak       => isArabic ? AppStrings.notifStreak       : AppStringsEn.notifStreak;

  // ── Admin ─────────────────────────────────────
  String get totalUsers        => isArabic ? AppStrings.totalUsers        : AppStringsEn.totalUsers;
  String get activeWeek        => isArabic ? AppStrings.activeWeek        : AppStringsEn.activeWeek;
  String get recalculateScores => isArabic ? AppStrings.recalculateScores : AppStringsEn.recalculateScores;
  String get announceWinners   => isArabic ? AppStrings.announceWinners   : AppStringsEn.announceWinners;
  String get reportedPosts     => isArabic ? AppStrings.reportedPosts     : AppStringsEn.reportedPosts;
  String get banPost           => isArabic ? AppStrings.banPost           : AppStringsEn.banPost;
  String get keepPost          => isArabic ? AppStrings.keepPost          : AppStringsEn.keepPost;
  String get createWeek        => isArabic ? AppStrings.createWeek        : AppStringsEn.createWeek;

  // ── Errors ────────────────────────────────────
  String get genericError   => isArabic ? AppStrings.genericError   : AppStringsEn.genericError;
  String get networkError   => isArabic ? AppStrings.networkError   : AppStringsEn.networkError;
  String get banned         => isArabic ? AppStrings.banned         : AppStringsEn.banned;
  String get alreadyVoted   => isArabic ? AppStrings.alreadyVoted   : AppStringsEn.alreadyVoted;
  String get cannotVoteOwn  => isArabic ? AppStrings.cannotVoteOwn  : AppStringsEn.cannotVoteOwn;
  String get votingOver     => isArabic ? AppStrings.votingOver     : AppStringsEn.votingOver;

  // ── Misc ──────────────────────────────────────
  String get cancel  => isArabic ? AppStrings.cancel  : AppStringsEn.cancel;
  String get confirm => isArabic ? AppStrings.confirm : AppStringsEn.confirm;
  String get loading => isArabic ? AppStrings.loading : AppStringsEn.loading;
  String get retry   => isArabic ? AppStrings.retry   : AppStringsEn.retry;
  String get unban => isArabic ? 'فك الحظر' : 'Unban';
  String get wallet => isArabic ? 'المحفظة' : 'Wallet';
  String get messagesTitle => isArabic ? 'الرسائل' : 'Messages';
  String get following => isArabic ? 'يتابع' : 'Following';
  String get follower => isArabic ? 'متابع' : 'Follower';
  String get followers => isArabic ? 'متابعين' : 'Followers';
  String get followingBtn => isArabic ? 'تتابعه' : 'Following';
  String get followBtn => isArabic ? 'متابعة' : 'Follow';
  String get newChat => isArabic ? 'محادثة جديدة' : 'New Chat';
  String get searchByUsername => isArabic ? 'ابحث باسم المستخدم @username' : 'Search by @username';
  String get startChat => isArabic ? 'ابدأ المحادثة' : 'Start Chat';
  String get startChatDots => isArabic ? 'ابدأ المحادثة...' : 'Start chat...';
  String get noConversationsYet => isArabic ? 'لا توجد محادثات بعد' : 'No conversations yet';
  String get startNewChatWithAnyUser => isArabic ? 'ابدأ محادثة جديدة مع أي مستخدم' : 'Start a new chat with any user';
  String get writeMessageHint => isArabic ? 'اكتب رسالة...' : 'Write a message...';
  String get done    => isArabic ? AppStrings.done    : AppStringsEn.done;
  String get conversationFallback => isArabic ? 'محادثة' : 'Conversation';
  String get startChatHandWave => isArabic ? 'ابدأ المحادثة 👋' : 'Start the chat 👋';

  // ── Live Streaming ────────────────────────────
  String get liveTitle          => isArabic ? AppStrings.liveTitle          : AppStringsEn.liveTitle;
  String get navLiveLabel       => isArabic ? AppStrings.navLive            : AppStringsEn.navLive;
  String get liveBroadcast      => isArabic ? AppStrings.liveBroadcast      : AppStringsEn.liveBroadcast;
  String get liveWatch          => isArabic ? AppStrings.liveWatch          : AppStringsEn.liveWatch;
  String get liveLocked         => isArabic ? AppStrings.liveLocked         : AppStringsEn.liveLocked;
  String get liveLockedDesc     => isArabic ? AppStrings.liveLockedDesc     : AppStringsEn.liveLockedDesc;
  String get noLiveStreams       => isArabic ? AppStrings.noLiveStreams      : AppStringsEn.noLiveStreams;
  String get liveStartTitle     => isArabic ? AppStrings.liveStartTitle     : AppStringsEn.liveStartTitle;
  String get liveStreamTitleHint => isArabic ? AppStrings.liveStreamTitleHint : AppStringsEn.liveStreamTitleHint;
  String get liveGoLive         => isArabic ? AppStrings.liveGoLive         : AppStringsEn.liveGoLive;
  String get liveEnd            => isArabic ? AppStrings.liveEnd            : AppStringsEn.liveEnd;
  String get liveEnded          => isArabic ? AppStrings.liveEnded          : AppStringsEn.liveEnded;
  String get liveEndConfirm     => isArabic ? AppStrings.liveEndConfirm     : AppStringsEn.liveEndConfirm;
  String get liveEndDesc        => isArabic ? AppStrings.liveEndDesc        : AppStringsEn.liveEndDesc;
  String get liveEndButton      => isArabic ? AppStrings.liveEndButton      : AppStringsEn.liveEndButton;
  String get liveBackToList     => isArabic ? AppStrings.liveBackToList     : AppStringsEn.liveBackToList;
  String get liveChatHint       => isArabic ? AppStrings.liveChatHint       : AppStringsEn.liveChatHint;

  // ── Splash / Auth extra ───────────────────────
  String get termsText => isArabic
      ? 'بالمتابعة، أنت توافق على شروط الخدمة وسياسة الخصوصية'
      : 'By continuing, you agree to our Terms of Service and Privacy Policy';
  String get emailConfirmMsg => isArabic
      ? 'يرجى تأكيد بريدك الإلكتروني من الرابط المرسل إليك'
      : 'Please confirm your email address from the link sent to you';
  String get profileLoadError => isArabic
      ? 'خطأ في تحميل الملف الشخصي'
      : 'Error loading profile';

  // ── Helpers ─────────────────────────────────────
  String translateLevel(String level) {
    if (isArabic) return level;
    switch (level) {
      case 'مجهول': return 'Unknown';
      case 'موهبة': return 'Talent';
      case 'صاعد': return 'Rising';
      case 'نجم': return 'Star';
      case 'ملك': return 'King';
      case 'أسطورة': return 'Legend';
      default: return level;
    }
  }

  String translateCategory(String cat) {
    if (isArabic) return cat;
    switch (cat) {
      case 'الكل': return 'All';
      case 'موهبة': return 'Talent';
      case 'كوميديا': return 'Comedy';
      case 'تجارة': return 'Business';
      case 'تحدي': return 'Challenge';
      case 'فكرة': return 'Idea';
      default: return cat;
    }
  }

  String translateCreatorLabel(String label) {
    if (isArabic) return label;
    if (label == 'منشئ') return 'Creator';
    return label;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final appL10nProvider = Provider<AppL10n>((ref) {
  final locale = ref.watch(localeProvider);
  return AppL10n(isArabic: locale.languageCode == 'ar');
});
