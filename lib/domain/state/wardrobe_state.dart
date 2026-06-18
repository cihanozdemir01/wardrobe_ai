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

  final WeatherService _weatherService = MockWeatherService();
  final AIService _aiService = MockAIService();

  UserProfile? get profile => _profile;
  List<ClothingItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get isOnboarded => _profile != null;

  // Constructor
  WardrobeState() {
    _loadFromPrefs();
  }

  // Load state from SharedPreferences
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
  Combination generateOutfitRecommendation(WeatherData weather, {String type = 'Daily'}) {
    if (_items.isEmpty) {
      return Combination(
        id: 'empty',
        items: [],
        harmonyScore: 0,
        seasonSuitability: 'N/A',
        formalityLevel: 'N/A',
        type: type,
        description: 'Gardırobunuzda henüz kıyafet bulunmuyor.',
      );
    }

    // 1. Filter out items based on weather temperature
    final temp = weather.temperature;
    
    List<ClothingItem> candidates = _items;

    // Filter by season appropriateness
    if (temp > 25) {
      // Hot Weather: Exclude heavy layers, long boots, kış items
      candidates = candidates.where((i) => 
        i.season != 'Kış' && 
        i.category != 'Mont' && 
        i.category != 'Ceket' &&
        i.fabricType != 'Yün' &&
        i.fabricType != 'Deri'
      ).toList();
    } else if (temp < 12) {
      // Cold Weather: Exclude shorts, lightweight linen, yaz items
      candidates = candidates.where((i) => 
        i.season != 'Yaz' && 
        i.category != 'Şort' &&
        i.fabricType != 'Keten'
      ).toList();
    }

    // Segregate categories
    List<ClothingItem> tops = candidates.where((i) => i.category == 'Tişört' || i.category == 'Gömlek').toList();
    List<ClothingItem> bottoms = candidates.where((i) => i.category == 'Pantolon' || i.category == 'Şort').toList();
    List<ClothingItem> shoes = candidates.where((i) => i.category == 'Ayakkabı').toList();
    List<ClothingItem> outer = candidates.where((i) => i.category == 'Ceket' || i.category == 'Mont').toList();
    List<ClothingItem> accessories = candidates.where((i) => i.category == 'Aksesuar').toList();

    // Check fallback if category lists are empty
    if (tops.isEmpty) tops = _items.where((i) => i.category == 'Tişört' || i.category == 'Gömlek').toList();
    if (bottoms.isEmpty) bottoms = _items.where((i) => i.category == 'Pantolon' || i.category == 'Şort').toList();
    if (shoes.isEmpty) shoes = _items.where((i) => i.category == 'Ayakkabı').toList();

    // Prioritize least worn items / not worn in last 3 days
    final now = DateTime.now();
    
    double getPriorityScore(ClothingItem item) {
      double score = 100.0;
      // Penalty for usage count
      score -= item.usageCount * 5.0;
      // Penalty for being worn recently
      if (item.lastWorn != null) {
        final daysSinceWorn = now.difference(item.lastWorn!).inDays;
        if (daysSinceWorn < 3) {
          score -= (4 - daysSinceWorn) * 20.0; // Heavy penalty if worn yesterday or today
        }
      }
      // Bonus if it matches user style preference
      if (_profile != null && item.style.toLowerCase() == _profile!.stylePreference.toLowerCase()) {
        score += 20.0;
      }
      return score;
    }

    // Sort lists by priority
    tops.sort((a, b) => getPriorityScore(b).compareTo(getPriorityScore(a)));
    bottoms.sort((a, b) => getPriorityScore(b).compareTo(getPriorityScore(a)));
    shoes.sort((a, b) => getPriorityScore(b).compareTo(getPriorityScore(a)));
    outer.sort((a, b) => getPriorityScore(b).compareTo(getPriorityScore(a)));
    accessories.sort((a, b) => getPriorityScore(b).compareTo(getPriorityScore(a)));

    // Choose top matching items
    final selectedTop = tops.isNotEmpty ? tops.first : null;
    final selectedBottom = bottoms.isNotEmpty ? bottoms.first : null;
    final selectedShoe = shoes.isNotEmpty ? shoes.first : null;

    final List<ClothingItem> outfitItems = [];
    if (selectedTop != null) outfitItems.add(selectedTop);
    if (selectedBottom != null) outfitItems.add(selectedBottom);
    if (selectedShoe != null) outfitItems.add(selectedShoe);

    // Weather based outer layer inclusion
    if (temp < 18) {
      // Recommend Jacket or Coat
      if (temp < 10) {
        final coat = outer.firstWhere((i) => i.category == 'Mont', orElse: () => outer.isNotEmpty ? outer.first : _items.firstWhere((i) => i.category == 'Mont', orElse: () => _items.first));
        if (coat.category == 'Mont' || coat.category == 'Ceket') outfitItems.add(coat);
      } else {
        final jacket = outer.firstWhere((i) => i.category == 'Ceket', orElse: () => outer.isNotEmpty ? outer.first : _items.firstWhere((i) => i.category == 'Ceket', orElse: () => _items.first));
        if (jacket.category == 'Ceket' || jacket.category == 'Mont') outfitItems.add(jacket);
      }
    }

    // Add accessory if available
    if (accessories.isNotEmpty) {
      outfitItems.add(accessories.first);
    }

    // Calculate details
    int harmony = 85;
    if (selectedTop != null && selectedBottom != null) {
      // Basic color harmony rule
      final topColor = selectedTop.color.toLowerCase();
      final bottomColor = selectedBottom.color.toLowerCase();
      if ((topColor == 'siyah' || topColor == 'beyaz') || (bottomColor == 'siyah' || bottomColor == 'beyaz')) {
        harmony += 10;
      } else if (topColor == 'lacivert' && bottomColor == 'bej') {
        harmony += 12;
      } else if (topColor == 'gri' && bottomColor == 'siyah') {
        harmony += 10;
      } else {
        harmony -= 5;
      }
    }
    harmony = min(100, max(50, harmony));

    String formality = 'Casual';
    if (type == 'İş Kombini') {
      formality = 'Resmi / Smart Casual';
    } else if (type == 'Akşam Kombini') {
      formality = 'Smart Casual';
    } else if (type == 'Hafta Sonu Kombini') {
      formality = 'Spor / Rahat';
    } else {
      formality = _profile?.stylePreference ?? 'Casual';
    }

    String seasonSuit = 'Çok Uygun';
    if (temp > 25 && outfitItems.any((i) => i.season == 'Kış')) {
      seasonSuit = 'Düşük';
    }

    String turkishType = 'Günlük Kombin';
    if (type == 'İş Kombini') {
      turkishType = 'İş Kombini';
    } else if (type == 'Akşam Kombini') {
      turkishType = 'Akşam Kombini';
    } else if (type == 'Hafta Sonu Kombini') {
      turkishType = 'Hafta Sonu Kombini';
    }

    return Combination(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: outfitItems,
      harmonyScore: harmony,
      seasonSuitability: seasonSuit,
      formalityLevel: formality,
      type: turkishType,
      description: "Bugünkü hava durumuna (${temp}°C) ve kişisel tarzınıza göre özenle seçilmiştir. ${selectedTop?.color} ve ${selectedBottom?.color} renk blokları dengeli bir görsel uyum yakalıyor.",
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
        imagePath: 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500',
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
        imagePath: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=500',
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
        imagePath: 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=500',
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
        imagePath: 'https://images.unsplash.com/photo-1479064555552-3ef4979f8908?w=500',
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
        imagePath: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=500',
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
        imagePath: 'https://images.unsplash.com/photo-1520639888713-7851133b1ed0?w=500',
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
        imagePath: 'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=500',
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
        imagePath: 'https://images.unsplash.com/photo-1513838279014-a89f7a76ae86?w=500',
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
