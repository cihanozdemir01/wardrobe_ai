import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/weather_service.dart';
import '../../data/models/clothing_item.dart';
import '../../data/models/combination.dart';
import '../../data/models/user_profile.dart';
class WardrobeState extends ChangeNotifier {
  UserProfile? _profile;
  List<ClothingItem> _items = [];
  List<String> _historyLog = []; // Format: "yyyy-MM-dd:item1Id,item2Id..."
  bool _isLoading = false;
  String? _openAiApiKey;
  String? _geminiApiKey;
  String? _githubToken = ''; // Enter token in app settings for private repository updates

  final WeatherService _weatherService = MockWeatherService();

  UserProfile? get profile => _profile;
  List<ClothingItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isOnboarded => _profile != null;
  String? get openAiApiKey => _openAiApiKey;
  String? get geminiApiKey => _geminiApiKey;
  String? get githubToken => _githubToken;

  AIService get aiService {
    if (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) {
      return GeminiAIServiceImpl(apiKey: _geminiApiKey!);
    } else if (_openAiApiKey != null && _openAiApiKey!.isNotEmpty) {
      return OpenAIServiceImpl(apiKey: _openAiApiKey!);
    }
    return MockAIService();
  }

  // Constructor
  WardrobeState() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Profile
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        _profile = UserProfile.fromJson(jsonDecode(profileStr));
      }

      // Load Items
      final itemsStr = prefs.getString('wardrobe_items');
      if (itemsStr != null) {
        final List<dynamic> decoded = jsonDecode(itemsStr);
        _items = decoded.map((i) => ClothingItem.fromJson(i)).toList();
      } else {
        // Pre-populate with high-quality sample items for demo
        _items = _getSampleItems();
        await _saveItemsToPrefs();
      }

      // Load History Log
      _historyLog = prefs.getStringList('wear_history') ?? [];
      
      // Load OpenAI API Key
      _openAiApiKey = prefs.getString('openai_api_key');

      // Load Gemini API Key
      _geminiApiKey = prefs.getString('gemini_api_key');

      // Load GitHub Access Token
      _githubToken = prefs.getString('github_token') ?? '';
    } catch (e) {
      debugPrint("Error loading preferences: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save profile to SharedPreferences
  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
    notifyListeners();
  }

  // Save items to SharedPreferences
  Future<void> _saveItemsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wardrobe_items', jsonEncode(_items.map((i) => i.toJson()).toList()));
  }

  // Save history log to SharedPreferences
  Future<void> _saveHistoryToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('wear_history', _historyLog);
  }

  // Save OpenAI API Key
  Future<void> saveApiKey(String? key) async {
    _openAiApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.isEmpty) {
      await prefs.remove('openai_api_key');
    } else {
      await prefs.setString('openai_api_key', key);
    }
    notifyListeners();
  }

  // Save Gemini API Key
  Future<void> saveGeminiApiKey(String? key) async {
    _geminiApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.isEmpty) {
      await prefs.remove('gemini_api_key');
    } else {
      await prefs.setString('gemini_api_key', key);
    }
    notifyListeners();
  }

  // Save GitHub Access Token
  Future<void> saveGithubToken(String? token) async {
    _githubToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove('github_token');
    } else {
      await prefs.setString('github_token', token);
    }
    notifyListeners();
  }

  // Add Item to Wardrobe
  Future<void> addItem(ClothingItem item) async {
    _items.add(item);
    await _saveItemsToPrefs();
    notifyListeners();
  }

  // Delete Item from Wardrobe
  Future<void> deleteItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _saveItemsToPrefs();
    notifyListeners();
  }

  // Update Item (Manual edit)
  Future<void> updateItem(ClothingItem updatedItem) async {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      await _saveItemsToPrefs();
      notifyListeners();
    }
  }

  // Record wearing an outfit
  Future<void> recordWearToday(Combination combination) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final itemIds = combination.items.map((i) => i.id).join(',');
    
    // Add to history log
    _historyLog.add("$todayStr:$itemIds");
    await _saveHistoryToPrefs();

    // Increment usage count and update last worn date
    for (var outfitItem in combination.items) {
      final idx = _items.indexWhere((item) => item.id == outfitItem.id);
      if (idx != -1) {
        _items[idx] = _items[idx].copyWith(
          usageCount: _items[idx].usageCount + 1,
          lastWorn: DateTime.now(),
        );
      }
    }
    await _saveItemsToPrefs();
    notifyListeners();
  }

  // Combination Engine Logic
  // Combination Engine Logic
  Future<Combination> generateOutfitRecommendation(WeatherData weather, {String type = 'Daily'}) async {
    return aiService.getOutfitRecommendation(
      weather,
      _items,
      _profile ?? UserProfile(name: 'Stil Sahibi', age: 25, gender: 'Belirtilmedi', height: 175, weight: 70, workStyle: 'Ofis', stylePreference: 'Casual'),
      type: type,
    );
  }

  // Wardrobe Analytics & Scores
  Map<String, int> getWardrobeScoreMetrics() {
    if (_items.isEmpty) {
      return {
        'total': 0,
        'yazlik': 0,
        'kislik': 0,
        'is': 0,
        'gunluk': 0,
        'renkDengesi': 0,
        'ayakkabi': 0
      };
    }

    int yazlik = min(100, (_items.where((i) => i.season == 'Yaz' || i.season == 'Mevsimsiz').length * 15));
    int kislik = min(100, (_items.where((i) => i.season == 'Kış' || i.season == 'Mevsimsiz').length * 15));
    int isKombinleri = min(100, (_items.where((i) => i.style == 'Smart Casual' || i.style == 'Klasik').length * 20));
    int gunlukKombinler = min(100, (_items.where((i) => i.style == 'Casual' || i.style == 'Spor').length * 15));
    
    // Color balance: Count unique colors
    final colors = _items.map((i) => i.color.toLowerCase()).toSet();
    int renkDengesi = min(100, (colors.length * 15));

    // Shoe diversity
    int ayakkabi = min(100, (_items.where((i) => i.category == 'Ayakkabı').length * 35));

    int total = ((yazlik + kislik + isKombinleri + gunlukKombinler + renkDengesi + ayakkabi) / 6).round();

    return {
      'total': total,
      'yazlik': yazlik,
      'kislik': kislik,
      'is': isKombinleri,
      'gunluk': gunlukKombinler,
      'renkDengesi': renkDengesi,
      'ayakkabi': ayakkabi,
    };
  }

  // Smart suggestions using combination capacity
  List<Map<String, dynamic>> getSmartSuggestions() {
    List<Map<String, dynamic>> suggestions = [];

    // Analyze gaps
    int shirtCount = _items.where((i) => i.category == 'Gömlek').length;
    int pantsCount = _items.where((i) => i.category == 'Pantolon').length;
    int shoesCount = _items.where((i) => i.category == 'Ayakkabı').length;
    int jacketCount = _items.where((i) => i.category == 'Ceket').length;
    final colors = _items.map((i) => i.color.toLowerCase()).toSet();

    if (pantsCount <= 2) {
      // Calculate how many outfits bej chino would unlock
      int matchingTops = _items.where((i) => i.category == 'Tişört' || i.category == 'Gömlek').length;
      int matchingShoes = shoesCount;
      int comboIncrease = matchingTops * matchingShoes;
      if (comboIncrease > 0) {
        suggestions.add({
          'item': 'Bej Chino Pantolon',
          'description': 'Gardırobunuza bej chino pantolon ekleyerek mevcut kıyafetlerinizle $comboIncrease yeni kombin oluşturabilirsiniz.',
          'percentage': 25,
          'priority': 'Yüksek'
        });
      }
    }

    if (!colors.contains('beyaz') || shoesCount <= 1) {
      int matchingTops = _items.where((i) => i.category == 'Tişört' || i.category == 'Gömlek').length;
      int matchingBottoms = _items.where((i) => i.category == 'Pantolon' || i.category == 'Şort').length;
      int comboIncrease = (matchingTops * matchingBottoms * 0.15).round();
      suggestions.add({
        'item': 'Beyaz Minimal Deri Sneaker',
        'description': 'Beyaz minimalist deri sneaker, gardırobunuzdaki kombin çeşitliliğini yaklaşık %15 artıracaktır.',
        'percentage': 15,
        'priority': 'Yüksek'
      });
    }

    if (shirtCount <= 2) {
      int matchingBottoms = _items.where((i) => i.category == 'Pantolon').length;
      int comboIncrease = matchingBottoms * shoesCount;
      suggestions.add({
        'item': 'Açık Mavi Oxford Gömlek',
        'description': 'Açık mavi keten/oxford gömlek eklemek, iş ve smart casual kombinlerinizi zenginleştirecektir ($comboIncrease yeni kombin).',
        'percentage': 12,
        'priority': 'Orta'
      });
    }

    if (jacketCount == 0) {
      suggestions.add({
        'item': 'Lacivert Blazer Ceket',
        'description': 'Lacivert blazer ceket eklemek, casual tişörtlerinizi anında resmi kombinlere dönüştürmenize imkan tanır.',
        'percentage': 20,
        'priority': 'Orta'
      });
    }

    // Default general suggestions if wardrobe is already rich
    if (suggestions.isEmpty) {
      suggestions.add({
        'item': 'Haki Kargo Şort',
        'description': 'Yazlık gardırobunuza haki şort ekleyerek sıcak havalardaki spor kombin alternatiflerinizi genişletebilirsiniz.',
        'percentage': 8,
        'priority': 'Düşük'
      });
    }

    return suggestions;
  }

  // Prepopulated dummy items for a high quality initial experience
  List<ClothingItem> _getSampleItems() {
    return [
      ClothingItem(
        id: '1',
        imagePath: 'https://images.pexels.com/photos/991509/pexels-photo-991509.jpeg?auto=compress&cs=tinysrgb&w=500',
        category: 'Tişört',
        color: 'Siyah',
        pattern: 'Düz',
        fabricType: 'Pamuk',
        season: 'Mevsimsiz',
        style: 'Casual',
        usageCount: 12,
        lastWorn: DateTime.now().subtract(const Duration(days: 4)),
      ),
      ClothingItem(
        id: '2',
        imagePath: 'https://images.pexels.com/photos/3772506/pexels-photo-3772506.jpeg?auto=compress&cs=tinysrgb&w=500',
        category: 'Gömlek',
        color: 'Beyaz',
        pattern: 'Düz',
        fabricType: 'Keten',
        season: 'Yaz',
        style: 'Smart Casual',
        usageCount: 8,
        lastWorn: DateTime.now().subtract(const Duration(days: 6)),
      ),
      ClothingItem(
        id: '3',
        imagePath: 'https://images.pexels.com/photos/1598507/pexels-photo-1598507.jpeg?auto=compress&cs=tinysrgb&w=500',
        category: 'Pantolon',
        color: 'Lacivert',
        pattern: 'Düz',
        fabricType: 'Denim',
        season: 'İlkbahar/Sonbahar',
        style: 'Casual',
        usageCount: 15,
        lastWorn: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ClothingItem(
        id: '4',
        imagePath: 'https://images.pexels.com/photos/2068349/pexels-photo-2068349.jpeg?auto=compress&cs=tinysrgb&w=500',
        category: 'Pantolon',
        color: 'Bej',
        pattern: 'Düz',
        fabricType: 'Pamuk',
        season: 'İlkbahar/Sonbahar',
        style: 'Smart Casual',
        usageCount: 5,
        lastWorn: DateTime.now().subtract(const Duration(days: 8)),
      ),
      ClothingItem(
        id: '5',
        imagePath: 'https://images.pexels.com/photos/1464625/pexels-photo-1464625.jpeg?auto=compress&cs=tinysrgb&w=500',
        category: 'Ayakkabı',
        color: 'Beyaz',
        pattern: 'Düz',
        fabricType: 'Deri',
        season: 'Mevsimsiz',
        style: 'Casual',
        usageCount: 22,
        lastWorn: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ClothingItem(
        id: '6',
        imagePath: 'https://images.pexels.com/photos/9834884/pexels-photo-9834884.jpeg?auto=compress&cs=tinysrgb&w=500',
        category: 'Ceket',
        color: 'Siyah',
        pattern: 'Düz',
        fabricType: 'Deri',
        season: 'Kış',
        style: 'Spor',
        usageCount: 4,
        lastWorn: DateTime.now().subtract(const Duration(days: 10)),
      ),
      ClothingItem(
        id: '7',
        imagePath: 'https://images.pexels.com/photos/11038283/pexels-photo-11038283.jpeg?auto=compress&cs=tinysrgb&w=500',
        category: 'Şort',
        color: 'Gri',
        pattern: 'Düz',
        fabricType: 'Pamuk',
        season: 'Yaz',
        style: 'Spor',
        usageCount: 10,
        lastWorn: DateTime.now().subtract(const Duration(days: 5)),
      ),
      ClothingItem(
        id: '8',
        imagePath: 'https://images.pexels.com/photos/13050849/pexels-photo-13050849.jpeg?auto=compress&cs=tinysrgb&w=500',
        category: 'Aksesuar',
        color: 'Siyah',
        pattern: 'Düz',
        fabricType: 'Metal',
        season: 'Mevsimsiz',
        style: 'Casual',
        usageCount: 18,
        lastWorn: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}
