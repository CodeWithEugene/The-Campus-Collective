import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state.dart';

/// Lightweight, dependency-free localization for TCC.
///
/// Three flavors: english (default) · swahili · sheng. Every user-facing string
/// resolves through [L]. Missing sheng keys fall back to swahili; missing
/// swahili falls back to english. Use via `final t = ref.l10n;` then `t.chatHint`.
class L {
  final String flavor;
  const L(this.flavor);

  String _pick(String en, String sw, String? sheng) {
    switch (flavor) {
      case 'swahili':
        return sw;
      case 'sheng':
        return sheng ?? sw;
      default:
        return en;
    }
  }

  // ---- Navigation / tabs ----
  String get tabChat => _pick('Chat', 'Chat', 'Chat');
  String get tabFinance => _pick('Finance', 'Pesa', 'Hustle');
  String get tabSchedule => _pick('Schedule', 'Ratiba', 'Ratiba');
  String get tabMe => _pick('Me', 'Mimi', 'Mimi');

  // ---- Common actions ----
  String get save => _pick('Save', 'Hifadhi', 'Save');
  String get delete => _pick('Delete', 'Futa', 'Delete');
  String get cancel => _pick('Cancel', 'Ghairi', 'Cancel');
  String get retry => _pick('Try again', 'Jaribu tena', 'Jaribu tena');
  String get share => _pick('Share', 'Sambaza', 'Share');
  String get add => _pick('Add', 'Ongeza', 'Ongeza');
  String get done => _pick('Done', 'Imekamilika', 'Poa');
  String get next => _pick('Next', 'Endelea', 'Endelea');
  String get generate => _pick('Generate', 'Tengeneza', 'Tengeneza');
  String get copy => _pick('Copy', 'Nakili', 'Copy');
  String get retake => _pick('Retake', 'Piga tena', 'Piga tena');
  String get send => _pick('Send', 'Tuma', 'Tuma');

  // ---- Chat ----
  String get chatHint => _pick('Ask anything…', 'Uliza chochote…', 'Uliza chochote…');
  String greeting(bool kiembu, String kiembuWord) {
    final base = _pick('Hello', 'Habari', 'Niaje');
    return kiembu ? kiembuWord : base;
  }

  String get chatIntro => _pick(
        'I am TCC. Ask me about classes, finance, schedule, or campus paperwork.',
        'Mimi ni TCC. Niulize kuhusu masomo, fedha, ratiba au makaratasi ya chuo.',
        'Mimi ni TCC. Unaweza niuliza kuhusu masomo, pesa, ratiba ama makaratasi ya chuo.',
      );
  String get scanNotes => _pick('📸 Scan notes', '📸 Soma maelezo', '📸 Soma notes');
  String get feeStatement => _pick('📄 Fee statement', '📄 Kauli ya ada', '📄 Fee statement');
  String get createBudget => _pick('💰 Create budget', '💰 Tengeneza bajeti', '💰 Tengeneza budget');
  String get planDay => _pick('🗓️ Plan my day', '🗓️ Panga siku yangu', '🗓️ Panga siku yangu');

  // ---- Empty states ----
  String get noTasks => _pick("No tasks — you're free!", 'Hakuna kazi — uko huru!', "Hakuna tasks — uko free!");
  String get noBudget => _pick("No budget yet — let's make one", 'Hakuna bajeti bado — tutengeneze', "Hakuna budget bado — tuweke moja");
  String get noDeadlines => _pick('No deadlines tracked', 'Hakuna makataa yaliyowekwa', 'Hakuna deadlines');
  String get noScans => _pick('Your scans will live here', 'Picha zako zitakuwa hapa', 'Scans zako zitakuwa hapa');

  // ---- Ratiba ----
  String get goodMorning => _pick('Good morning', 'Habari ya asubuhi', 'Niaje asubuhi');
  String get goodAfternoon => _pick('Good afternoon', 'Habari ya mchana', 'Niaje mchana');
  String get goodEvening => _pick('Good evening', 'Habari ya jioni', 'Niaje jioni');
  String get generateDayPlan => _pick('Generate day plan', 'Tengeneza ratiba ya siku', 'Panga siku yangu');
  String get tasks => _pick('Tasks', 'Kazi', 'Tasks');
  String get deadlines => _pick('Deadlines', 'Makataa', 'Deadlines');
  String get timetable => _pick('Timetable', 'Ratiba ya masomo', 'Timetable');

