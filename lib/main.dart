import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const OmniScannerProGlobalApp());
}

class OmniScannerProGlobalApp extends StatefulWidget {
  const OmniScannerProGlobalApp({super.key});

  @override
  State<OmniScannerProGlobalApp> createState() => _OmniScannerProGlobalAppState();
}

class _OmniScannerProGlobalAppState extends State<OmniScannerProGlobalApp> {
  String _lang = 'EN';
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('app_lang') ?? 'EN';
      _isPro = prefs.getBool('is_pro') ?? false;
    });
  }

  Future<void> _changeLang(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', code);
    setState(() => _lang = code);
  }

  Future<void> _activatePro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', true);
    setState(() => _isPro = true);
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = _lang == 'FA' || _lang == 'AR';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OmniScanner Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070A0E),
        primaryColor: const Color(0xFF00E676),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF00B0FF),
        ),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: GlobalDashboardPage(
        lang: _lang,
        isPro: _isPro,
        onLangChange: _changeLang,
        onUnlockPro: _activatePro,
      ),
    );
  }
}

class LocalizationHelper {
  static const Map<String, String> languages = {
    'EN': 'English 🇺🇸',
    'DE': 'Deutsch 🇩🇪',
    'FA': 'فارسی 🇮🇷',
    'AR': 'العربية 🇸🇦',
    'TR': 'Türkçe 🇹🇷',
    'FR': 'Français 🇫🇷',
    'ES': 'Español 🇪🇸',
    'IT': 'Italiano 🇮🇹',
    'RU': 'Русский 🇷🇺',
    'ZH': '中文 🇨🇳',
    'JA': '日本語 🇯🇵',
    'HI': 'हिन्दी 🇮🇳',
  };

  static final Map<String, Map<String, String>> _dict = {
    'scan_btn': {
      'EN': 'START AI LIVE SCAN',
      'DE': 'KI LIVE-SCAN STARTEN',
      'FA': 'شروع اسکن زنده هوشمند',
      'AR': 'بدء المسح الذكي المباشر',
      'TR': 'CANLI AI TARAMAYI BAŞLAT',
      'FR': 'LANCER LE SCAN IA',
      'ES': 'INICIAR ESCANEO IA',
      'IT': 'AVVIA SCANSIONE IA',
      'RU': 'ЗАПУСТИТЬ ИИ-СКАНЕР',
      'ZH': '开始智能实时扫描',
      'JA': 'AIライブスキャン開始',
      'HI': 'AI लाइव स्कैन शुरू करें',
    },
    'inventory': {
      'EN': 'Smart Inventory',
      'DE': 'Intelligentes Lager',
      'FA': 'انبار هوشمند',
      'AR': 'المخزون الذكي',
      'TR': 'Akıllı Envanter',
      'FR': 'Inventaire Intelligent',
      'ES': 'Inventario Inteligente',
      'IT': 'Inventario Smart',
      'RU': 'Умный склад',
      'ZH': '智能库存',
      'JA': 'スマート在庫',
      'HI': 'स्मार्ट इन्वेंटरी',
    },
    'shopping': {
      'EN': 'Shopping List',
      'DE': 'Einkaufsliste',
      'FA': 'لیست خرید',
      'AR': 'قائمة التسوق',
      'TR': 'Alışveriş Listesi',
      'FR': 'Liste de courses',
      'ES': 'Lista de compras',
      'IT': 'Lista della spesa',
      'RU': 'Список покупок',
      'ZH': '购物清单',
      'JA': '買い物リスト',
      'HI': 'खरीदारी सूची',
    },
    'fresh': {
      'EN': 'Fresh',
      'DE': 'Frisch',
      'FA': 'سالم',
      'AR': 'طازج',
      'TR': 'Taze',
      'FR': 'Frais',
      'ES': 'Fresco',
      'IT': 'Fresco',
      'RU': 'Свежий',
      'ZH': '新鲜',
      'JA': '新鮮',
      'HI': 'ताज़ा',
    },
    'soon': {
      'EN': 'Expiring Soon',
      'DE': 'Bald fällig',
      'FA': 'نزدیک انقضا',
      'AR': 'ينتهي قريباً',
      'TR': 'Yakında Doluyor',
      'FR': 'Expire bientôt',
      'ES': 'Caduca pronto',
      'IT': 'In scadenza',
      'RU': 'Скоро истекает',
      'ZH': '即将过期',
      'JA': '期限間近',
      'HI': 'जल्द समाप्त',
    },
    'expired': {
      'EN': 'EXPIRED',
      'DE': 'ABGELAUFEN',
      'FA': 'منقضی شده',
      'AR': 'منتهي الصلاحية',
      'TR': 'SÜRESİ DOLMUŞ',
      'FR': 'EXPIRÉ',
      'ES': 'CADUCADO',
      'IT': 'SCADUTO',
      'RU': 'ПРОСРОЧЕНО',
      'ZH': '已过期',
      'JA': '期限切れ',
      'HI': 'समाप्त',
    },
    'save': {
      'EN': 'Save Offline',
      'DE': 'Offline speichern',
      'FA': 'ذخیره آفلاین',
      'AR': 'حفظ بدون إنترنت',
      'TR': 'Çevrimdışı Kaydet',
      'FR': 'Enregistrer hors ligne',
      'ES': 'Guardar sin conexión',
      'IT': 'Salva offline',
      'RU': 'Сохранить офлайн',
      'ZH': '离线保存',
      'JA': 'オフライン保存',
      'HI': 'ऑफ़लाइन सहेजें',
    },
    'pro_title': {
      'EN': 'OmniScanner Pro (\$5/mo)',
      'DE': 'OmniScanner Pro (5 \$/Monat)',
      'FA': 'نسخه پرو (۵ دلار ماهانه)',
      'AR': 'النسخة الاحترافية (5\$ شهرياً)',
      'TR': 'OmniScanner Pro (Aylık \$5)',
      'FR': 'OmniScanner Pro (5 \$/mois)',
      'ES': 'OmniScanner Pro (\$5/mes)',
      'IT': 'OmniScanner Pro (5 \$/mese)',
      'RU': 'OmniScanner Pro (\$5/мес)',
      'ZH': '专业版 (\$5/月)',
      'JA': 'プロ版 (\$5/月)',
      'HI': 'प्रो संस्करण (\$5/माह)',
    },
  };

