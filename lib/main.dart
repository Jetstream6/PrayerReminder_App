import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.initDb();
  runApp(const PrayerApp());
}

class PrayerApp extends StatelessWidget {
  const PrayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prayer & Hadith',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

// ---------------- DATABASE HELPER ----------------
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDb();
    return _database!;
  }

  Future<Database> initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'islamic_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE hadiths (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            arabic TEXT,
            translation TEXT,
            isFavorite INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE prayer_logs (
            prayerName TEXT PRIMARY KEY,
            isCompleted INTEGER DEFAULT 0
          )
        ''');

        await db.insert('hadiths', {
          'arabic': 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
          'translation': 'Actions are judged by intentions. (Sahih al-Bukhari)',
          'isFavorite': 0
        });
        await db.insert('hadiths', {
          'arabic': 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
          'translation': 'The best among you are those who learn the Quran and teach it. (Sahih al-Bukhari)',
          'isFavorite': 0
        });
        await db.insert('hadiths', {
          'arabic': 'الدُّعَاءُ هُوَ الْعِبَادَةُ',
          'translation': 'Supplication (Dua) is the essence of worship. (Jami at-Tirmidhi)',
          'isFavorite': 0
        });
        await db.insert('hadiths', {
          'arabic': 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ',
          'translation': 'Your smile for your brother is a charity. (Jami at-Tirmidhi)',
          'isFavorite': 0
        });

        for (var prayer in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
          await db.insert('prayer_logs', {'prayerName': prayer, 'isCompleted': 0});
        }
      },
    );
  }

  Future<List> getAllHadiths() async {
    final db = await instance.database;
    return await db.query('hadiths');
  }

  Future<List> getFavoriteHadiths() async {
    final db = await instance.database;
    return await db.query('hadiths', where: 'isFavorite = ?', whereArgs: [1]);
  }

  Future<void> toggleFavorite(int id, int currentStatus) async {
    final db = await instance.database;
    await db.update(
      'hadiths',
      {'isFavorite': currentStatus == 1 ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List> getPrayerLogs() async {
    final db = await instance.database;
    return await db.query('prayer_logs');
  }

  Future<void> togglePrayer(String name, int currentStatus) async {
    final db = await instance.database;
    await db.update(
      'prayer_logs',
      {'isCompleted': currentStatus == 1 ? 0 : 1},
      where: 'prayerName = ?',
      whereArgs: [name],
    );
  }
}

// ---------------- MAIN NAVIGATION (4 Screens) ----------------
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PrayerTimesScreen(),
    HadithLibraryScreen(),
    FavoritesScreen(),
    PrayerTrackerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.access_time), label: 'Prayers'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Hadiths'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.check_circle_outline), label: 'Tracker'),
        ],
      ),
    );
  }
}

// ---------------- SCREEN 1: PRAYER TIMES & DAILY HADITH ----------------
class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myCoordinates = Coordinates(30.0444, 31.2357);
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;
    final prayerTimes = PrayerTimes.today(myCoordinates, params);
    final timeFormat = DateFormat.jm();

    final prayers = {
      'Fajr': timeFormat.format(prayerTimes.fajr),
      'Sunrise': timeFormat.format(prayerTimes.sunrise),
      'Dhuhr': timeFormat.format(prayerTimes.dhuhr),
      'Asr': timeFormat.format(prayerTimes.asr),
      'Maghrib': timeFormat.format(prayerTimes.maghrib),
      'Isha': timeFormat.format(prayerTimes.isha),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s Prayer Times')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.teal.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hadith of the Day ﷺ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  SizedBox(height: 8),
                  Text('إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Actions are judged by intentions. (Sahih al-Bukhari)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...prayers.entries.map((entry) => Card(
            child: ListTile(
              leading: const Icon(Icons.mosque, color: Colors.teal),
              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(entry.value, style: const TextStyle(fontSize: 16)),
            ),
          )),
        ],
      ),
    );
  }
}

// ---------------- SCREEN 2: HADITH LIBRARY ----------------
class HadithLibraryScreen extends StatefulWidget {
  const HadithLibraryScreen({super.key});

  @override
  State<HadithLibraryScreen> createState() => _HadithLibraryScreenState();
}

class _HadithLibraryScreenState extends State<HadithLibraryScreen> {
  List _hadiths = [];

  @override
  void initState() {
    super.initState();
    _loadHadiths();
  }

  Future<void> _loadHadiths() async {
    final data = await DatabaseHelper.instance.getAllHadiths();
    setState(() => _hadiths = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hadith Library ﷺ')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _hadiths.length,
        itemBuilder: (context, index) {
          final item = _hadiths[index];
          final isFav = item['isFavorite'] == 1;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(item['arabic'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(item['translation']),
              ),
              trailing: IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
                onPressed: () async {
                  await DatabaseHelper.instance.toggleFavorite(item['id'], item['isFavorite']);
                  _loadHadiths();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- SCREEN 3: SAVED FAVORITES ----------------
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final data = await DatabaseHelper.instance.getFavoriteHadiths();
    setState(() => _favorites = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Hadiths')),
      body: _favorites.isEmpty
          ? const Center(child: Text('No saved Hadiths yet. Tap the heart icon to save!'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final item = _favorites[index];
          return Card(
            child: ListTile(
              title: Text(item['arabic'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text(item['translation']),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await DatabaseHelper.instance.toggleFavorite(item['id'], 1);
                  _loadFavorites();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- SCREEN 4: DAILY PRAYER TRACKER ----------------
class PrayerTrackerScreen extends StatefulWidget {
  const PrayerTrackerScreen({super.key});

  @override
  State<PrayerTrackerScreen> createState() => _PrayerTrackerScreenState();
}

class _PrayerTrackerScreenState extends State<PrayerTrackerScreen> {
  List _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final data = await DatabaseHelper.instance.getPrayerLogs();
    setState(() => _logs = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Prayer Tracker')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final log = _logs[index];
          final completed = log['isCompleted'] == 1;
          return Card(
            child: CheckboxListTile(
              title: Text(log['prayerName'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(completed ? 'Completed Alhamdulillah' : 'Pending'),
              value: completed,
              activeColor: Colors.teal,
              onChanged: (val) async {
                await DatabaseHelper.instance.togglePrayer(log['prayerName'], log['isCompleted']);
                _loadLogs();
              },
            ),
          );
        },
      ),
    );
  }
}
