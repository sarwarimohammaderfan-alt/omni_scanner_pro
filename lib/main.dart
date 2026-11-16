import 'dart:convert';
import 'package:flutter/material.dart';
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
  String _lang = 'EN';
  bool _isPro = false;

  void _toggleLang(String newLang) => setState(() => _lang = newLang);
  void _unlockPro() => setState(() => _isPro = true);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OmniScanner Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E12),
        primaryColor: const Color(0xFF00E676),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF00B0FF),
        ),
      ),
      home: HomePage(
        lang: _lang,
        isPro: _isPro,
        onLangChange: _toggleLang,
        onUnlockPro: _unlockPro,
      ),
    );
  }
}

class ProductItem {
  final String name;
  final String barcode;
  final String size;
  final DateTime expiryDate;
  final bool isShoppingList;

  ProductItem({
    required this.name,
    required this.barcode,
    required this.size,
    required this.expiryDate,
    this.isShoppingList = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'barcode': barcode,
        'size': size,
        'expiryDate': expiryDate.toIso8601String(),
        'isShoppingList': isShoppingList,
      };

  factory ProductItem.fromJson(Map<String, dynamic> json) => ProductItem(
        name: json['name'],
        barcode: json['barcode'],
        size: json['size'],
        expiryDate: DateTime.parse(json['expiryDate']),
        isShoppingList: json['isShoppingList'] ?? false,
      );
}

class HomePage extends StatefulWidget {
  final String lang;
  final bool isPro;
  final Function(String) onLangChange;
  final VoidCallback onUnlockPro;

  const HomePage({
    super.key,
    required this.lang,
    required this.isPro,
    required this.onLangChange,
    required this.onUnlockPro,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ProductItem> _items = [];
  String _selectedBusiness = 'Supermarket & Food';

  final List<String> _businesses = [
    'Supermarket & Food',
    'Pharmacy & Medical',
    'Cosmetics & Care',
    'Warehouse & Logistics',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('products') ?? [];
    setState(() {
      _items = raw.map((e) => ProductItem.fromJson(jsonDecode(e))).toList();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('products', raw);
  }

  void _addItem(ProductItem item) {
    setState(() => _items.add(item));
    _saveData();
  }

  String tr(String en, String de) => widget.lang == 'DE' ? de : en;

  @override
  Widget build(BuildContext context) {
    final activeItems = _items.where((i) => !i.isShoppingList).toList();
    final shoppingItems = _items.where((i) => i.isShoppingList).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF11161D),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner, color: Color(0xFF00E676)),
            const SizedBox(width: 8),
            const Text(
              'OmniScanner Pro',
              style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          DropdownButton<String>(
            value: widget.lang,
            dropdownColor: const Color(0xFF1A222C),
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'EN', child: Text('EN 🇺🇸')),
              DropdownMenuItem(value: 'DE', child: Text('DE 🇩🇪')),
            ],
            onChanged: (val) {
              if (val != null) widget.onLangChange(val);
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF141B24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF00E676).withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBusiness,
                        dropdownColor: const Color(0xFF1A222C),
                        isExpanded: true,
                        items: _businesses
                            .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedBusiness = val);
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Store Barcode Gate',
                    icon: Icon(
                      Icons.verified_user,
                      color: widget.isPro ? const Color(0xFF00E676) : Colors.amber,
                    ),
                    onPressed: () {
                      if (!widget.isPro) {
                        _showProDialog(context);
                      } else {
                        _showStoreCodeDialog(context);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.camera_alt, size: 28),
              label: Text(
                tr('START LIVE SCAN', 'LIVE-SCAN STARTEN'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final scannedCode = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveBarcodeScannerPage()),
                );
                if (!mounted) return;
                _openAddProductForm(context, initialBarcode: scannedCode ?? '');
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('Inventory (${activeItems.length})', 'Lagerbestand (${activeItems.length})'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.shopping_cart, color: Color(0xFF00B0FF)),
                  label: Text(
                    tr('Shopping List (${shoppingItems.length})', 'Einkaufsliste (${shoppingItems.length})'),
                    style: const TextStyle(color: Color(0xFF00B0FF)),
                  ),
                  onPressed: () => _showShoppingListSheet(context, shoppingItems),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: activeItems.isEmpty
                  ? Center(
                      child: Text(
                        tr('No items scanned yet.\nTap START LIVE SCAN to begin.', 'Noch keine Artikel gescannt.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      itemCount: activeItems.length,
                      itemBuilder: (context, index) {
                        final item = activeItems[index];
                        final daysLeft = item.expiryDate.difference(DateTime.now()).inDays;
                        Color statusColor = const Color(0xFF00E676);
                        String statusText = tr('Fresh', 'Frisch');
                        if (daysLeft < 0) {
                          statusColor = Colors.redAccent;
                          statusText = tr('EXPIRED', 'ABGELAUFEN');
                        } else if (daysLeft <= 14) {
                          statusColor = Colors.orangeAccent;
                          statusText = tr('Expiring Soon', 'Bald fällig');
                        }
                        return Card(
                          color: const Color(0xFF141B24),
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