  // ---- Karani ----
  String get explained => _pick('Explained', 'Imefafanuliwa', 'Imefafanuliwa');
  String get addToSchedule => _pick('Add to schedule', 'Weka kwa Ratiba', 'Weka kwa Ratiba');
  String get source => _pick('Source', 'Chanzo', 'Chanzo');
  String get verifyOffice => _pick(
        'Double-check this with the office — I might be wrong.',
        'Thibitisha na ofisi — naweza kuwa nimekosea.',
        'Confirm na ofisi — naweza kuwa nimekosea.',
      );
  String get findContacts => _pick('Contacts', 'Mawasiliano', 'Contacts');

  // ---- Somo ----
  String get summary => _pick('Summary', 'Muhtasari', 'Muhtasari');
  String get quiz => _pick('Quiz', 'Jaribio', 'Quiz');
  String get flashcards => _pick('Flashcards', 'Kadi', 'Flashcards');
  String get startQuiz => _pick('Start quiz', 'Anza jaribio', 'Anza Quiz');
  String question(int i, int n) => _pick('Question $i/$n', 'Swali $i/$n', 'Swali $i/$n');
  String score(int c, int n) => _pick('You got $c/$n', 'Umepata $c/$n', 'Umepata $c/$n');
  String get backToChat => _pick('Back to chat', 'Rudi kwa chat', 'Rudi kwa chat');
  String get keyPoints => _pick('Key points', 'Mambo muhimu', 'Mambo muhimu');
  String get inSimpleTerms => _pick('In simple terms', 'Kwa lugha rahisi', 'Kwa lugha rahisi');
  String get cards => _pick('Cards', 'Kadi', 'Cards');
  String get review => _pick('Review', 'Mapitio', 'Mapitio');
  String get takeAgain => _pick('Take again', 'Piga tena', 'Piga tena');

  // ---- Scan / capture ----
  String get reviewPhoto => _pick('Review photo', 'Kagua picha', 'Kagua picha');
  String get readingImage => _pick('Reading image…', 'Inasoma picha…', 'Inasoma picha…');
  String get oneMoment => _pick('One moment…', 'Subiri kidogo', 'Ngoja kidogo');
  String get rotate => _pick('Rotate', 'Zungusha', 'Zungusha');
  String get gallery => _pick('Gallery', 'Picha', 'Gallery');
  String get captionOptional => _pick('Caption (optional)', 'Maelezo (hiari)', 'Caption (optional)');
  String get captionHint => _pick(
        'Write something about this photo…',
        'Andika kitu kuhusu picha…',
        'Andika kitu kuhusu picha…',
      );
  String get scanFailed => _pick('Something went wrong. Try again.', 'Imeshindikana. Jaribu tena.', 'Imeshindikana. Jaribu tena.');

  // ---- Karani extras ----
  String get deadlineSaved => _pick('Deadline saved', 'Makataa yamehifadhiwa', 'Deadline imesave');
  String get shared => _pick('Shared', 'Imesambazwa', 'Imeshare');

  // ---- Mimi hub ----
  String get yourSpace => _pick('Your space', 'Nafasi yako', 'Space yako');
  String get yoursAlone => _pick('Everything here is yours alone.',
      'Kila kitu hapa ni chako pekee.', 'Kila kitu hapa ni chako pekee.');
  String get staysOnPhone => _pick('Everything stays on your phone',
      'Kila kitu kinabaki kwenye simu yako', 'Kila kitu kinabaki kwa simu yako');
  String get hubLibrarySub => _pick('Your saved notes, docs & receipts',
      'Maelezo, nyaraka na risiti zako zilizohifadhiwa', 'Notes na receipts zako');
  String get studySets => _pick('Study sets', 'Seti za masomo', 'Study sets');
  String get hubStudySub => _pick('Quizzes & flashcards from your notes',
      'Maswali na kadi kutoka maelezo yako', 'Quizzes na flashcards zako');
  String get hubSafetySub => _pick('Campus & national helplines — offline',
      'Nambari za usaidizi chuo na kitaifa — bila mtandao',
      'Helplines za chuo na kitaifa — offline');
  String get hubSettingsSub => _pick('Language, model, privacy & more',
      'Lugha, mfumo, faragha na mengineyo', 'Lugha, model, privacy na zaidi');
  String get settings => _pick('Settings', 'Mipangilio', 'Settings');

