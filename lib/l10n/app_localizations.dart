import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_it.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('it')];

  /// No description provided for @appTitle.
  ///
  /// In it, this message translates to:
  /// **'Donatello Lab'**
  String get appTitle;

  /// No description provided for @welcomeMessage.
  ///
  /// In it, this message translates to:
  /// **'Benvenuto nel laboratorio di Donatello'**
  String get welcomeMessage;

  /// No description provided for @loginTitle.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In it, this message translates to:
  /// **'Registrati'**
  String get registerTitle;

  /// No description provided for @emailHint.
  ///
  /// In it, this message translates to:
  /// **'Inserisci la tua email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In it, this message translates to:
  /// **'Inserisci la password'**
  String get passwordHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In it, this message translates to:
  /// **'Conferma password'**
  String get confirmPasswordHint;

  /// No description provided for @nameHint.
  ///
  /// In it, this message translates to:
  /// **'Nome'**
  String get nameHint;

  /// No description provided for @birthdateHint.
  ///
  /// In it, this message translates to:
  /// **'Data di nascita'**
  String get birthdateHint;

  /// No description provided for @agreeToTerms.
  ///
  /// In it, this message translates to:
  /// **'Accetto i termini e le condizioni'**
  String get agreeToTerms;

  /// No description provided for @loginButton.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In it, this message translates to:
  /// **'Registrati'**
  String get registerButton;

  /// No description provided for @generateGiftIdeas.
  ///
  /// In it, this message translates to:
  /// **'Genera Idee Regalo'**
  String get generateGiftIdeas;

  /// No description provided for @favoriteRecipients.
  ///
  /// In it, this message translates to:
  /// **'Destinatari Preferiti'**
  String get favoriteRecipients;

  /// No description provided for @popularGiftsThisMonth.
  ///
  /// In it, this message translates to:
  /// **'Regali Popolari Questo Mese'**
  String get popularGiftsThisMonth;

  /// No description provided for @recipients.
  ///
  /// In it, this message translates to:
  /// **'Destinatari'**
  String get recipients;

  /// No description provided for @savedGifts.
  ///
  /// In it, this message translates to:
  /// **'Regali Salvati'**
  String get savedGifts;

  /// No description provided for @homepage.
  ///
  /// In it, this message translates to:
  /// **'Homepage'**
  String get homepage;

  /// No description provided for @generate.
  ///
  /// In it, this message translates to:
  /// **'Genera'**
  String get generate;

  /// No description provided for @addRecipient.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi Destinatario'**
  String get addRecipient;

  /// No description provided for @male.
  ///
  /// In it, this message translates to:
  /// **'Uomo'**
  String get male;

  /// No description provided for @female.
  ///
  /// In it, this message translates to:
  /// **'Donna'**
  String get female;

  /// No description provided for @other.
  ///
  /// In it, this message translates to:
  /// **'Altro'**
  String get other;

  /// No description provided for @friend.
  ///
  /// In it, this message translates to:
  /// **'Amico'**
  String get friend;

  /// No description provided for @family.
  ///
  /// In it, this message translates to:
  /// **'Famiglia'**
  String get family;

  /// No description provided for @colleague.
  ///
  /// In it, this message translates to:
  /// **'Collega'**
  String get colleague;

  /// No description provided for @partner.
  ///
  /// In it, this message translates to:
  /// **'Partner'**
  String get partner;

  /// No description provided for @mentor.
  ///
  /// In it, this message translates to:
  /// **'Mentore'**
  String get mentor;

  /// No description provided for @interests.
  ///
  /// In it, this message translates to:
  /// **'Interessi'**
  String get interests;

  /// No description provided for @music.
  ///
  /// In it, this message translates to:
  /// **'Musica'**
  String get music;

  /// No description provided for @sports.
  ///
  /// In it, this message translates to:
  /// **'Sport'**
  String get sports;

  /// No description provided for @tech.
  ///
  /// In it, this message translates to:
  /// **'Tech'**
  String get tech;

  /// No description provided for @art.
  ///
  /// In it, this message translates to:
  /// **'Arte'**
  String get art;

  /// No description provided for @travel.
  ///
  /// In it, this message translates to:
  /// **'Viaggi'**
  String get travel;

  /// No description provided for @food.
  ///
  /// In it, this message translates to:
  /// **'Cibo'**
  String get food;

  /// No description provided for @fashion.
  ///
  /// In it, this message translates to:
  /// **'Moda'**
  String get fashion;

  /// No description provided for @reading.
  ///
  /// In it, this message translates to:
  /// **'Lettura'**
  String get reading;

  /// No description provided for @gaming.
  ///
  /// In it, this message translates to:
  /// **'Gaming'**
  String get gaming;

  /// No description provided for @astrology.
  ///
  /// In it, this message translates to:
  /// **'Astrologia'**
  String get astrology;

  /// No description provided for @dislikes.
  ///
  /// In it, this message translates to:
  /// **'Non gradisce'**
  String get dislikes;

  /// No description provided for @personalNotes.
  ///
  /// In it, this message translates to:
  /// **'Note personali'**
  String get personalNotes;

  /// No description provided for @whoIsThisGiftFor.
  ///
  /// In it, this message translates to:
  /// **'Per chi è questo regalo?'**
  String get whoIsThisGiftFor;

  /// No description provided for @recipientName.
  ///
  /// In it, this message translates to:
  /// **'Nome del destinatario'**
  String get recipientName;

  /// No description provided for @recipientAge.
  ///
  /// In it, this message translates to:
  /// **'Età del destinatario'**
  String get recipientAge;

  /// No description provided for @whatAreTheirPassions.
  ///
  /// In it, this message translates to:
  /// **'Quali sono le sue passioni?'**
  String get whatAreTheirPassions;

  /// No description provided for @selectAllThatApply.
  ///
  /// In it, this message translates to:
  /// **'Seleziona tutte quelle pertinenti'**
  String get selectAllThatApply;

  /// No description provided for @whatTypeOfGift.
  ///
  /// In it, this message translates to:
  /// **'Che tipo di regalo stai cercando?'**
  String get whatTypeOfGift;

  /// No description provided for @whatsYourBudget.
  ///
  /// In it, this message translates to:
  /// **'Qual è il tuo budget?'**
  String get whatsYourBudget;

  /// No description provided for @small.
  ///
  /// In it, this message translates to:
  /// **'Piccolo'**
  String get small;

  /// No description provided for @medium.
  ///
  /// In it, this message translates to:
  /// **'Medio'**
  String get medium;

  /// No description provided for @large.
  ///
  /// In it, this message translates to:
  /// **'Grande'**
  String get large;

  /// No description provided for @extraLarge.
  ///
  /// In it, this message translates to:
  /// **'Extra Grande'**
  String get extraLarge;

  /// No description provided for @customBudget.
  ///
  /// In it, this message translates to:
  /// **'Budget personalizzato'**
  String get customBudget;

  /// No description provided for @next.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get next;

  /// No description provided for @back.
  ///
  /// In it, this message translates to:
  /// **'Indietro'**
  String get back;

  /// No description provided for @saveRecipient.
  ///
  /// In it, this message translates to:
  /// **'Salva Destinatario'**
  String get saveRecipient;

  /// No description provided for @giftIdeas.
  ///
  /// In it, this message translates to:
  /// **'Idee Regalo'**
  String get giftIdeas;

  /// No description provided for @loadMore.
  ///
  /// In it, this message translates to:
  /// **'Carica Altro'**
  String get loadMore;

  /// No description provided for @noSavedGifts.
  ///
  /// In it, this message translates to:
  /// **'Nessun regalo salvato'**
  String get noSavedGifts;

  /// No description provided for @savedGiftsWillAppearHere.
  ///
  /// In it, this message translates to:
  /// **'I regali salvati appariranno qui'**
  String get savedGiftsWillAppearHere;

  /// No description provided for @error.
  ///
  /// In it, this message translates to:
  /// **'Errore'**
  String get error;

  /// No description provided for @success.
  ///
  /// In it, this message translates to:
  /// **'Successo'**
  String get success;

  /// No description provided for @giftSavedSuccessfully.
  ///
  /// In it, this message translates to:
  /// **'Regalo salvato con successo!'**
  String get giftSavedSuccessfully;

  /// No description provided for @recipientAddedSuccessfully.
  ///
  /// In it, this message translates to:
  /// **'Destinatario aggiunto con successo!'**
  String get recipientAddedSuccessfully;

  /// No description provided for @pleaseEnterRecipientName.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il nome del destinatario'**
  String get pleaseEnterRecipientName;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In it, this message translates to:
  /// **'Le password non corrispondono'**
  String get passwordsDontMatch;

  /// No description provided for @mustAgreeToTerms.
  ///
  /// In it, this message translates to:
  /// **'Devi accettare i termini e condizioni'**
  String get mustAgreeToTerms;

  /// No description provided for @welcomeToDonatelloLab.
  ///
  /// In it, this message translates to:
  /// **'Benvenuto a Donatello Lab'**
  String get welcomeToDonatelloLab;

  /// No description provided for @letsCreatePerfectGift.
  ///
  /// In it, this message translates to:
  /// **'Creiamo insieme il regalo perfetto. Condividi alcuni dettagli e la nostra AI genererà idee uniche su misura per il tuo destinatario.'**
  String get letsCreatePerfectGift;

  /// No description provided for @start.
  ///
  /// In it, this message translates to:
  /// **'Inizia'**
  String get start;

  /// No description provided for @hello.
  ///
  /// In it, this message translates to:
  /// **'Ciao'**
  String get hello;

  /// No description provided for @artist.
  ///
  /// In it, this message translates to:
  /// **'Artista'**
  String get artist;

  /// No description provided for @yearsOld.
  ///
  /// In it, this message translates to:
  /// **'anni'**
  String get yearsOld;

  /// No description provided for @forRecipient.
  ///
  /// In it, this message translates to:
  /// **'Per'**
  String get forRecipient;

  /// No description provided for @step.
  ///
  /// In it, this message translates to:
  /// **'Passo'**
  String get step;

  /// No description provided for @labelOf.
  ///
  /// In it, this message translates to:
  /// **'di'**
  String get labelOf;

  /// No description provided for @addCustomInterest.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi interesse personalizzato'**
  String get addCustomInterest;

  /// No description provided for @home.
  ///
  /// In it, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @books.
  ///
  /// In it, this message translates to:
  /// **'Libri'**
  String get books;

  /// No description provided for @experiences.
  ///
  /// In it, this message translates to:
  /// **'Esperienze'**
  String get experiences;

  /// No description provided for @loadingMoreIdeas.
  ///
  /// In it, this message translates to:
  /// **'Caricamento di altre idee...'**
  String get loadingMoreIdeas;

  /// No description provided for @help.
  ///
  /// In it, this message translates to:
  /// **'Aiuto'**
  String get help;

  /// No description provided for @welcomeBack.
  ///
  /// In it, this message translates to:
  /// **'Bentornato'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In it, this message translates to:
  /// **'Accedi per continuare su Donatello Lab'**
  String get signInToContinue;

  /// No description provided for @signIn.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get signIn;

  /// No description provided for @forgotPassword.
  ///
  /// In it, this message translates to:
  /// **'Password dimenticata?'**
  String get forgotPassword;

  /// No description provided for @or.
  ///
  /// In it, this message translates to:
  /// **'oppure'**
  String get or;

  /// No description provided for @createAccount.
  ///
  /// In it, this message translates to:
  /// **'Crea Account'**
  String get createAccount;

  /// No description provided for @joinDonatelloLab.
  ///
  /// In it, this message translates to:
  /// **'Unisciti a Donatello Lab'**
  String get joinDonatelloLab;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Crea il tuo account per iniziare a trovare regali perfetti'**
  String get createAccountSubtitle;

  /// No description provided for @firstName.
  ///
  /// In it, this message translates to:
  /// **'Nome'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In it, this message translates to:
  /// **'Cognome'**
  String get lastName;

  /// No description provided for @emailAddress.
  ///
  /// In it, this message translates to:
  /// **'Indirizzo email'**
  String get emailAddress;

  /// No description provided for @birthDate.
  ///
  /// In it, this message translates to:
  /// **'Data di nascita (gg/mm/aaaa)'**
  String get birthDate;

  /// No description provided for @passwordMinChars.
  ///
  /// In it, this message translates to:
  /// **'Password (min. 6 caratteri)'**
  String get passwordMinChars;

  /// No description provided for @confirmPassword.
  ///
  /// In it, this message translates to:
  /// **'Conferma password'**
  String get confirmPassword;

  /// No description provided for @iAgreeToTerms.
  ///
  /// In it, this message translates to:
  /// **'Accetto i termini e le condizioni'**
  String get iAgreeToTerms;

  /// No description provided for @readTermsOf.
  ///
  /// In it, this message translates to:
  /// **'Leggi '**
  String get readTermsOf;

  /// No description provided for @termsOfUse.
  ///
  /// In it, this message translates to:
  /// **'condizioni d\'uso'**
  String get termsOfUse;

  /// No description provided for @and.
  ///
  /// In it, this message translates to:
  /// **' e '**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In it, this message translates to:
  /// **'informativa sulla privacy'**
  String get privacyPolicy;

  /// No description provided for @ageConfirmation.
  ///
  /// In it, this message translates to:
  /// **'Confermo di avere almeno 13 anni e accetto che i miei dati vengano elaborati secondo l\'informativa sulla privacy per ricevere idee regalo personalizzate.'**
  String get ageConfirmation;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In it, this message translates to:
  /// **'Hai già un account? '**
  String get alreadyHaveAccount;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il tuo indirizzo email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un indirizzo email valido'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In it, this message translates to:
  /// **'Inserisci la tua password'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseEnterFirstName.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il tuo nome'**
  String get pleaseEnterFirstName;

  /// No description provided for @pleaseEnterLastName.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il tuo cognome'**
  String get pleaseEnterLastName;

  /// No description provided for @pleaseEnterBirthDate.
  ///
  /// In it, this message translates to:
  /// **'Inserisci la tua data di nascita'**
  String get pleaseEnterBirthDate;

  /// No description provided for @pleaseEnterValidDate.
  ///
  /// In it, this message translates to:
  /// **'Inserisci una data valida (gg/mm/aaaa)'**
  String get pleaseEnterValidDate;

  /// No description provided for @passwordMinLength.
  ///
  /// In it, this message translates to:
  /// **'La password deve essere di almeno 6 caratteri'**
  String get passwordMinLength;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In it, this message translates to:
  /// **'Conferma la tua password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In it, this message translates to:
  /// **'Le password non corrispondono'**
  String get passwordsDoNotMatch;

  /// No description provided for @mustAgreeToTermsAndConditions.
  ///
  /// In it, this message translates to:
  /// **'Devi accettare i termini e le condizioni'**
  String get mustAgreeToTermsAndConditions;

  /// No description provided for @loginFailed.
  ///
  /// In it, this message translates to:
  /// **'Accesso fallito. Riprova.'**
  String get loginFailed;

  /// No description provided for @registrationFailed.
  ///
  /// In it, this message translates to:
  /// **'Registrazione fallita. Riprova.'**
  String get registrationFailed;

  /// No description provided for @connectionError.
  ///
  /// In it, this message translates to:
  /// **'Errore di connessione. Riprova.'**
  String get connectionError;

  /// No description provided for @incorrectEmailOrPassword.
  ///
  /// In it, this message translates to:
  /// **'Email o password non corretti'**
  String get incorrectEmailOrPassword;

  /// No description provided for @serviceUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Servizio non disponibile'**
  String get serviceUnavailable;

  /// No description provided for @serverError.
  ///
  /// In it, this message translates to:
  /// **'Errore del server. Riprova più tardi'**
  String get serverError;

  /// No description provided for @connectionProblem.
  ///
  /// In it, this message translates to:
  /// **'Problema di connessione. Controlla la tua rete'**
  String get connectionProblem;

  /// No description provided for @errorDuringRegistration.
  ///
  /// In it, this message translates to:
  /// **'Errore durante la registrazione. Riprova.'**
  String get errorDuringRegistration;

  /// No description provided for @invalidData.
  ///
  /// In it, this message translates to:
  /// **'Dati non validi. Controlla i campi inseriti'**
  String get invalidData;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In it, this message translates to:
  /// **'Email già registrata. Prova con un\'altra email'**
  String get emailAlreadyRegistered;

  /// No description provided for @enterBirthDateError.
  ///
  /// In it, this message translates to:
  /// **'Inserisci la tua data di nascita'**
  String get enterBirthDateError;

  /// No description provided for @validDateError.
  ///
  /// In it, this message translates to:
  /// **'Inserisci una data valida (gg/mm/aaaa)'**
  String get validDateError;

  /// No description provided for @preparingExperience.
  ///
  /// In it, this message translates to:
  /// **'Preparando la tua esperienza...'**
  String get preparingExperience;

  /// No description provided for @checkYourEmail.
  ///
  /// In it, this message translates to:
  /// **'Controlla la tua email'**
  String get checkYourEmail;

  /// No description provided for @resetPassword.
  ///
  /// In it, this message translates to:
  /// **'Reimposta Password'**
  String get resetPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In it, this message translates to:
  /// **'Password dimenticata?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Non preoccuparti! Inserisci il tuo indirizzo email e ti invieremo un link per reimpostare la password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @emailSentTo.
  ///
  /// In it, this message translates to:
  /// **'Abbiamo inviato un link per reimpostare la password a'**
  String get emailSentTo;

  /// No description provided for @sendResetLink.
  ///
  /// In it, this message translates to:
  /// **'Invia Link di Reset'**
  String get sendResetLink;

  /// No description provided for @emailSentSuccessfully.
  ///
  /// In it, this message translates to:
  /// **'Email inviata con successo!'**
  String get emailSentSuccessfully;

  /// No description provided for @checkInboxInstructions.
  ///
  /// In it, this message translates to:
  /// **'Controlla la tua casella di posta e segui le istruzioni per reimpostare la password.'**
  String get checkInboxInstructions;

  /// No description provided for @backToLogin.
  ///
  /// In it, this message translates to:
  /// **'Torna al Login'**
  String get backToLogin;

  /// No description provided for @sendToDifferentEmail.
  ///
  /// In it, this message translates to:
  /// **'Invia a email diversa'**
  String get sendToDifferentEmail;

  /// No description provided for @emailNotFound.
  ///
  /// In it, this message translates to:
  /// **'Indirizzo email non trovato'**
  String get emailNotFound;

  /// No description provided for @errorSendingResetEmail.
  ///
  /// In it, this message translates to:
  /// **'Errore nell\'invio dell\'email di reset. Riprova.'**
  String get errorSendingResetEmail;

  /// No description provided for @skip.
  ///
  /// In it, this message translates to:
  /// **'Salta'**
  String get skip;

  /// No description provided for @continue_.
  ///
  /// In it, this message translates to:
  /// **'Continua'**
  String get continue_;

  /// No description provided for @startExclamation.
  ///
  /// In it, this message translates to:
  /// **'Inizia!'**
  String get startExclamation;

  /// No description provided for @welcomeToDonatelloLabOnboarding.
  ///
  /// In it, this message translates to:
  /// **'Benvenuto in Donatello Lab'**
  String get welcomeToDonatelloLabOnboarding;

  /// No description provided for @discoverGiftPower.
  ///
  /// In it, this message translates to:
  /// **'Scopri il potere dell\'arte del regalo. Lascia che la genialità di Donatello ti guidi nella creazione di doni perfetti.'**
  String get discoverGiftPower;

  /// No description provided for @createRecipientProfile.
  ///
  /// In it, this message translates to:
  /// **'Crea il profilo del destinatario'**
  String get createRecipientProfile;

  /// No description provided for @addLovedOnesProfiles.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi i tuoi cari e costruisci profili dettagliati per ricevere suggerimenti sempre più personalizzati.'**
  String get addLovedOnesProfiles;

  /// No description provided for @artificialIntelligence.
  ///
  /// In it, this message translates to:
  /// **'Intelligenza Artificiale'**
  String get artificialIntelligence;

  /// No description provided for @aiAnalyzesInterests.
  ///
  /// In it, this message translates to:
  /// **'La nostra AI analizza interessi, relazioni e budget per suggerirti regali che toccheranno davvero il cuore.'**
  String get aiAnalyzesInterests;

  /// No description provided for @startCreatingMagic.
  ///
  /// In it, this message translates to:
  /// **'Inizia a creare magia'**
  String get startCreatingMagic;

  /// No description provided for @readyToTransform.
  ///
  /// In it, this message translates to:
  /// **'Sei pronto per trasformare ogni occasione in un momento indimenticabile. Iniziamo questo viaggio insieme!'**
  String get readyToTransform;

  /// No description provided for @goodMorning.
  ///
  /// In it, this message translates to:
  /// **'Buongiorno'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In it, this message translates to:
  /// **'Buon pomeriggio'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In it, this message translates to:
  /// **'Buonasera'**
  String get goodEvening;

  /// No description provided for @quickActions.
  ///
  /// In it, this message translates to:
  /// **'Azioni Rapide'**
  String get quickActions;

  /// No description provided for @letAiFindPerfectGift.
  ///
  /// In it, this message translates to:
  /// **'Lascia che l\'AI trovi il regalo perfetto'**
  String get letAiFindPerfectGift;

  /// No description provided for @recentRecipients.
  ///
  /// In it, this message translates to:
  /// **'Destinatari Recenti'**
  String get recentRecipients;

  /// No description provided for @viewAll.
  ///
  /// In it, this message translates to:
  /// **'Vedi Tutti'**
  String get viewAll;

  /// No description provided for @noRecipientsYet.
  ///
  /// In it, this message translates to:
  /// **'Nessun destinatario ancora'**
  String get noRecipientsYet;

  /// No description provided for @supportDonatello.
  ///
  /// In it, this message translates to:
  /// **'Supporta Donatello'**
  String get supportDonatello;

  /// No description provided for @discoverDonatello.
  ///
  /// In it, this message translates to:
  /// **'Scopri Donatello'**
  String get discoverDonatello;

  /// No description provided for @signOut.
  ///
  /// In it, this message translates to:
  /// **'Esci'**
  String get signOut;

  /// No description provided for @notificationsComingSoon.
  ///
  /// In it, this message translates to:
  /// **'Notifiche in arrivo'**
  String get notificationsComingSoon;

  /// No description provided for @cannotOpenSupportPage.
  ///
  /// In it, this message translates to:
  /// **'Impossibile aprire la pagina di supporto'**
  String get cannotOpenSupportPage;

  /// No description provided for @errorOpeningSupportPage.
  ///
  /// In it, this message translates to:
  /// **'Errore nell\'apertura della pagina di supporto'**
  String get errorOpeningSupportPage;

  /// No description provided for @cannotOpenWebsite.
  ///
  /// In it, this message translates to:
  /// **'Impossibile aprire il sito web'**
  String get cannotOpenWebsite;

  /// No description provided for @errorOpeningWebsite.
  ///
  /// In it, this message translates to:
  /// **'Errore nell\'apertura del sito web'**
  String get errorOpeningWebsite;

  /// No description provided for @noPopularGiftsAvailable.
  ///
  /// In it, this message translates to:
  /// **'Nessun regalo popolare disponibile'**
  String get noPopularGiftsAvailable;

  /// No description provided for @errorOpeningProduct.
  ///
  /// In it, this message translates to:
  /// **'Errore nell\'apertura del prodotto'**
  String get errorOpeningProduct;

  /// No description provided for @myProfile.
  ///
  /// In it, this message translates to:
  /// **'Il mio Profilo'**
  String get myProfile;

  /// No description provided for @shareProfile.
  ///
  /// In it, this message translates to:
  /// **'Condividi profilo'**
  String get shareProfile;

  /// No description provided for @featureComingSoon.
  ///
  /// In it, this message translates to:
  /// **'Funzionalità in arrivo!'**
  String get featureComingSoon;

  /// No description provided for @personalInformation.
  ///
  /// In it, this message translates to:
  /// **'Informazioni Personali'**
  String get personalInformation;

  /// No description provided for @contacts.
  ///
  /// In it, this message translates to:
  /// **'Contatti'**
  String get contacts;

  /// No description provided for @bio.
  ///
  /// In it, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @name.
  ///
  /// In it, this message translates to:
  /// **'Nome'**
  String get name;

  /// No description provided for @enterYourName.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il tuo nome'**
  String get enterYourName;

  /// No description provided for @surname.
  ///
  /// In it, this message translates to:
  /// **'Cognome'**
  String get surname;

  /// No description provided for @enterYourSurname.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il tuo cognome'**
  String get enterYourSurname;

  /// No description provided for @yourEmail.
  ///
  /// In it, this message translates to:
  /// **'La tua email'**
  String get yourEmail;

  /// No description provided for @phone.
  ///
  /// In it, this message translates to:
  /// **'Telefono'**
  String get phone;

  /// No description provided for @enterYourPhone.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il tuo numero di telefono'**
  String get enterYourPhone;

  /// No description provided for @biography.
  ///
  /// In it, this message translates to:
  /// **'Biografia'**
  String get biography;

  /// No description provided for @tellAboutYourself.
  ///
  /// In it, this message translates to:
  /// **'Racconta qualcosa di te...'**
  String get tellAboutYourself;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get save;

  /// No description provided for @nameRequired.
  ///
  /// In it, this message translates to:
  /// **'Il nome è obbligatorio'**
  String get nameRequired;

  /// No description provided for @surnameRequired.
  ///
  /// In it, this message translates to:
  /// **'Il cognome è obbligatorio'**
  String get surnameRequired;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In it, this message translates to:
  /// **'Errore nel caricamento del profilo:'**
  String get errorLoadingProfile;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In it, this message translates to:
  /// **'Profilo aggiornato con successo!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @errorUpdating.
  ///
  /// In it, this message translates to:
  /// **'Errore nell\'aggiornamento:'**
  String get errorUpdating;

  /// No description provided for @peopleInYourCircle.
  ///
  /// In it, this message translates to:
  /// **'persone nella tua cerchia'**
  String get peopleInYourCircle;

  /// No description provided for @personInYourCircle.
  ///
  /// In it, this message translates to:
  /// **'persona nella tua cerchia'**
  String get personInYourCircle;

  /// No description provided for @searchRecipients.
  ///
  /// In it, this message translates to:
  /// **'Cerca destinatari...'**
  String get searchRecipients;

  /// No description provided for @loadingRecipients.
  ///
  /// In it, this message translates to:
  /// **'Caricamento destinatari...'**
  String get loadingRecipients;

  /// No description provided for @noRecipients.
  ///
  /// In it, this message translates to:
  /// **'Nessun destinatario'**
  String get noRecipients;

  /// No description provided for @noRecipientsDescription.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi le persone per cui vuoi trovare il regalo perfetto. Più dettagli fornisci, migliori saranno i nostri suggerimenti!'**
  String get noRecipientsDescription;

  /// No description provided for @tip.
  ///
  /// In it, this message translates to:
  /// **'Consiglio'**
  String get tip;

  /// No description provided for @recipientTip.
  ///
  /// In it, this message translates to:
  /// **'Includi interessi, colori preferiti e cosa non gradiscono per suggerimenti più personalizzati.'**
  String get recipientTip;

  /// No description provided for @noResults.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato'**
  String get noResults;

  /// No description provided for @modifySearchTerms.
  ///
  /// In it, this message translates to:
  /// **'Prova a modificare i termini di ricerca'**
  String get modifySearchTerms;

  /// No description provided for @seeDetails.
  ///
  /// In it, this message translates to:
  /// **'Vedi dettagli'**
  String get seeDetails;

  /// No description provided for @removeGift.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi Regalo'**
  String get removeGift;

  /// No description provided for @confirmRemoveGift.
  ///
  /// In it, this message translates to:
  /// **'Sei sicuro di voler rimuovere questo regalo dai tuoi regali salvati?'**
  String get confirmRemoveGift;

  /// No description provided for @remove.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi'**
  String get remove;

  /// No description provided for @giftRemovedSuccessfully.
  ///
  /// In it, this message translates to:
  /// **'Regalo rimosso con successo'**
  String get giftRemovedSuccessfully;

  /// No description provided for @errorRemoving.
  ///
  /// In it, this message translates to:
  /// **'Errore nella rimozione del regalo'**
  String get errorRemoving;

  /// No description provided for @more.
  ///
  /// In it, this message translates to:
  /// **'altro'**
  String get more;

  /// No description provided for @profile.
  ///
  /// In it, this message translates to:
  /// **'Profilo'**
  String get profile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
