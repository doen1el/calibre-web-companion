import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_et.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('et'),
    Locale('fr'),
    Locale('it'),
    Locale('pt'),
    Locale('tr')
  ];

  /// No description provided for @loginToCalibreWb.
  ///
  /// In en, this message translates to:
  /// **'Login to Calibre Web'**
  String get loginToCalibreWb;

  /// No description provided for @calibreWebUrl.
  ///
  /// In en, this message translates to:
  /// **'https://calibre.example.com'**
  String get calibreWebUrl;

  /// No description provided for @enterCalibreWebUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter Calibre Web URL'**
  String get enterCalibreWebUrl;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @enterYourUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterYourUsername;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @pleaseFillInAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillInAllFields;

  /// No description provided for @failedToLognIn.
  ///
  /// In en, this message translates to:
  /// **'Failed to login'**
  String get failedToLognIn;

  /// No description provided for @books.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get books;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @discoverBooks.
  ///
  /// In en, this message translates to:
  /// **'Discover books'**
  String get discoverBooks;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchBook.
  ///
  /// In en, this message translates to:
  /// **'Search book'**
  String get searchBook;

  /// No description provided for @enterTitleAuthorOrTags.
  ///
  /// In en, this message translates to:
  /// **'Enter title, author or tags ...'**
  String get enterTitleAuthorOrTags;

  /// No description provided for @showReadBooks.
  ///
  /// In en, this message translates to:
  /// **'Show read books'**
  String get showReadBooks;

  /// No description provided for @showUnReadBooks.
  ///
  /// In en, this message translates to:
  /// **'Show unread books'**
  String get showUnReadBooks;

  /// No description provided for @showBookmarkedBooks.
  ///
  /// In en, this message translates to:
  /// **'Show bookmarked books'**
  String get showBookmarkedBooks;

  /// No description provided for @readBooks.
  ///
  /// In en, this message translates to:
  /// **'Read books'**
  String get readBooks;

  /// No description provided for @unreadBooks.
  ///
  /// In en, this message translates to:
  /// **'Unread books'**
  String get unreadBooks;

  /// No description provided for @bookmarkedBooks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked books'**
  String get bookmarkedBooks;

  /// No description provided for @showHotBooks.
  ///
  /// In en, this message translates to:
  /// **'Show hot books'**
  String get showHotBooks;

  /// No description provided for @hotBooks.
  ///
  /// In en, this message translates to:
  /// **'Hot books'**
  String get hotBooks;

  /// No description provided for @showNewBooks.
  ///
  /// In en, this message translates to:
  /// **'Show new books'**
  String get showNewBooks;

  /// No description provided for @newBooks.
  ///
  /// In en, this message translates to:
  /// **'New books'**
  String get newBooks;

  /// No description provided for @showRatedBooks.
  ///
  /// In en, this message translates to:
  /// **'Show rated books'**
  String get showRatedBooks;

  /// No description provided for @ratedBooks.
  ///
  /// In en, this message translates to:
  /// **'Rated books'**
  String get ratedBooks;

  /// No description provided for @titleAZ.
  ///
  /// In en, this message translates to:
  /// **'Title (A-Z)'**
  String get titleAZ;

  /// No description provided for @titleZA.
  ///
  /// In en, this message translates to:
  /// **'Title (Z-A)'**
  String get titleZA;

  /// No description provided for @authorAZ.
  ///
  /// In en, this message translates to:
  /// **'Author (A-Z)'**
  String get authorAZ;

  /// No description provided for @authorZA.
  ///
  /// In en, this message translates to:
  /// **'Author (Z-A)'**
  String get authorZA;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get newestFirst;

  /// No description provided for @oldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get oldestFirst;

  /// No description provided for @authors.
  ///
  /// In en, this message translates to:
  /// **'Authors'**
  String get authors;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @series.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get series;

  /// No description provided for @formats.
  ///
  /// In en, this message translates to:
  /// **'Formats'**
  String get formats;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @publishers.
  ///
  /// In en, this message translates to:
  /// **'Publishers'**
  String get publishers;

  /// No description provided for @ratings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get ratings;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @showAuthors.
  ///
  /// In en, this message translates to:
  /// **'Show authors'**
  String get showAuthors;

  /// No description provided for @showCategories.
  ///
  /// In en, this message translates to:
  /// **'Show categories'**
  String get showCategories;

  /// No description provided for @showSeries.
  ///
  /// In en, this message translates to:
  /// **'Show series'**
  String get showSeries;

  /// No description provided for @showFormats.
  ///
  /// In en, this message translates to:
  /// **'Show formats'**
  String get showFormats;

  /// No description provided for @showLanguages.
  ///
  /// In en, this message translates to:
  /// **'Show languages'**
  String get showLanguages;

  /// No description provided for @showPublishers.
  ///
  /// In en, this message translates to:
  /// **'Show publishers'**
  String get showPublishers;

  /// No description provided for @showRatings.
  ///
  /// In en, this message translates to:
  /// **'Show ratings'**
  String get showRatings;

  /// No description provided for @by.
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String by(Object author);

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @publicationInfo.
  ///
  /// In en, this message translates to:
  /// **'Publication info'**
  String get publicationInfo;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @publisher.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get publisher;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @fileInfo.
  ///
  /// In en, this message translates to:
  /// **'File info'**
  String get fileInfo;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @noCoverAvailable.
  ///
  /// In en, this message translates to:
  /// **'No cover available'**
  String get noCoverAvailable;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @italian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get italian;

  /// No description provided for @japanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get japanese;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @portuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get portuguese;

  /// No description provided for @chineese.
  ///
  /// In en, this message translates to:
  /// **'Chineese'**
  String get chineese;

  /// No description provided for @dutch.
  ///
  /// In en, this message translates to:
  /// **'Dutch'**
  String get dutch;

  /// No description provided for @sendToEReader.
  ///
  /// In en, this message translates to:
  /// **'Send to E-Reader'**
  String get sendToEReader;

  /// No description provided for @sendToKindleKobo.
  ///
  /// In en, this message translates to:
  /// **'Send to Kindle/Kobo'**
  String get sendToKindleKobo;

  /// No description provided for @enter4DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 4-digit code displayed on your E-Reader\'s browser:'**
  String get enter4DigitCode;

  /// No description provided for @visit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get visit;

  /// No description provided for @onYourEReader.
  ///
  /// In en, this message translates to:
  /// **'on your E-Reader to get a code'**
  String get onYourEReader;

  /// No description provided for @pleaseEnter4DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 4-digit code'**
  String get pleaseEnter4DigitCode;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @startingDownloadProcess.
  ///
  /// In en, this message translates to:
  /// **'Starting download process'**
  String get startingDownloadProcess;

  /// No description provided for @preparingTransfer.
  ///
  /// In en, this message translates to:
  /// **'Preparing transfer...'**
  String get preparingTransfer;

  /// No description provided for @downloadingBook.
  ///
  /// In en, this message translates to:
  /// **'Downloading book...'**
  String get downloadingBook;

  /// No description provided for @sendingToEReader.
  ///
  /// In en, this message translates to:
  /// **'Sending to E-Reader...'**
  String get sendingToEReader;

  /// No description provided for @successfullySentToEReader.
  ///
  /// In en, this message translates to:
  /// **'Successfully sent to E-Reader'**
  String get successfullySentToEReader;

  /// No description provided for @transferFailed.
  ///
  /// In en, this message translates to:
  /// **'Transfer failed'**
  String get transferFailed;

  /// No description provided for @downloadToDevice.
  ///
  /// In en, this message translates to:
  /// **'Download to device'**
  String get downloadToDevice;

  /// No description provided for @errorDownloading.
  ///
  /// In en, this message translates to:
  /// **'Error downloading'**
  String get errorDownloading;

  /// No description provided for @downlaodFomat.
  ///
  /// In en, this message translates to:
  /// **'Download format'**
  String get downlaodFomat;

  /// No description provided for @preparingDownload.
  ///
  /// In en, this message translates to:
  /// **'Preparing download...'**
  String get preparingDownload;

  /// No description provided for @selectDownloadDestination.
  ///
  /// In en, this message translates to:
  /// **'Select download destination'**
  String get selectDownloadDestination;

  /// No description provided for @successfullyDownloadedBook.
  ///
  /// In en, this message translates to:
  /// **'Successfully downloaded book'**
  String get successfullyDownloadedBook;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @libraryStatistics.
  ///
  /// In en, this message translates to:
  /// **'Library statistics'**
  String get libraryStatistics;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorLoadingBooks.
  ///
  /// In en, this message translates to:
  /// **'Error loading books'**
  String get errorLoadingBooks;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @erroLoadingBookDetails.
  ///
  /// In en, this message translates to:
  /// **'Error loading book details'**
  String get erroLoadingBookDetails;

  /// No description provided for @noBooksFound.
  ///
  /// In en, this message translates to:
  /// **'No books found'**
  String get noBooksFound;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noDataFound;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeMode;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System theme'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @downloadService.
  ///
  /// In en, this message translates to:
  /// **'Download service'**
  String get downloadService;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @searchForABook.
  ///
  /// In en, this message translates to:
  /// **'Search for a book'**
  String get searchForABook;

  /// No description provided for @noDownloadsFound.
  ///
  /// In en, this message translates to:
  /// **'No downloads found'**
  String get noDownloadsFound;

  /// No description provided for @foundBooks.
  ///
  /// In en, this message translates to:
  /// **'Found {count} books'**
  String foundBooks(Object count);

  /// No description provided for @addedBookToTheDownloadQueue.
  ///
  /// In en, this message translates to:
  /// **'Added book to the download queue'**
  String get addedBookToTheDownloadQueue;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @queued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get queued;

  /// No description provided for @notDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get notDownloaded;

  /// No description provided for @downloadServiceUrl.
  ///
  /// In en, this message translates to:
  /// **'Download service URL'**
  String get downloadServiceUrl;

  /// No description provided for @enterUrlOfYourDownloadService.
  ///
  /// In en, this message translates to:
  /// **'Enter URL of your download service'**
  String get enterUrlOfYourDownloadService;

  /// No description provided for @bookWillBeSendToYourEmailAdress.
  ///
  /// In en, this message translates to:
  /// **'The book will be sent as EPUB to your registered email address.'**
  String get bookWillBeSendToYourEmailAdress;

  /// No description provided for @makeSureEmailSettingsAreConfigured.
  ///
  /// In en, this message translates to:
  /// **'Make sure SMTP mail settings are configured on the server.'**
  String get makeSureEmailSettingsAreConfigured;

  /// No description provided for @markAsReadUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as read/unread'**
  String get markAsReadUnread;

  /// No description provided for @archiveUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Archive/Unarchive'**
  String get archiveUnarchive;

  /// No description provided for @addToShelf.
  ///
  /// In en, this message translates to:
  /// **'Add to shelf'**
  String get addToShelf;

  /// No description provided for @selectShelf.
  ///
  /// In en, this message translates to:
  /// **'Select shelf'**
  String get selectShelf;

  /// No description provided for @noShelvesFound.
  ///
  /// In en, this message translates to:
  /// **'No shelves found'**
  String get noShelvesFound;

  /// No description provided for @bookAddedToShelf.
  ///
  /// In en, this message translates to:
  /// **'Book added to shelf {book}'**
  String bookAddedToShelf(Object book);

  /// No description provided for @failedToAddToShelf.
  ///
  /// In en, this message translates to:
  /// **'Failed to add to shelf'**
  String get failedToAddToShelf;

  /// No description provided for @bookRemovedFromShelf.
  ///
  /// In en, this message translates to:
  /// **'Book removed from shelf {book}'**
  String bookRemovedFromShelf(Object book);

  /// No description provided for @failedToRemoveFromShelf.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove book from shelf'**
  String get failedToRemoveFromShelf;

  /// No description provided for @removeFromShelf.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeFromShelf;

  /// No description provided for @shelfs.
  ///
  /// In en, this message translates to:
  /// **'Shelves'**
  String get shelfs;

  /// No description provided for @shelfContains.
  ///
  /// In en, this message translates to:
  /// **'Shelf contains {count} books'**
  String shelfContains(Object count);

  /// No description provided for @errorLoadingShelf.
  ///
  /// In en, this message translates to:
  /// **'Error loading shelf'**
  String get errorLoadingShelf;

  /// No description provided for @createShelf.
  ///
  /// In en, this message translates to:
  /// **'Create shelf'**
  String get createShelf;

  /// No description provided for @shelfName.
  ///
  /// In en, this message translates to:
  /// **'Shelf name'**
  String get shelfName;

  /// No description provided for @shelfNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Shelf name is required'**
  String get shelfNameRequired;

  /// No description provided for @shelfSuccessfullyCreated.
  ///
  /// In en, this message translates to:
  /// **'Shelf successfully created'**
  String get shelfSuccessfullyCreated;

  /// No description provided for @errorCreatingShelf.
  ///
  /// In en, this message translates to:
  /// **'Error creating shelf {name}'**
  String errorCreatingShelf(Object name);

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating'**
  String get creating;

  /// No description provided for @noShelvesFoundCreateOne.
  ///
  /// In en, this message translates to:
  /// **'No shelves found. Create one!'**
  String get noShelvesFoundCreateOne;

  /// No description provided for @editShelf.
  ///
  /// In en, this message translates to:
  /// **'Edit shelf'**
  String get editShelf;

  /// No description provided for @deleteShelf.
  ///
  /// In en, this message translates to:
  /// **'Delete shelf'**
  String get deleteShelf;

  /// No description provided for @bookOptions.
  ///
  /// In en, this message translates to:
  /// **'Book options'**
  String get bookOptions;

  /// No description provided for @successfullyDeletedShelf.
  ///
  /// In en, this message translates to:
  /// **'Successfully deleted shelf'**
  String get successfullyDeletedShelf;

  /// No description provided for @failedToDeleteShelf.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete shelf'**
  String get failedToDeleteShelf;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting'**
  String get deleting;

  /// No description provided for @successfullyEditedShelf.
  ///
  /// In en, this message translates to:
  /// **'Successfully edited shelf'**
  String get successfullyEditedShelf;

  /// No description provided for @failedToEditShelf.
  ///
  /// In en, this message translates to:
  /// **'Failed to edit shelf'**
  String get failedToEditShelf;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editing.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get editing;

  /// No description provided for @deleteShelfConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the shelf {name}?'**
  String deleteShelfConfirmation(Object name);

  /// No description provided for @addBooksToShelf.
  ///
  /// In en, this message translates to:
  /// **'Add books to shelf'**
  String get addBooksToShelf;

  /// No description provided for @shelfIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Shelf is empty'**
  String get shelfIsEmpty;

  /// No description provided for @removing.
  ///
  /// In en, this message translates to:
  /// **'Removing'**
  String get removing;

  /// No description provided for @manageBookShelves.
  ///
  /// In en, this message translates to:
  /// **'Manage book shelves'**
  String get manageBookShelves;

  /// No description provided for @bookInShelfs.
  ///
  /// In en, this message translates to:
  /// **'Book in {count, plural, =1{one shelf} other{{count} shelves}}'**
  String bookInShelfs(num count);

  /// No description provided for @searchForBooks.
  ///
  /// In en, this message translates to:
  /// **'Search for books'**
  String get searchForBooks;

  /// No description provided for @connectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Connection settings'**
  String get connectionSettings;

  /// No description provided for @costumHttpPHeader.
  ///
  /// In en, this message translates to:
  /// **'Custom HTTP-Header'**
  String get costumHttpPHeader;

  /// No description provided for @addHeader.
  ///
  /// In en, this message translates to:
  /// **'Add header'**
  String get addHeader;

  /// No description provided for @httpHeader.
  ///
  /// In en, this message translates to:
  /// **'HTTP-Header'**
  String get httpHeader;

  /// No description provided for @addACostumHttpHeaderThatWillBeSentWithEveryRequest.
  ///
  /// In en, this message translates to:
  /// **'Add a custom HTTP-Header that will be sent with every request'**
  String get addACostumHttpHeaderThatWillBeSentWithEveryRequest;

  /// No description provided for @noCostumHttpHeadersYet.
  ///
  /// In en, this message translates to:
  /// **'No custom HTTP-Header yet'**
  String get noCostumHttpHeadersYet;

  /// No description provided for @header.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get header;

  /// No description provided for @headerKey.
  ///
  /// In en, this message translates to:
  /// **'Header key'**
  String get headerKey;

  /// No description provided for @headerValue.
  ///
  /// In en, this message translates to:
  /// **'Header value'**
  String get headerValue;

  /// No description provided for @deleteHeader.
  ///
  /// In en, this message translates to:
  /// **'Delete header'**
  String get deleteHeader;

  /// No description provided for @urlMustStartWithHttpOrHttps.
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://'**
  String get urlMustStartWithHttpOrHttps;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @httpHeaderSettings.
  ///
  /// In en, this message translates to:
  /// **'Authentication settings'**
  String get httpHeaderSettings;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report issue'**
  String get reportIssue;

  /// No description provided for @reportAppIssueOrSuggestFeature.
  ///
  /// In en, this message translates to:
  /// **'Report app issue or suggest feature'**
  String get reportAppIssueOrSuggestFeature;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @bookActions.
  ///
  /// In en, this message translates to:
  /// **'Book actions'**
  String get bookActions;

  /// No description provided for @openBookInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open book in browser'**
  String get openBookInBrowser;

  /// No description provided for @metadataUpdateSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Metadata updated successfully'**
  String get metadataUpdateSuccessfully;

  /// No description provided for @editBookMetadata.
  ///
  /// In en, this message translates to:
  /// **'Edit book metadata'**
  String get editBookMetadata;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @separateWithCommas.
  ///
  /// In en, this message translates to:
  /// **'Separate with commas'**
  String get separateWithCommas;

  /// No description provided for @separateWithAnd.
  ///
  /// In en, this message translates to:
  /// **'Separate with \'&\''**
  String get separateWithAnd;

  /// No description provided for @ratingOneToTen.
  ///
  /// In en, this message translates to:
  /// **'Rating (1-10)'**
  String get ratingOneToTen;

  /// No description provided for @markedAsReadSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Marked as read successfully'**
  String get markedAsReadSuccessfully;

  /// No description provided for @markedAsReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark as read'**
  String get markedAsReadFailed;

  /// No description provided for @markedAsUnreadSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Marked as unread successfully'**
  String get markedAsUnreadSuccessfully;

  /// No description provided for @markedAsUnreadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark as unread'**
  String get markedAsUnreadFailed;

  /// No description provided for @archivedBookSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Archived book successfully'**
  String get archivedBookSuccessfully;

  /// No description provided for @archivedBookFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to archive book'**
  String get archivedBookFailed;

  /// No description provided for @unarchivedBookSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Unarchived book successfully'**
  String get unarchivedBookSuccessfully;

  /// No description provided for @unarchivedBookFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unarchive book'**
  String get unarchivedBookFailed;

  /// No description provided for @themeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme color'**
  String get themeColor;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @systemThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'The app will use the system theme'**
  String get systemThemeDescription;

  /// No description provided for @selectDownloadSchema.
  ///
  /// In en, this message translates to:
  /// **'Select download schema'**
  String get selectDownloadSchema;

  /// No description provided for @schemaFlat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get schemaFlat;

  /// No description provided for @schemaAuthorOnly.
  ///
  /// In en, this message translates to:
  /// **'Author only'**
  String get schemaAuthorOnly;

  /// No description provided for @schemaAuthorBook.
  ///
  /// In en, this message translates to:
  /// **'Author/Book'**
  String get schemaAuthorBook;

  /// No description provided for @schemaAuthorSeriesBook.
  ///
  /// In en, this message translates to:
  /// **'Author/Series/Book'**
  String get schemaAuthorSeriesBook;

  /// No description provided for @lightGreen.
  ///
  /// In en, this message translates to:
  /// **'Light green'**
  String get lightGreen;

  /// No description provided for @amber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get amber;

  /// No description provided for @blueGrey.
  ///
  /// In en, this message translates to:
  /// **'Blue grey'**
  String get blueGrey;

  /// No description provided for @grey.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get grey;

  /// No description provided for @lightBlue.
  ///
  /// In en, this message translates to:
  /// **'Light blue'**
  String get lightBlue;

  /// No description provided for @lime.
  ///
  /// In en, this message translates to:
  /// **'Lime'**
  String get lime;

  /// No description provided for @teal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get teal;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @bookRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Book recommendations'**
  String get bookRecommendations;

  /// No description provided for @recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// No description provided for @selectABookFromYourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Select a read book from your library'**
  String get selectABookFromYourLibrary;

  /// No description provided for @searchRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Search recommendations'**
  String get searchRecommendations;

  /// No description provided for @selectBook.
  ///
  /// In en, this message translates to:
  /// **'Select book'**
  String get selectBook;

  /// No description provided for @selectABookToGetRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Select a book to get recommendations'**
  String get selectABookToGetRecommendations;

  /// No description provided for @noRecommendationsFoundForThisBook.
  ///
  /// In en, this message translates to:
  /// **'No recommendations found for this book'**
  String get noRecommendationsFoundForThisBook;

  /// No description provided for @bookRecommendationsInfo1.
  ///
  /// In en, this message translates to:
  /// **'Book recommendations are fetched from '**
  String get bookRecommendationsInfo1;

  /// No description provided for @bookRecommendationsInfo2.
  ///
  /// In en, this message translates to:
  /// **' and work best with English book titles.'**
  String get bookRecommendationsInfo2;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noMatchingBooksFound.
  ///
  /// In en, this message translates to:
  /// **'No matching books found'**
  String get noMatchingBooksFound;

  /// No description provided for @bookCouldNotBeFound.
  ///
  /// In en, this message translates to:
  /// **'Book could not be found'**
  String get bookCouldNotBeFound;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @recommendedBasedOn.
  ///
  /// In en, this message translates to:
  /// **'Recommended based on'**
  String get recommendedBasedOn;

  /// No description provided for @storagePermissionRequiredToSelectAFolder.
  ///
  /// In en, this message translates to:
  /// **'Storage permission required to select a folder'**
  String get storagePermissionRequiredToSelectAFolder;

  /// No description provided for @noFolderWasSelected.
  ///
  /// In en, this message translates to:
  /// **'No folder was selected'**
  String get noFolderWasSelected;

  /// No description provided for @folderSelectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Folder selected successfully'**
  String get folderSelectedSuccessfully;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @schemaWasSelectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Schema was selected successfully'**
  String get schemaWasSelectedSuccessfully;

  /// No description provided for @downloadSchema.
  ///
  /// In en, this message translates to:
  /// **'Download schema'**
  String get downloadSchema;

  /// No description provided for @noFolderSelected.
  ///
  /// In en, this message translates to:
  /// **'No folder selected'**
  String get noFolderSelected;

  /// No description provided for @downloadFolder.
  ///
  /// In en, this message translates to:
  /// **'Download folder'**
  String get downloadFolder;

  /// No description provided for @openInReader.
  ///
  /// In en, this message translates to:
  /// **'Open in reader'**
  String get openInReader;

  /// No description provided for @bookOpenedExternallySuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Book opened externally successfully'**
  String get bookOpenedExternallySuccessfully;

  /// No description provided for @openBookExternallyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open book externally'**
  String get openBookExternallyFailed;

  /// No description provided for @headers.
  ///
  /// In en, this message translates to:
  /// **'HTTP Headers'**
  String get headers;

  /// No description provided for @authSystems.
  ///
  /// In en, this message translates to:
  /// **'Authentication Systems'**
  String get authSystems;

  /// No description provided for @webViewAuth.
  ///
  /// In en, this message translates to:
  /// **'WebView Authentication'**
  String get webViewAuth;

  /// No description provided for @basePath.
  ///
  /// In en, this message translates to:
  /// **'Base Path'**
  String get basePath;

  /// No description provided for @authSystem.
  ///
  /// In en, this message translates to:
  /// **'Authentication System'**
  String get authSystem;

  /// No description provided for @authSystemDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the authentication system used by your Calibre Web instance'**
  String get authSystemDescription;

  /// No description provided for @webViewAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Browser-Based Authentication'**
  String get webViewAuthentication;

  /// No description provided for @browserBasedAuth.
  ///
  /// In en, this message translates to:
  /// **'Authentication via Browser'**
  String get browserBasedAuth;

  /// No description provided for @webViewAuthDescription.
  ///
  /// In en, this message translates to:
  /// **'Log in using a browser for advanced authentication systems like SSO'**
  String get webViewAuthDescription;

  /// No description provided for @webViewSessionActive.
  ///
  /// In en, this message translates to:
  /// **'Active browser session detected'**
  String get webViewSessionActive;

  /// No description provided for @webViewSessionInactive.
  ///
  /// In en, this message translates to:
  /// **'No active browser session found'**
  String get webViewSessionInactive;

  /// No description provided for @lastAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Last Authentication:'**
  String get lastAuthentication;

  /// No description provided for @authenticate.
  ///
  /// In en, this message translates to:
  /// **'Authenticate'**
  String get authenticate;

  /// No description provided for @clearSession.
  ///
  /// In en, this message translates to:
  /// **'Clear Session'**
  String get clearSession;

  /// No description provided for @authenticationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Authentication was successful'**
  String get authenticationSuccessful;

  /// No description provided for @sessionCleared.
  ///
  /// In en, this message translates to:
  /// **'Session has been cleared'**
  String get sessionCleared;

  /// No description provided for @webViewAuthInstructions.
  ///
  /// In en, this message translates to:
  /// **'Login Instructions'**
  String get webViewAuthInstructions;

  /// No description provided for @webViewSessionSaved.
  ///
  /// In en, this message translates to:
  /// **'Browser session saved successfully'**
  String get webViewSessionSaved;

  /// No description provided for @saveSession.
  ///
  /// In en, this message translates to:
  /// **'Save Session'**
  String get saveSession;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @homePage.
  ///
  /// In en, this message translates to:
  /// **'Home Page'**
  String get homePage;

  /// No description provided for @serverUrlMissing.
  ///
  /// In en, this message translates to:
  /// **'Server URL is missing'**
  String get serverUrlMissing;

  /// No description provided for @pleaseConfigureServerURL.
  ///
  /// In en, this message translates to:
  /// **'Please configure the server URL in the settings first'**
  String get pleaseConfigureServerURL;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @helpAndInfo.
  ///
  /// In en, this message translates to:
  /// **'Help & Information'**
  String get helpAndInfo;

  /// No description provided for @authSystemHelp1.
  ///
  /// In en, this message translates to:
  /// **'Authentication systems may require specific HTTP headers.'**
  String get authSystemHelp1;

  /// No description provided for @authSystemHelp2.
  ///
  /// In en, this message translates to:
  /// **'Predefined configurations are available for common systems.'**
  String get authSystemHelp2;

  /// No description provided for @authSystemHelp3.
  ///
  /// In en, this message translates to:
  /// **'You can customize headers in the Headers tab.'**
  String get authSystemHelp3;

  /// No description provided for @authSystemHelp4.
  ///
  /// In en, this message translates to:
  /// **'For advanced systems, use WebView Authentication instead.'**
  String get authSystemHelp4;

  /// No description provided for @webViewHelp1.
  ///
  /// In en, this message translates to:
  /// **'Browser-based authentication is ideal for SSO and advanced systems.'**
  String get webViewHelp1;

  /// No description provided for @webViewHelp2.
  ///
  /// In en, this message translates to:
  /// **'The session is saved and reused for future requests.'**
  String get webViewHelp2;

  /// No description provided for @webViewHelp3.
  ///
  /// In en, this message translates to:
  /// **'Sessions may expire after a certain period.'**
  String get webViewHelp3;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSaved;

  /// No description provided for @send2ereaderService.
  ///
  /// In en, this message translates to:
  /// **'Send2Ereader service'**
  String get send2ereaderService;

  /// No description provided for @send2ereaderServiceUrl.
  ///
  /// In en, this message translates to:
  /// **'Send2Ereader service URL'**
  String get send2ereaderServiceUrl;

  /// No description provided for @enterUrlOfYourSend2ereaderService.
  ///
  /// In en, this message translates to:
  /// **'Enter the URL of your Send2Ereader service'**
  String get enterUrlOfYourSend2ereaderService;

  /// No description provided for @noFilesSelected.
  ///
  /// In en, this message translates to:
  /// **'No files selected'**
  String get noFilesSelected;

  /// No description provided for @preparingUpload.
  ///
  /// In en, this message translates to:
  /// **'Preparing upload'**
  String get preparingUpload;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @uploadingBook.
  ///
  /// In en, this message translates to:
  /// **'Uploading book'**
  String get uploadingBook;

  /// No description provided for @columnsCount.
  ///
  /// In en, this message translates to:
  /// **'Columns count'**
  String get columnsCount;

  /// No description provided for @columns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get columns;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listView;

  /// No description provided for @uploadEbook.
  ///
  /// In en, this message translates to:
  /// **'Upload eBook'**
  String get uploadEbook;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logoutFailed;

  /// No description provided for @shelfNotFound.
  ///
  /// In en, this message translates to:
  /// **'Shelf not found'**
  String get shelfNotFound;

  /// No description provided for @titleIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleIsRequired;

  /// No description provided for @descriptionIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionIsRequired;

  /// No description provided for @downloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled'**
  String get downloadCancelled;

  /// No description provided for @transferCancelled.
  ///
  /// In en, this message translates to:
  /// **'Transfer cancelled'**
  String get transferCancelled;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @basePathTitle.
  ///
  /// In en, this message translates to:
  /// **'API Base Path'**
  String get basePathTitle;

  /// No description provided for @basePathLabel.
  ///
  /// In en, this message translates to:
  /// **'Base Path'**
  String get basePathLabel;

  /// No description provided for @basePathHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., /opds or /calibre'**
  String get basePathHint;

  /// No description provided for @basePathDescription.
  ///
  /// In en, this message translates to:
  /// **'Define a custom base path for API requests'**
  String get basePathDescription;

  /// No description provided for @bookCover.
  ///
  /// In en, this message translates to:
  /// **'Book cover'**
  String get bookCover;

  /// No description provided for @currentCover.
  ///
  /// In en, this message translates to:
  /// **'Current cover'**
  String get currentCover;

  /// No description provided for @newCover.
  ///
  /// In en, this message translates to:
  /// **'New cover'**
  String get newCover;

  /// No description provided for @selectCover.
  ///
  /// In en, this message translates to:
  /// **'Select cover'**
  String get selectCover;

  /// No description provided for @removeCover.
  ///
  /// In en, this message translates to:
  /// **'Remove cover'**
  String get removeCover;

  /// No description provided for @removeCoverConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the cover?'**
  String get removeCoverConfirmation;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @noCover.
  ///
  /// In en, this message translates to:
  /// **'No cover'**
  String get noCover;

  /// No description provided for @loadingBooks.
  ///
  /// In en, this message translates to:
  /// **'Loading books...'**
  String get loadingBooks;

  /// No description provided for @sucessfullyUploadedBook.
  ///
  /// In en, this message translates to:
  /// **'Successfully uploaded book'**
  String get sucessfullyUploadedBook;

  /// No description provided for @sslSettings.
  ///
  /// In en, this message translates to:
  /// **'SSL Settings'**
  String get sslSettings;

  /// No description provided for @sslCertificate.
  ///
  /// In en, this message translates to:
  /// **'SSL Certificate'**
  String get sslCertificate;

  /// No description provided for @settingsForSSL.
  ///
  /// In en, this message translates to:
  /// **'Settings for SSL certificate'**
  String get settingsForSSL;

  /// No description provided for @allowSelfSignedCertificates.
  ///
  /// In en, this message translates to:
  /// **'Allow self-signed certificates'**
  String get allowSelfSignedCertificates;

  /// No description provided for @allowUnsafeConnections.
  ///
  /// In en, this message translates to:
  /// **'Allow unsafe connections'**
  String get allowUnsafeConnections;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @attentionSSLCertificate.
  ///
  /// In en, this message translates to:
  /// **'Attention: Self-signed certificates can be insecure. Use them only if you understand the risks.'**
  String get attentionSSLCertificate;

  /// No description provided for @ssoLogin.
  ///
  /// In en, this message translates to:
  /// **'SSO-Login'**
  String get ssoLogin;

  /// No description provided for @pleaseLoginWithYourSSOAccount.
  ///
  /// In en, this message translates to:
  /// **'Please login with your SSO account. You will be redirected back to the app after successful login.'**
  String get pleaseLoginWithYourSSOAccount;

  /// No description provided for @loginWithSSO.
  ///
  /// In en, this message translates to:
  /// **'Login with SSO'**
  String get loginWithSSO;

  /// No description provided for @pleaseEnterSSOUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter the SSO URL'**
  String get pleaseEnterSSOUrl;

  /// No description provided for @openInInternalReader.
  ///
  /// In en, this message translates to:
  /// **'Open in Internal Reader'**
  String get openInInternalReader;

  /// No description provided for @errorOpeningBookInInternalReader.
  ///
  /// In en, this message translates to:
  /// **'Error opening book in internal reader'**
  String get errorOpeningBookInInternalReader;

  /// No description provided for @readNow.
  ///
  /// In en, this message translates to:
  /// **'Read Now'**
  String get readNow;

  /// No description provided for @showReadNowButton.
  ///
  /// In en, this message translates to:
  /// **'Show \'Read Now\' button'**
  String get showReadNowButton;

  /// No description provided for @showReadNowButtonDescription.
  ///
  /// In en, this message translates to:
  /// **'Replaces the \'Send to E-Reader\' button with a \'Read Now\' button to open books directly.'**
  String get showReadNowButtonDescription;

  /// No description provided for @bookDetails.
  ///
  /// In en, this message translates to:
  /// **'Book Details'**
  String get bookDetails;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @contentType.
  ///
  /// In en, this message translates to:
  /// **'Content Type'**
  String get contentType;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @searchFilters.
  ///
  /// In en, this message translates to:
  /// **'Search Filters'**
  String get searchFilters;

  /// No description provided for @bookFiction.
  ///
  /// In en, this message translates to:
  /// **'Book (Fiction)'**
  String get bookFiction;

  /// No description provided for @bookNonFiction.
  ///
  /// In en, this message translates to:
  /// **'Book (Non-Fiction)'**
  String get bookNonFiction;

  /// No description provided for @magazine.
  ///
  /// In en, this message translates to:
  /// **'Magazine'**
  String get magazine;

  /// No description provided for @comic.
  ///
  /// In en, this message translates to:
  /// **'Comic'**
  String get comic;

  /// No description provided for @audiobook.
  ///
  /// In en, this message translates to:
  /// **'Audiobook'**
  String get audiobook;

  /// No description provided for @sectionDisabledOrNotFound.
  ///
  /// In en, this message translates to:
  /// **'Section unavailable'**
  String get sectionDisabledOrNotFound;

  /// No description provided for @sectionDisabledDescription.
  ///
  /// In en, this message translates to:
  /// **'This section appears to be disabled in your Calibre-Web server settings or does not exist.'**
  String get sectionDisabledDescription;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @libraries.
  ///
  /// In en, this message translates to:
  /// **'Libraries'**
  String get libraries;

  /// No description provided for @browsLibraries.
  ///
  /// In en, this message translates to:
  /// **'Browse Libraries'**
  String get browsLibraries;

  /// No description provided for @surpriseMe.
  ///
  /// In en, this message translates to:
  /// **'Surprise Me'**
  String get surpriseMe;

  /// No description provided for @downloadOptions.
  ///
  /// In en, this message translates to:
  /// **'Download Options'**
  String get downloadOptions;

  /// No description provided for @customSend2EReader.
  ///
  /// In en, this message translates to:
  /// **'Custom Send2Ereader'**
  String get customSend2EReader;

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testing;

  /// No description provided for @saveCredentials.
  ///
  /// In en, this message translates to:
  /// **'Save Credentials'**
  String get saveCredentials;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @appendsBookLorePath.
  ///
  /// In en, this message translates to:
  /// **'Appends \'/api/v1/opds\' to the BookLore URL if not present.'**
  String get appendsBookLorePath;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @syncsReadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncs reading progress across devices via a JSON file on your WebDAV storage.'**
  String get syncsReadingProgress;

  /// No description provided for @webDavSync.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Sync'**
  String get webDavSync;

  /// No description provided for @pleaseFillInAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields.'**
  String get pleaseFillInAllRequiredFields;

  /// No description provided for @connectionTestSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connection test successful. Press Save to apply the credentials.'**
  String get connectionTestSuccessful;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed:'**
  String get loginFailed;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @pleaseEnterWebDavUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid WebDAV URL'**
  String get pleaseEnterWebDavUrl;

  /// No description provided for @loginSuccessfull.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccessfull;

  /// No description provided for @enterUsernamePasswordForSSO.
  ///
  /// In en, this message translates to:
  /// **'Since Calibre Web Companion uses many OPDS endpoints to provide different features, and OPDS currently only works with username/password authentication, you need to provide your credentials, even when using SSO. We know that this goes against the purpose of SSO, but it is necessary for the app to function correctly. Hopefully, future versions will offer a better solution.'**
  String get enterUsernamePasswordForSSO;

  /// No description provided for @credentialsRequiredForSSO.
  ///
  /// In en, this message translates to:
  /// **'Credentials required for SSO'**
  String get credentialsRequiredForSSO;

  /// No description provided for @readerSettings.
  ///
  /// In en, this message translates to:
  /// **'Reader Settings'**
  String get readerSettings;

  /// No description provided for @scrollDirection.
  ///
  /// In en, this message translates to:
  /// **'Scroll Direction'**
  String get scrollDirection;

  /// No description provided for @vertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get vertical;

  /// No description provided for @horizontal.
  ///
  /// In en, this message translates to:
  /// **'Horizontal'**
  String get horizontal;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'et', 'fr', 'it', 'pt', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'et': return AppLocalizationsEt();
    case 'fr': return AppLocalizationsFr();
    case 'it': return AppLocalizationsIt();
    case 'pt': return AppLocalizationsPt();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