  // ---- Library ----
  String get library => _pick('Library', 'Maktaba', 'Library');
  String get searchScans =>
      _pick('Search your scans…', 'Tafuta picha zako…', 'Search scans zako…');
  String get nothingHere =>
      _pick('Nothing here yet', 'Hakuna kitu bado', 'Hakuna kitu bado');
  String get scansLiveHere => _pick(
      'Your scans will live here. Everything stays on your phone.',
      'Picha zako zitakuwa hapa. Kila kitu kinabaki kwenye simu yako.',
      'Scans zako zitakuwa hapa. Kila kitu kinabaki kwa simu yako.');
  String get scanSomething =>
      _pick('Scan something', 'Piga picha', 'Scan kitu');
  String get filterAll => _pick('All', 'Zote', 'All');
  String get filterNotes => _pick('Notes', 'Maelezo', 'Notes');
  String get filterDocs => _pick('Docs', 'Nyaraka', 'Docs');
  String get filterReceipts => _pick('Receipts', 'Risiti', 'Receipts');
  String get filterTimetables => _pick('Timetables', 'Ratiba', 'Timetables');
  String get typeNote => _pick('Note', 'Maelezo', 'Note');
  String get typeDoc => _pick('Doc', 'Nyaraka', 'Doc');
  String get typeReceipt => _pick('Receipt', 'Risiti', 'Receipt');
  String get typeScan => _pick('Scan', 'Picha', 'Scan');

  // ---- Scan detail ----
  String get scanNotFound =>
      _pick('Scan not found', 'Picha haijapatikana', 'Scan haijapatikana');
  String get mayBeDeleted => _pick('This item may have been deleted.',
      'Huenda kipengee hiki kimefutwa.', 'Huenda hii imefutwa.');
  String get textOnlyNote => _pick('Text-only note — no photo attached.',
      'Maelezo ya maandishi tu — hakuna picha.',
      'Note ya maandishi tu — hakuna photo.');
  String get result => _pick('Result', 'Matokeo', 'Result');
  String get rerun => _pick('Re-run', 'Rudia', 'Re-run');
  String get deletedDone => _pick('Deleted', 'Imefutwa', 'Imefutwa');
  String get deleteScanQ =>
      _pick('Delete this scan?', 'Futa picha hii?', 'Futa scan hii?');
  String get deleteScanBody => _pick(
      'This removes it from your library for good. This can’t be undone.',
      'Hii inaiondoa kwenye maktaba yako kabisa. Haiwezi kutenduliwa.',
      'Hii inaitoa kwenye library yako kabisa. Haiwezi kurudishwa.');

  // ---- Safety ----
  String get safetyContacts =>
      _pick('Safety contacts', 'Nambari za dharura', 'Safety contacts');
  String get inDangerCall => _pick('In danger? Call now.',
      'Uko hatarini? Piga sasa.', 'Uko hatarini? Piga sasa.');
  String get worksOffline => _pick('These numbers work with no internet needed.',
      'Nambari hizi hufanya kazi bila intaneti.',
      'Hizi namba zinafanya kazi bila internet.');
  String get numberComingSoon => _pick('Number coming soon',
      'Nambari inakuja hivi karibuni', 'Namba inakuja soon');
  String get call => _pick('Call', 'Piga simu', 'Piga');
  String copied(String v) => _pick('Copied $v', 'Imenakiliwa $v', 'Copied $v');
}

extension L10nRef on WidgetRef {
  L get l10n => L(watch(langProvider).flavor);
}

extension L10nReader on Ref {
  L get l10n => L(read(langProvider).flavor);
}
