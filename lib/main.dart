import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
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
// ---------------- HELPERS ----------------
const Map<String, List<double>> egyptCities = {
  'Cairo': [30.0444, 31.2357],
  'Giza': [30.0131, 31.2089],
  'Alexandria': [31.2001, 29.9187],
  'Port Said': [31.2653, 32.3019],
  'Luxor': [25.6872, 32.6396],
  'Aswan': [24.0889, 32.8998],
};

class ArabicText extends StatelessWidget {
  final String text;
  final double fontSize;
  const ArabicText(this.text, {super.key, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, height: 1.6),
      ),
    );
  }
}

// ---------------- DATABASE HELPER ----------------
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  // أول 4 أحاديث هما الأصليين، لازم يفضلوا بنفس الترتيب
  static const List<Map<String, String>> _seedHadiths = [
    {
      'arabic': 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
      'translation': 'Actions are judged by intentions. (Sahih al-Bukhari)',
    },
    {
      'arabic': 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
      'translation': 'The best among you are those who learn the Quran and teach it. (Sahih al-Bukhari)',
    },
    {
      'arabic': 'الدُّعَاءُ هُوَ الْعِبَادَةُ',
      'translation': 'Supplication (Dua) is the essence of worship. (Jami at-Tirmidhi)',
    },
    {
      'arabic': 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ',
      'translation': 'Your smile for your brother is a charity. (Jami at-Tirmidhi)',
    },
    {
      'arabic': 'الدِّينُ النَّصِيحَةُ',
      'translation': 'Religion is sincere advice. (Sahih Muslim)',
    },
    {
      'arabic': 'لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ',
      'translation': 'None of you truly believes until he loves for his brother what he loves for himself. (Sahih al-Bukhari & Sahih Muslim)',
    },
    {
      'arabic': 'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الْآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ',
      'translation': 'Whoever believes in Allah and the Last Day, let him speak good or remain silent. (Sahih al-Bukhari & Sahih Muslim)',
    },
    {
      'arabic': 'الطُّهُورُ شَطْرُ الْإِيمَانِ',
      'translation': 'Cleanliness is half of faith. (Sahih Muslim)',
    },
    {
      'arabic': 'أَحَبُّ الْأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ',
      'translation': 'The most beloved deeds to Allah are the most consistent, even if small. (Sahih al-Bukhari & Sahih Muslim)',
    },
    {
      'arabic': 'الْكَلِمَةُ الطَّيِّبَةُ صَدَقَةٌ',
      'translation': 'A good word is charity. (Sahih al-Bukhari & Sahih Muslim)',
    },
  ];

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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE hadiths (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            arabic TEXT,
            translation TEXT,
            isFavorite INTEGER DEFAULT 0
          )
        ''');
        await _createPrayerLogsTable(db);
        await _createSettingsTable(db);
        await _insertHadiths(db, _seedHadiths);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS prayer_logs');
          await _createPrayerLogsTable(db);
          await _createSettingsTable(db);
          await _insertHadiths(db, _seedHadiths.skip(4));
        }
      },
    );
  }

  Future<void> _createPrayerLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE prayer_logs (
        prayerName TEXT,
        date TEXT,
        isCompleted INTEGER DEFAULT 0,
        PRIMARY KEY (prayerName, date)
      )
    ''');
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE settings (
        settingKey TEXT PRIMARY KEY,
        settingValue TEXT
      )
    ''');
  }

  Future<void> _insertHadiths(Database db, Iterable<Map<String, String>> list) async {
    for (final h in list) {
      await db.insert('hadiths', {...h, 'isFavorite': 0});
    }
  }

  String _today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // ---------- Hadiths ----------
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

  // حديث مختلف كل يوم: رقم اليوم في السنة % عدد الأحاديث
  Future<Map?> getDailyHadith() async {
    final all = await getAllHadiths();
    if (all.isEmpty) return null;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return all[dayOfYear % all.length] as Map;
  }

  // ---------- Prayer logs (صف لكل صلاة في كل يوم) ----------
  Future<List> getPrayerLogs() async {
    final db = await instance.database;
    final today = _today();
    for (final prayer in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      await db.insert(
        'prayer_logs',
        {'prayerName': prayer, 'date': today, 'isCompleted': 0},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    return await db.query(
      'prayer_logs',
      where: 'date = ?',
      whereArgs: [today],
      orderBy: 'rowid',
    );
  }

  Future<void> togglePrayer(String name, int currentStatus) async {
    final db = await instance.database;
    await db.update(
      'prayer_logs',
      {'isCompleted': currentStatus == 1 ? 0 : 1},
      where: 'prayerName = ? AND date = ?',
      whereArgs: [name, _today()],
    );
  }

  // ---------- Settings ----------
  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final rows = await db.query('settings', where: 'settingKey = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['settingValue'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {'settingKey': key, 'settingValue': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
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
class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  String _city = 'Cairo';
  Map? _dailyHadith;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final savedCity = await DatabaseHelper.instance.getSetting('city');
    final hadith = await DatabaseHelper.instance.getDailyHadith();
    if (!mounted) return;
    setState(() {
      if (savedCity != null && egyptCities.containsKey(savedCity)) {
        _city = savedCity;
      }
      _dailyHadith = hadith;
      _loading = false;
    });
  }

  Future<void> _changeCity(String city) async {
    await DatabaseHelper.instance.setSetting('city', city);
    if (!mounted) return;
    setState(() => _city = city);
  }

  String _formatDiff(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final c = egyptCities[_city]!;
    final myCoordinates = Coordinates(c[0], c[1]);
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;
    final prayerTimes = PrayerTimes.today(myCoordinates, params);
    final timeFormat = DateFormat.jm();

    final times = {
      'Fajr': prayerTimes.fajr,
      'Sunrise': prayerTimes.sunrise,
      'Dhuhr': prayerTimes.dhuhr,
      'Asr': prayerTimes.asr,
      'Maghrib': prayerTimes.maghrib,
      'Isha': prayerTimes.isha,
    };

    // أول وقت لسه ما جاش = الصلاة الجاية
    final now = DateTime.now();
    String? nextName;
    for (final e in times.entries) {
      if (e.value.isAfter(now)) {
        nextName = e.key;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Prayer Times'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.location_on),
            tooltip: 'Change city',
            onSelected: _changeCity,
            itemBuilder: (context) => egyptCities.keys
                .map((name) => PopupMenuItem<String>(value: name, child: Text(name)))
                .toList(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.teal),
                    const SizedBox(width: 4),
                    Text('$_city, Egypt', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                if (nextName != null)
                  Card(
                    color: Colors.teal,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Next: $nextName in ${_formatDiff(times[nextName]!.difference(now))}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (_dailyHadith != null)
                  Card(
                    color: Colors.teal.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hadith of the Day ﷺ',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                          const SizedBox(height: 8),
                          ArabicText(_dailyHadith!['arabic']),
                          const SizedBox(height: 4),
                          Text(_dailyHadith!['translation']),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                ...times.entries.map((entry) => Card(
                      color: entry.key == nextName ? Colors.teal.shade100 : null,
                      child: ListTile(
                        leading: const Icon(Icons.mosque, color: Colors.teal),
                        title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(timeFormat.format(entry.value), style: const TextStyle(fontSize: 16)),
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
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHadiths();
  }

  Future<void> _loadHadiths() async {
    final data = await DatabaseHelper.instance.getAllHadiths();
    if (!mounted) return;
    setState(() {
      _hadiths = data;
      _loading = false;
    });
  }

  List get _filtered {
    final q = _query.trim();
    if (q.isEmpty) return _hadiths;
    return _hadiths.where((h) {
      return h['translation'].toString().toLowerCase().contains(q.toLowerCase()) ||
          h['arabic'].toString().contains(q);
    }).toList();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('Hadith Library ﷺ')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search Hadiths...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(child: Text('No Hadiths found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isFav = item['isFavorite'] == 1;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: ArabicText(item['arabic'], fontSize: 18),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(item['translation']),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    tooltip: 'Copy',
                                    onPressed: () async {
                                      await Clipboard.setData(ClipboardData(
                                        text: '${item['arabic']}\n${item['translation']}',
                                      ));
                                      if (!mounted) return;
                                      _showMessage('Copied');
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isFav ? Icons.favorite : Icons.favorite_border,
                                      color: isFav ? Colors.red : null,
                                    ),
                                    onPressed: () async {
                                      await DatabaseHelper.instance.toggleFavorite(item['id'], item['isFavorite']);
                                      await _loadHadiths();
                                      if (!mounted) return;
                                      _showMessage(isFav ? 'Removed from Saved' : 'Added to Saved');
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
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
    if (!mounted) return;
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
                    title: ArabicText(item['arabic'], fontSize: 18),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(item['translation']),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove from Saved',
                      onPressed: () async {
                        await DatabaseHelper.instance.toggleFavorite(item['id'], 1);
                        await _loadFavorites();
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
    if (!mounted) return;
    setState(() => _logs = data);
  }

  @override
  Widget build(BuildContext context) {
    final total = _logs.length;
    final done = _logs.where((l) => l['isCompleted'] == 1).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Prayer Tracker')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            color: Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM').format(DateTime.now()),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: total == 0 ? 0.0 : done / total,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Text('$done / $total prayers completed today'),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
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
          ),
        ],
      ),
    );
  }
}