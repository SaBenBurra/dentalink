// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DentLink';

  @override
  String get appTagline => 'Social Platform for Dentists';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get error => 'Error';

  @override
  String get unknownError => 'An unknown error occurred.';

  @override
  String get networkError => 'Please check your internet connection.';

  @override
  String get noResults => 'No results found.';

  @override
  String get emptyFeed => 'No posts yet.';

  @override
  String get seeAll => 'See All';

  @override
  String get sharePost => 'Share Post';

  @override
  String get report => 'Report';

  @override
  String get moreOptions => 'More Options';

  @override
  String get navFeed => 'Home';

  @override
  String get navExplore => 'Explore';

  @override
  String get navCreate => 'Create';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profile';

  @override
  String get loginTitle => 'Welcome!';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get loginButton => 'Continue';

  @override
  String get textBeetweenLoginAndOauth => 'or';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get loginWithPhone => 'Continue with Phone';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get registerNow => 'Sign Up';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerButton => 'Sign Up';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signIn => 'Sign In';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'enter your e-mail address';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get phone => 'Phone Number';

  @override
  String get phoneHint => '+1 xxx xxx xxxx';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get sendCode => 'Send Code';

  @override
  String get verifyCode => 'Verify Code';

  @override
  String get titleSelection => 'Select Title';

  @override
  String get titleSelectionSubtitle =>
      'Choose the title that best describes you';

  @override
  String get titleStudent => 'Student';

  @override
  String get titleGeneralDentist => 'General Dentist';

  @override
  String get titleEndodontist => 'Endodontist';

  @override
  String get titleOrthodontist => 'Orthodontist';

  @override
  String get titlePeriodontologist => 'Periodontologist';

  @override
  String get titleProsthodontist => 'Prosthodontist';

  @override
  String get titlePedodontist => 'Pedodontist';

  @override
  String get titleOralSurgeon => 'Oral and Maxillofacial Surgeon';

  @override
  String get titleOralRadiologist => 'Oral and Maxillofacial Radiologist';

  @override
  String get titleOralDiagnostics => 'Oral Diagnosis Specialist';

  @override
  String get titleRestorativeDentistry => 'Restorative Dentistry Specialist';

  @override
  String get profileTitle => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get followers => 'Followers';

  @override
  String get following => 'Following';

  @override
  String get posts => 'Posts';

  @override
  String get followButton => 'Follow';

  @override
  String get unfollowButton => 'Unfollow';

  @override
  String get messageButton => 'Send Message';

  @override
  String get bio => 'Bio';

  @override
  String get university => 'University';

  @override
  String get city => 'City';

  @override
  String get experienceYears => 'Years of Experience';

  @override
  String get workplace => 'Clinic / Hospital';

  @override
  String get profileBadges => 'My Badges';

  @override
  String get profileCases => 'My Cases';

  @override
  String get profileQuestions => 'My Questions';

  @override
  String get profileSaved => 'Saved';

  @override
  String get casePost => 'Case';

  @override
  String get questionPost => 'Question';

  @override
  String get createPost => 'Create Post';

  @override
  String get createCase => 'Share Case';

  @override
  String get createQuestion => 'Ask Question';

  @override
  String get postTitle => 'Title';

  @override
  String get postContent => 'Description';

  @override
  String get postBranch => 'Branch';

  @override
  String get postTags => 'Tags';

  @override
  String get addTag => 'Add Tag';

  @override
  String get addImages => 'Add Images';

  @override
  String get maxImagesReached => 'You can add up to 10 images.';

  @override
  String get publish => 'Publish';

  @override
  String get branchPedodontics => 'Pedodontics';

  @override
  String get branchEndodontics => 'Endodontics';

  @override
  String get branchOrthodontics => 'Orthodontics';

  @override
  String get branchPeriodontology => 'Periodontology';

  @override
  String get branchProsthodontics => 'Prosthodontics';

  @override
  String get branchOralSurgery => 'Oral and Maxillofacial Surgery';

  @override
  String get branchOralRadiology => 'Oral and Maxillofacial Radiology';

  @override
  String get branchOralDiagnosis => 'Oral Diagnosis';

  @override
  String get branchRestorativeDentistry => 'Restorative Dentistry';

  @override
  String get feedChronological => 'Latest';

  @override
  String get feedAlgorithmic => 'Top Picks';

  @override
  String get feedFilterAll => 'All';

  @override
  String get feedFilterCases => 'Cases';

  @override
  String get feedFilterQuestions => 'Questions';

  @override
  String likesCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString likes';
  }

  @override
  String commentsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString comments';
  }

  @override
  String answersCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString answers';
  }

  @override
  String get bestAnswer => 'Best Answer';

  @override
  String get markAsBestAnswer => 'Mark as Best Answer';

  @override
  String get writeComment => 'Write a comment...';

  @override
  String get writeAnswer => 'Write your answer...';

  @override
  String get sendMessage => 'Send';

  @override
  String get exploreTitle => 'Explore';

  @override
  String get searchHint => 'Search cases, questions or users...';

  @override
  String get filterByBranch => 'By Branch';

  @override
  String get filterByTitle => 'By Title';

  @override
  String get filterByType => 'By Type';

  @override
  String get filterByTag => 'By Tag';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get noMessages => 'No messages yet.';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotifications => 'No notifications yet.';

  @override
  String notifLiked(String name) {
    return '$name liked your post.';
  }

  @override
  String notifCommented(String name) {
    return '$name commented on your post.';
  }

  @override
  String notifFollowed(String name) {
    return '$name started following you.';
  }

  @override
  String notifMessage(String name) {
    return '$name sent you a message.';
  }

  @override
  String get bookmarksTitle => 'Saved';

  @override
  String get noBookmarks => 'No saved posts yet.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System Default';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsLogout => 'Sign Out';

  @override
  String get settingsLogoutConfirm => 'Are you sure you want to sign out?';

  @override
  String get languageTurkish => 'Turkish';

  @override
  String get languageEnglish => 'English';

  @override
  String get badgeExpert => 'Expert';

  @override
  String get badgePopular => 'Popular';

  @override
  String get badgeHelper => 'Helper';

  @override
  String get badgeNewMember => 'New Member';

  @override
  String get validationRequired => 'This field is required.';

  @override
  String get validationEmailInvalid => 'Please enter a valid email address.';

  @override
  String get validationPasswordMinLength =>
      'Password must be at least 8 characters.';

  @override
  String get validationPasswordMismatch => 'Passwords do not match.';

  @override
  String get validationPhoneInvalid => 'Please enter a valid phone number.';
}
