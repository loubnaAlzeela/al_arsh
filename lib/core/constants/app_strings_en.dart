/// Al Arsh — English String Constants
abstract class AppStringsEn {
  // ── App ────────────────────────────────────
  static const String appName        = 'ZUVOXA';
  static const String appTagline     = 'Compete. Create. Shine.';

  // ── Auth ───────────────────────────────────
  static const String enterEmail         = 'Enter your email';
  static const String emailHint          = 'example@domain.com';
  static const String enterPassword      = 'Password'; // security-ignore-line
  static const String passwordHint       = 'Enter password (min 6 chars)';
  static const String login              = 'Login';
  static const String signUp             = 'Sign Up';
  static const String dontHaveAccount    = 'No account? Sign up';
  static const String alreadyHaveAccount = 'Have an account? Login';
  static const String passwordTooShort   = 'Password too short (min 6 chars)';
  static const String emailRequired      = 'Enter your email';
  static const String emailInvalid       = 'Invalid email address';
  static const String setupUsername      = 'Create Your Account';
  static const String chooseUsername     = 'Choose a username';
  static const String usernameHint       = 'your_username';
  static const String displayNameLabel   = 'Display Name';
  static const String displayNameHint    = 'Your name in the app';
  static const String addPhoto           = 'Add Photo';
  static const String skipForNow         = 'Skip for Now';
  static const String createAccount      = 'Create Account';
  static const String usernameExists     = 'Username already taken';
  static const String usernameInvalid    = 'Only letters and numbers allowed';
  static const String usernameTooShort   = 'Must be at least 3 characters';

  // ── Navigation ─────────────────────────────
  static const String navHome            = 'Home';
  static const String navRankings        = 'Rankings';
  static const String navUpload          = 'Post';
  static const String navWinners         = 'Stars';
  static const String navProfile         = 'Profile';

  // ── Feed ───────────────────────────────────
  static const String weeklyFeed         = 'Weekly Posts';
  static const String voteNow            = 'Vote';
  static const String voted              = 'Voted';
  static const String views              = 'Views';
  static const String votingClosed       = 'Voting Closed';
  static const String pullToRefresh      = 'Pull to Refresh';
  static const String noPostsYet         = 'No posts yet';
  static const String beFirst            = 'Be the first to post this week!';
  static const String anonymousPrefix    = 'Creator #';

  // ── Upload ─────────────────────────────────
  static const String uploadPost         = 'Post Content';
  static const String chooseMedia        = 'Choose a photo or video';
  static const String addCaption         = 'Add a description (optional)';
  static const String captionHint        = 'Share your idea...';
  static const String selectCategory     = 'Select Category';
  static const String uploadProgress     = 'Uploading...';
  static const String submitting         = 'Publishing...';
  static const String publishPost        = 'Post';
  static const String videoTooLong       = 'Video must be under 60 seconds';
  static const String uploading          = 'Uploading...';
  static const String uploadSuccess      = 'Content posted successfully!';
  static const String uploadFailed       = 'Post failed, try again';

  // ── Categories ─────────────────────────────
  static const List<String> categories = [
    'Talent', 'Comedy', 'Business', 'Challenge', 'Idea', 'Other'
  ];

  // ── Rankings ───────────────────────────────
  static const String rankingsTitle      = 'Weekly Rankings';
  static const String tierBlueLabel      = 'Risers League';
  static const String tierGoldLabel      = 'Elite League';
  static const String tierRedLabel       = 'Kings League';
  static const String votingClosesIn     = 'Voting closes in';
  static const String announcementIn     = 'Winners announced in';
  static const String rank               = 'Rank';
  static const String score              = 'Score';

  // ── Winners Hall ───────────────────────────
  static const String winnersHall        = 'Hall of Fame';
  static const String weekWinner         = 'Week Champion';
  static const String week               = 'Week';
  static const String noWinnersYet       = 'No winners yet';

  // ── Profile ────────────────────────────────
  static const String myProfile          = 'My Profile';
  static const String totalPosts         = 'Posts';
  static const String totalVotes         = 'Votes';
  static const String streakDays         = 'day streak';
  static const String bestRank           = 'Best Rank';
  static const String editProfile        = 'Edit Profile';
  static const String myPosts            = 'My Posts';
  static const String levelProgress      = 'Progress to Next Level';
  static const String saveChanges        = 'Save Changes';

  // ── Notifications ──────────────────────────
  static const String notifications      = 'Notifications';
  static const String markAllRead        = 'Mark All as Read';
  static const String noNotifications    = 'No notifications';
  static const String notifVoteReceived  = 'You received a vote!';
  static const String notifWeekWinner    = 'You are the week champion! 🎉';
  static const String notifLevelUp       = 'Level Up! ⬆️';
  static const String notifStreak        = 'Daily Streak! 🔥';

  // ── Admin ──────────────────────────────────
  static const String adminPanel         = 'Admin Panel';
  static const String totalUsers         = 'Users';
  static const String activeWeek         = 'Current Week';
  static const String recalculateScores  = 'Recalculate Scores';
  static const String announceWinners    = 'Announce Winners';
  static const String reportedPosts      = 'Reported Posts';
  static const String banPost            = 'Ban';
  static const String keepPost           = 'Keep';
  static const String createWeek         = 'Create New Week';

  // ── Levels ─────────────────────────────────
  static const Map<String, String> levelDescriptions = {
    'Unknown' : 'Starting level',
    'Talent'  : '100 votes or 7-day streak',
    'Rising'  : '500 votes or Blue League win',
    'Star'    : '2000 votes or Elite League win',
    'King'    : 'Kings League win',
    'Legend'  : '3 Kings League wins',
  };

  // ── Errors ─────────────────────────────────
  static const String genericError      = 'An error occurred, please try again';
  static const String networkError      = 'Check your internet connection';
  static const String banned            = 'Your account has been banned';
  static const String alreadyVoted      = 'You already voted this week';
  static const String cannotVoteOwn     = 'You cannot vote on your own posts';
  static const String votingOver        = 'Voting phase has ended';

  // ── Misc ───────────────────────────────────
  static const String cancel            = 'Cancel';
  static const String confirm           = 'Confirm';
  static const String loading           = 'Loading...';
  static const String retry             = 'Retry';
  static const String done              = 'Done';

  // ── Live Streaming ─────────────────────────
  static const String liveTitle         = 'LIVE';
  static const String navLive           = 'Live';
  static const String liveBroadcast     = 'Start';
  static const String liveWatch         = 'Watch';
  static const String liveLocked        = 'Live Stream 🔒';
  static const String liveLockedDesc    = 'Only available for Kings League champions';
  static const String noLiveStreams     = 'No live streams right now';
  static const String liveStartTitle    = 'Start Live Stream';
  static const String liveStreamTitleHint = 'Stream title (optional)';
  static const String liveGoLive        = 'Go Live Now 🔴';
  static const String liveEnd           = 'End';
  static const String liveEnded         = 'Stream Ended';
  static const String liveEndConfirm    = 'End Live Stream?';
  static const String liveEndDesc       = 'Do you want to end the stream? You cannot resume it.';
  static const String liveEndButton     = 'Yes, End';
  static const String liveBackToList    = 'Back to List';
  static const String liveChatHint      = 'Write a comment...';
}
