import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

// ---- Tables (offline-first; everything lives on-device) ----

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get amount => real()(); // positive=income, negative=expense
  TextColumn get category => text().withDefault(const Constant('Other'))();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get receiptPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class BudgetCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get limit => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(1))(); // 0 low,1 med,2 high
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  BoolColumn get reminder => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Deadlines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get dueAt => dateTime()();
  TextColumn get sourceType => text().withDefault(const Constant('manual'))(); // manual|scan|timetable
  IntColumn get sourceScanId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class TimetableClasses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get unit => text()();
  IntColumn get weekday => integer()(); // 1=Mon..7=Sun
  TextColumn get startTime => text()(); // "08:00"
  TextColumn get endTime => text()();
  TextColumn get venue => text().nullable()();
  TextColumn get lecturer => text().nullable()();
}

class Scans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // somo|karani|receipt|timetable|hostel
  TextColumn get title => text()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get resultJson => text()(); // serialized generated output
  RealColumn get confidence => real().withDefault(const Constant(1))();
  BoolColumn get topicSensitive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer().nullable()(); // null = legacy rows, backfilled in v2
  TextColumn get role => text()(); // user|agent|system
  TextColumn get agent => text().nullable()(); // somo|karani|hustle|ratiba|router
  TextColumn get content => text()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get cardJson => text().nullable()(); // inline result card payload
  RealColumn get confidence => real().withDefault(const Constant(1))();
  BoolColumn get topicSensitive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withDefault(const Constant('New chat'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [
    Transactions,
    BudgetCategories,
    Tasks,
    Deadlines,
    TimetableClasses,
    Scans,
    ChatMessages,
    Conversations,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(conversations);
            await m.addColumn(chatMessages, chatMessages.conversationId);
            // Adopt pre-v2 messages into a first conversation so history
            // written before the upgrade stays visible.
            final legacy = await (select(chatMessages)
                  ..where((t) => t.conversationId.isNull())
                  ..limit(1))
                .get();
            if (legacy.isNotEmpty) {
              final id = await into(conversations).insert(
                  ConversationsCompanion.insert(
                      title: const Value('Earlier chat')));
              await (update(chatMessages)
                    ..where((t) => t.conversationId.isNull()))
                  .write(ChatMessagesCompanion(conversationId: Value(id)));
            }
          }
        },
      );

  static QueryExecutor _open() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'tcc.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
