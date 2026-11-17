import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const OmniScannerApp());

class OmniScannerApp extends StatefulWidget {
  const OmniScannerApp({super.key});
  @override
  State<OmniScannerApp> createState() => _OmniScannerAppState();
}

class _OmniScannerAppState extends State<OmniScannerApp> {
  String _lang = 'EN';
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _lang = p.getString('lang') ?? 'EN';
      _isPro = p.getBool('pro') ?? false;
    });
  }

  Future<void> _setLang(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', v);
    setState(() => _lang = v);
  }

  Future<void> _setPro() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('pro', true);
    setState(() => _isPro = true);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = _lang == 'FA' || _lang == 'AR';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OmniScanner Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070A0E),
        primaryColor: const Color(0xFF00E676),
      ),
      builder: (c, w) => Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: w!,
      ),
      home: HomePage(
        lang: _lang,
        isPro: _isPro,
        onLang: _setLang,
        onPro: _setPro,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String lang;
  final bool isPro;
  final Function(String) onLang;
  final VoidCallback onPro;

  const HomePage({
    super.key,
    required this.lang,
    required this.isPro,
    required this.onLang,
    required this.onPro,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _items = [];
  String _biz = 'Supermarket';

  final Map<String, String> _langs = const {
    'EN': 'EN 🇺🇸',
    'DE': 'DE 🇩🇪',
    'FA': 'FA 🇮🇷',
    'AR': 'AR 🇸🇦',
    'TR': 'TR 🇹🇷',
    'FR': 'FR 🇫🇷',
    'ES': 'ES 🇪🇸',
    'RU': 'RU 🇷🇺',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList('items_db') ?? [];
    setState(() {
      _items = raw.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList();
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('items_db', _items.map((e) => jsonEncode(e)).toList());
  }

  Future<String> _findName(String code) async {
    try {
      final r = await http
          .get(Uri.parse('https://openfoodfacts.org'))
          .timeout(const Duration(seconds: 4));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        if (d['status'] == 1) {
          return d['product']?['product_name']?.toString() ?? '';
        }
      }
    } catch (_) {}
    return '';
  }

  String _txt(String k) {
    const m = {
      'scan': {'EN': 'START LIVE SCAN', 'DE': 'LIVE-SCAN STARTEN', 'FA': 'شروع اسکن زنده'},
      'inv': {'EN': 'Smart Inventory', 'DE': 'Intelligentes Lager', 'FA': 'انبار هوشمند'},
      'shop': {'EN': 'Shopping List', 'DE': 'Einkaufsliste', 'FA': 'لیست خرید'},
      'save': {'EN': 'Save Offline', 'DE': 'Offline speichern', 'FA': 'ذخیره آفلاین'},
    };
    return m[k]?[widget.lang] ?? m[k]?['EN'] ?? k;
  }

  @override
  Widget build(BuildContext context) {
    final inv = _items.where((x) => x['shop'] != true).toList();
    final shop = _items.where((x) => x['shop'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E131A),
        title: const Text(
          'OmniScanner Pro',
          style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
        ),
        actions: [
          DropdownButton<String>(
            value: _langs.containsKey(widget.lang) ? widget.lang : 'EN',
            underline: const SizedBox(),
            items: _langs.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) {
              if (v != null) widget.onLang(v);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _biz,
                    isExpanded: true,
                    items: const ['Supermarket', 'Pharmacy', 'Cosmetics', 'Warehouse']
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _biz = v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isPro ? const Color(0xFF00E676) : Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _proModal,
                  child: Text(widget.isPro ? 'PRO ACTIVE' : 'GO PRO \$5'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.camera_alt, size: 26),
              label: Text(_txt('scan'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final code = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const ScannerView()),
                );
                if (!mounted) return;
                final autoName = (code != null && code.isNotEmpty) ? await _findName(code) : '';
                if (!mounted) return;
                _addForm(code: code ?? '', name: autoName, isShop: false);
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_txt('inv')} (${inv.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => _addForm(isShop: true),
                  child: Text('+ ${_txt('shop')} (${shop.length})', style: const TextStyle(color: Color(0xFF00B0FF))),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (c, i) {
                  final it = _items[i];
                  final exp = DateTime.tryParse(it['exp'] ?? '') ?? DateTime.now();
                  final days = exp.difference(DateTime.now()).inDays;
                  final col = days < 0 ? Colors.redAccent : (days <= 14 ? Colors.orangeAccent : const Color(0xFF00E676));
                  return Card(
                    color: const Color(0xFF121822),
                    child: ListTile(
                      leading: Icon(it['shop'] == true ? Icons.shopping_cart : Icons.inventory, color: col),
                      title: Text('${it['name']} (${it['size']})'),
                      subtitle: Text('Code: ${it['code']} • Exp: ${exp.year}-${exp.month}-${exp.day}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          setState(() => _items.removeAt(i));
                          _save();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addForm({String code = '', String name = '', bool isShop = false}) {
    final nCtrl = TextEditingController(text: name);
    final cCtrl = TextEditingController(text: code);
    final sCtrl = TextEditingController();
    DateTime exp = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121822),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
              TextField(controller: cCtrl, decoration: const InputDecoration(labelText: 'Barcode')),
              TextField(controller: sCtrl, decoration: const InputDecoration(labelText: 'Size / Weight')),
              ListTile(
                title: Text('Expiry: ${exp.year}-${exp.month}-${exp.day}'),
                trailing: const Icon(Icons.calendar_today, color: Color(0xFF00E676)),
                onTap: () async {