  static String t(String key, String lang) {
    return _dict[key]?[lang] ?? _dict[key]?['EN'] ?? key;
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

class GlobalDashboardPage extends StatefulWidget {
  final String lang;
  final bool isPro;
  final Function(String) onLangChange;
  final VoidCallback onUnlockPro;

  const GlobalDashboardPage({
    super.key,
    required this.lang,
    required this.isPro,
    required this.onLangChange,
    required this.onUnlockPro,
  });

  @override
  State<GlobalDashboardPage> createState() => _GlobalDashboardPageState();
}

class _GlobalDashboardPageState extends State<GlobalDashboardPage> {
  List<ProductItem> _items = [];
  String _selectedBusiness = 'Supermarket & Retail';

  final List<String> _businesses = [
    'Supermarket & Retail',
    'Pharmacy & Healthcare',
    'Cosmetics & Beauty',
    'Warehouse & Logistics',
    'Restaurant & Cafe',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('products_v2') ?? [];
    setState(() {
      _items = raw.map((e) => ProductItem.fromJson(jsonDecode(e))).toList();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('products_v2', raw);
  }

  void _addItem(ProductItem item) {
    setState(() => _items.insert(0, item));
    _saveData();
  }

  String _formatDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }

  Future<String> _lookupGlobalBarcode(String barcode) async {
    if (barcode.isEmpty) return '';
    try {
      final url = Uri.parse('https://openfoodfacts.org');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 1 && data['product'] != null) {
          return data['product']['product_name']?.toString() ?? '';
        }
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final activeItems = _items.where((i) => !i.isShoppingList).toList();
    final shoppingItems = _items.where((i) => i.isShoppingList).toList();

    final freshCount = activeItems.where((i) => i.expiryDate.difference(DateTime.now()).inDays > 14).length;
    final soonCount = activeItems.where((i) {
      final d = i.expiryDate.difference(DateTime.now()).inDays;
      return d >= 0 && d <= 14;
    }).length;
    final expiredCount = activeItems.where((i) => i.expiryDate.difference(DateTime.now()).inDays < 0).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E131A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E676).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Color(0xFF00E676), size: 22),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'OmniScanner Pro',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 18),
