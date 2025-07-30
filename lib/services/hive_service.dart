import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/settings.dart';

class HiveService {
  static const String transactionsBoxName = 'transactions';
  static const String settingsBoxName = 'settings';
  static const String settingsKey = 'app_settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(TransactionEntryAdapter());
    Hive.registerAdapter(SettingsAdapter());

    // Open boxes
    await Hive.openBox<TransactionEntry>(transactionsBoxName);
    await Hive.openBox<Settings>(settingsBoxName);

    // Initialize default settings if they don't exist
    final settingsBox = getSettingsBox();
    if (!settingsBox.containsKey(settingsKey)) {
      await settingsBox.put(settingsKey, Settings.defaultSettings());
    }
  }

  static Box<TransactionEntry> getTransactionsBox() =>
      Hive.box<TransactionEntry>(transactionsBoxName);

  static Box<Settings> getSettingsBox() =>
      Hive.box<Settings>(settingsBoxName);

  static Settings getSettings() {
    final settings = getSettingsBox().get(settingsKey);
    return settings ?? Settings.defaultSettings();
  }

  static Future<void> updateSettings(Settings settings) async {
    await getSettingsBox().put(settingsKey, settings);
  }
}