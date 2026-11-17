import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const OmniScannerApp());
}

class OmniScannerApp extends StatefulWidget {
  const OmniScannerApp({super.key});
  @override
  State<OmniScannerApp> createState() => _OmniScannerAppState();
}

class _OmniScannerAppState extends State<OmniScannerApp> {
  String lang = 'EN';
  bool isPro = false;

  @override
  void initState() {
    super.initState();
    loadPrefs();
  }

  Future<void> loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      lang = p.getString('lang') ?? 'EN';
      isPro = p.getBool('pro') ?? false;
    });
  }

  Future<void> changeLang(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('lang', v);
    setState(() {
      lang = v;
    });
  }

  Future<void> unlockPro() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('pro', true);
    setState(() {
      isPro = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rtl = lang == 'FA' || lang == 'AR';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OmniScanner Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070A0E),
        primaryColor: const Color(0xFF00E676),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: DashboardScreen(
        lang: lang,
        isPro: isPro,
        onLang: changeLang,
        onPro: unlockPro,
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final String lang;
  final bool isPro;
  final Function(String) onLang;
  final VoidCallback onPro;

  const DashboardScreen({
    super.key,
    required this.lang,
    required this.isPro,
    required this.onLang,
    required this.onPro,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> items = [];
  String business = 'Supermarket';

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList('db_items') ?? [];
    setState(() {
      items = list.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList();
    });
  }

  Future<void> saveItems() async {
    final p = await SharedPreferences.getInstance();
    final list = items.map((e) => jsonEncode(e)).toList();
    await p.setStringList('db_items', list);
  }

  Future<String> fetchProductName(String barcode) async {
    try {
      final uri = Uri.parse('https://openfoodfacts.org' + barcode + '.json');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 1 && data['product'] != null) {
          return data['product']['product_name']?.toString() ?? '';
        }
      }
    } catch (_) {}
    return '';
  }

  String tr(String key) {
    const dict = {
      'scan': {'EN': 'START LIVE SCAN', 'DE': 'LIVE-SCAN STARTEN', 'FA': 'شروع اسکن زنده'},
      'inv': {'EN': 'Smart Inventory', 'DE': 'Intelligentes Lager', 'FA': 'انبار هوشمند'},
      'shop': {'EN': 'Shopping List', 'DE': 'Einkaufsliste', 'FA': 'لیست خرید'},
      'save': {'EN': 'Save Offline', 'DE': 'Offline speichern', 'FA': 'ذخیره آفلاین'},
    };
    return dict[key]?[widget.lang] ?? dict[key]?['EN'] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E131A),
        title: const Text(
          'OmniScanner Pro',
          style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
        ),
        actions: [
          DropdownButton<String>(
            value: widget.lang,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'EN', child: Text('EN')),
              DropdownMenuItem(value: 'DE', child: Text('DE')),
              DropdownMenuItem(value: 'FA', child: Text('FA')),
              DropdownMenuItem(value: 'AR', child: Text('AR')),
              DropdownMenuItem(value: 'TR', child: Text('TR')),
              DropdownMenuItem(value: 'FR', child: Text('FR')),
            ],
            onChanged: (v) {
              if (v != null) widget.onLang(v);
            },
          ),
          const SizedBox(width: 10),
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
                    value: business,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Supermarket', child: Text('Supermarket')),
                      DropdownMenuItem(value: 'Pharmacy', child: Text('Pharmacy')),
                      DropdownMenuItem(value: 'Cosmetics', child: Text('Cosmetics')),
                      DropdownMenuItem(value: 'Warehouse', child: Text('Warehouse')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => business = v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isPro ? const Color(0xFF00E676) : Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: showProModal,
                  child: Text(widget.isPro ? 'PRO ACTIVE' : 'GO PRO 5 USD'),
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
              label: Text(tr('scan'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final code = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const BarcodeCameraScreen()),
                );
                if (!mounted) return;
                final autoName = (code != null && code.isNotEmpty) ? await fetchProductName(code) : '';
                if (!mounted) return;
                openProductForm(code: code ?? '', name: autoName, isShop: false);
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tr('inv') + ' (' + items.length.toString() + ')', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => openProductForm(isShop: true),
                  child: Text('+ ' + tr('shop'), style: const TextStyle(color: Color(0xFF00B0FF))),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final it = items[index];
                  final exp = DateTime.tryParse(it['exp'] ?? '') ?? DateTime.now();
                  final days = exp.difference(DateTime.now()).inDays;
                  final col = days < 0 ? Colors.redAccent : (days <= 14 ? Colors.orangeAccent : const Color(0xFF00E676));
                  final expStr = exp.year.toString() + '-' + exp.month.toString() + '-' + exp.day.toString();
                  return Card(
                    color: const Color(0xFF121822),
                    child: ListTile(
                      leading: Icon(it['shop'] == true ? Icons.shopping_cart : Icons.inventory, color: col),
                      title: Text(it['name'].toString() + ' (' + it['size'].toString() + ')'),
                      subtitle: Text('Code: ' + it['code'].toString() + ' | Exp: ' + expStr),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          setState(() => items.removeAt(index));
                          saveItems();
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

  void openProductForm({String code = '', String name = '', bool isShop = false}) {
    final nameCtrl = TextEditingController(text: name);
    final codeCtrl = TextEditingController(text: code);
    final sizeCtrl = TextEditingController();
    DateTime exp = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121822),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final expText = 'Expiry: ' + exp.year.toString() + '-' + exp.month.toString() + '-' + exp.day.toString();
          return Padding(
