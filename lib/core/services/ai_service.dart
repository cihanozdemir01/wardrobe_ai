import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/models/clothing_item.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/combination.dart';
import 'weather_service.dart';

class ClothingAnalysisResult {
  final String category;
  final String color;
  final String pattern;
  final String fabricType;
  final String season;
  final String style;

  ClothingAnalysisResult({
    required this.category,
    required this.color,
    required this.pattern,
    required this.fabricType,
    required this.season,
    required this.style,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'color': color,
    'pattern': pattern,
    'fabricType': fabricType,
    'season': season,
    'style': style,
  };
}

class OutfitAnalysisResult {
  final int score;
  final String colorHarmony;
  final String styleHarmony;
  final String seasonSuitability;
  final String bodyTypeSuitability;
  final List<String> suggestions;

  OutfitAnalysisResult({
    required this.score,
    required this.colorHarmony,
    required this.styleHarmony,
    required this.seasonSuitability,
    required this.bodyTypeSuitability,
    required this.suggestions,
  });
}

abstract class AIService {
  Future<ClothingAnalysisResult> analyzeClothingImage(String imagePath);
  Future<OutfitAnalysisResult> analyzeOutfitPhoto(String imagePath, UserProfile profile);
  Future<String> getChatRecommendation(String query, List<ClothingItem> wardrobe, UserProfile profile);
  Future<Combination> getOutfitRecommendation(WeatherData weather, List<ClothingItem> wardrobe, UserProfile profile, {String type = 'Daily'});
}

class MockAIService implements AIService {
  @override
  Future<ClothingAnalysisResult> analyzeClothingImage(String imagePath) async {
    await Future.delayed(const Duration(milliseconds: 1800));

    // Realistic classification mock
    // We can randomize between categories
    final categories = ['Tişört', 'Gömlek', 'Pantolon', 'Şort', 'Ceket', 'Mont', 'Ayakkabı', 'Aksesuar'];
    final colors = ['Siyah', 'Beyaz', 'Bej', 'Lacivert', 'Gri', 'Haki', 'Bordo'];
    final patterns = ['Düz', 'Çizgili', 'Kareli', 'Baskılı'];
    final fabrics = ['Pamuk', 'Keten', 'Denim', 'Deri', 'Yün'];
    final seasons = ['Yaz', 'Kış', 'İlkbahar/Sonbahar', 'Mevsimsiz'];
    final styles = ['Casual', 'Smart Casual', 'Klasik', 'Spor'];

    // Try to guess from image path to make mock look smart
    int idx = imagePath.toLowerCase().hashCode;

    return ClothingAnalysisResult(
      category: categories[idx % categories.length],
      color: colors[(idx + 1) % colors.length],
      pattern: patterns[(idx + 2) % patterns.length],
      fabricType: fabrics[(idx + 3) % fabrics.length],
      season: seasons[(idx + 4) % seasons.length],
      style: styles[(idx + 5) % styles.length],
    );
  }

  @override
  Future<OutfitAnalysisResult> analyzeOutfitPhoto(String imagePath, UserProfile profile) async {
    await Future.delayed(const Duration(seconds: 2));

    // Generates styling feedback based on profile
    int score = 75 + (imagePath.hashCode % 21); // Score between 75 and 95
    
    return OutfitAnalysisResult(
      score: score,
      colorHarmony: "Üst ve alt giyim renkleriniz oldukça uyumlu. Toprak tonları ile beyaz kontrastı modern bir görünüm oluşturmuş.",
      styleHarmony: "Kombininizin resmiyet seviyesi tam olarak seçtiğiniz ${profile.stylePreference} stiline uyuyor.",
      seasonSuitability: "Keten ve pamuklu kumaşların seçimi bugünkü hava sıcaklığı için mükemmel bir tercih.",
      bodyTypeSuitability: "Geniş kesim pantolon tercihi boy-kilo oranınızla dengeli bir proporsiyon sağlamış.",
      suggestions: [
        "Açık renk tonlarını tamamlamak için bej veya taba rengi deri bir kemer ekleyebilirsiniz.",
        "Metal aksesuarlarda gümüş tonları tercih ederek kombine minimalist bir şıklık katın.",
        "Ayakkabı olarak beyaz sneaker yerine süet taba loafer giymek şıklık seviyesini artıracaktır."
      ],
    );
  }

  @override
  Future<String> getChatRecommendation(String query, List<ClothingItem> wardrobe, UserProfile profile) async {
    await Future.delayed(const Duration(seconds: 1));

    if (query.toLowerCase().contains('iş') || query.toLowerCase().contains('ofis')) {
      return "İş günleriniz için gardırobunuzdaki klasik gömlek ve chino pantolonu kombinleyebilirsiniz. Üzerine ekleyeceğiniz ince ceket, smart casual tarzınızı tamamlayacaktır.";
    }

    if (query.toLowerCase().contains('hava') || query.toLowerCase().contains('yağmur')) {
      return "Bugün hafif serin ve yağışlı bir hava var. Gardırobunuzdaki su geçirmez montu ve botlarınızı tercih etmeniz hem konforlu hem de şık bir gün geçirmenizi sağlayacaktır.";
    }

    return "Kişisel stil profilinizi inceledim. Boyunuz (${profile.height} cm) ve kilonuz (${profile.weight} kg) göz önüne alındığında, vücut hatlarınızı orantılı gösterecek reglan kol kesimler veya dik yaka ceketler size çok yakışacaktır. Gardırobunuzdaki antrasit tonlarını beyaz sneakerlar ile kombinleyerek şık bir casual stil yakalayabilirsiniz.";
  }

  @override
  Future<Combination> getOutfitRecommendation(WeatherData weather, List<ClothingItem> wardrobe, UserProfile profile, {String type = 'Daily'}) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (wardrobe.isEmpty) {
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

    final temp = weather.temperature;
    List<ClothingItem> candidates = wardrobe;

    // Filter by season appropriateness
    if (temp > 25) {
      candidates = candidates.where((i) => 
        i.season != 'Kış' && 
        i.category != 'Mont' && 
        i.category != 'Ceket' &&
        i.fabricType != 'Yün' &&
        i.fabricType != 'Deri'
      ).toList();
    } else if (temp < 12) {
      candidates = candidates.where((i) => 
        i.season != 'Yaz' && 
        i.category != 'Şort' &&
        i.fabricType != 'Keten'
      ).toList();
    }

    List<ClothingItem> tops = candidates.where((i) => i.category == 'Tişört' || i.category == 'Gömlek').toList();
    List<ClothingItem> bottoms = candidates.where((i) => i.category == 'Pantolon' || i.category == 'Şort').toList();
    List<ClothingItem> shoes = candidates.where((i) => i.category == 'Ayakkabı').toList();
    List<ClothingItem> outer = candidates.where((i) => i.category == 'Ceket' || i.category == 'Mont').toList();
    List<ClothingItem> accessories = candidates.where((i) => i.category == 'Aksesuar').toList();

    if (tops.isEmpty) tops = wardrobe.where((i) => i.category == 'Tişört' || i.category == 'Gömlek').toList();
    if (bottoms.isEmpty) bottoms = wardrobe.where((i) => i.category == 'Pantolon' || i.category == 'Şort').toList();
    if (shoes.isEmpty) shoes = wardrobe.where((i) => i.category == 'Ayakkabı').toList();

    final now = DateTime.now();
    double getPriorityScore(ClothingItem item) {
      double score = 100.0;
      score -= item.usageCount * 5.0;
      if (item.lastWorn != null) {
        final daysSinceWorn = now.difference(item.lastWorn!).inDays;
        if (daysSinceWorn < 3) {
          score -= (4 - daysSinceWorn) * 20.0;
        }
      }
      if (item.style.toLowerCase() == profile.stylePreference.toLowerCase()) {
        score += 20.0;
      }
      return score;
    }

    tops.sort((a, b) => getPriorityScore(b).compareTo(getPriorityScore(a)));
    bottoms.sort((a, b) => getPriorityScore(b).compareTo(getPriorityScore(a)));
    shoes.sort((a, b) => getPriorityScore(b).compareTo(getPriorityScore(a)));
    outer.sort((a, b) => getPriorityScore(b).compareTo(getPriorityScore(a)));
    accessories.sort((a, b) => getPriorityScore(b).compareTo(getPriorityScore(a)));

    final selectedTop = tops.isNotEmpty ? tops.first : null;
    final selectedBottom = bottoms.isNotEmpty ? bottoms.first : null;
    final selectedShoe = shoes.isNotEmpty ? shoes.first : null;

    final List<ClothingItem> outfitItems = [];
    if (selectedTop != null) outfitItems.add(selectedTop);
    if (selectedBottom != null) outfitItems.add(selectedBottom);
    if (selectedShoe != null) outfitItems.add(selectedShoe);

    if (temp < 18) {
      if (temp < 10) {
        final coat = outer.firstWhere(
          (i) => i.category == 'Mont',
          orElse: () => outer.isNotEmpty ? outer.first : wardrobe.firstWhere((i) => i.category == 'Mont', orElse: () => wardrobe.first),
        );
        if (coat.category == 'Mont' || coat.category == 'Ceket') outfitItems.add(coat);
      } else {
        final jacket = outer.firstWhere(
          (i) => i.category == 'Ceket',
          orElse: () => outer.isNotEmpty ? outer.first : wardrobe.firstWhere((i) => i.category == 'Ceket', orElse: () => wardrobe.first),
        );
        if (jacket.category == 'Ceket' || jacket.category == 'Mont') outfitItems.add(jacket);
      }
    }

    if (accessories.isNotEmpty) {
      outfitItems.add(accessories.first);
    }

    int harmony = 85;
    if (selectedTop != null && selectedBottom != null) {
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
      formality = profile.stylePreference;
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
}

class OpenAIServiceImpl implements AIService {
  final String apiKey;

  OpenAIServiceImpl({required this.apiKey});

  @override
  Future<ClothingAnalysisResult> analyzeClothingImage(String imagePath) async {
    try {
      // Typically, in a real implementation we would convert the file at imagePath to base64
      // and send it to the OpenAI Chat Completions API with gpt-4o.
      // We will simulate the HTTP request here:
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Bu kıyafet resmini analiz et. Bana JSON formatında şu alanları döndür: '
                      'category (Tişört, Gömlek, Pantolon, Şort, Ceket, Mont, Ayakkabı, Aksesuar seçeneklerinden biri), '
                      'color (Türkçe ana renk adı), '
                      'pattern (Düz, Çizgili, Kareli, Desenli, Baskılı vb.), '
                      'fabricType (Pamuk, Keten, Denim, Deri, Yün vb.), '
                      'season (Yaz, Kış, İlkbahar/Sonbahar, Mevsimsiz), '
                      'style (Klasik, Casual, Smart Casual, Spor)'
                },
                // In actual deployment, we pass the base64 image here.
                // {
                //   'type': 'image_url',
                //   'image_url': {'url': 'data:image/jpeg;base64,...'}
                // }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        final content = resData['choices'][0]['message']['content'];
        final parsed = jsonDecode(content);

        return ClothingAnalysisResult(
          category: parsed['category'] ?? 'Tişört',
          color: parsed['color'] ?? 'Siyah',
          pattern: parsed['pattern'] ?? 'Düz',
          fabricType: parsed['fabricType'] ?? 'Pamuk',
          season: parsed['season'] ?? 'Yaz',
          style: parsed['style'] ?? 'Casual',
        );
      } else {
        throw Exception('OpenAI API Hatası');
      }
    } catch (e) {
      // Fallback on failure
      return MockAIService().analyzeClothingImage(imagePath);
    }
  }

  @override
  Future<OutfitAnalysisResult> analyzeOutfitPhoto(String imagePath, UserProfile profile) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Kullanıcının bu kombin fotoğrafını analiz et. Kullanıcı profili: '
                      'Yaş: ${profile.age}, Cinsiyet: ${profile.gender}, Stil: ${profile.stylePreference}. '
                      'Bana JSON formatında şu alanları döndür: '
                      'score (100 üzerinden uyum puanı tam sayı), '
                      'colorHarmony (Renk uyumu hakkında 1-2 cümlelik analiz), '
                      'styleHarmony (Stil uyumu hakkında analiz), '
                      'seasonSuitability (Mevsim uygunluğu hakkında analiz), '
                      'bodyTypeSuitability (Vücut tipi ve proporsiyon uyumu hakkında analiz), '
                      'suggestions (Kombini geliştirmek için 3 maddelik Türkçe tavsiye listesi)'
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        final content = resData['choices'][0]['message']['content'];
        final parsed = jsonDecode(content);

        return OutfitAnalysisResult(
          score: parsed['score'] ?? 85,
          colorHarmony: parsed['colorHarmony'] ?? '',
          styleHarmony: parsed['styleHarmony'] ?? '',
          seasonSuitability: parsed['seasonSuitability'] ?? '',
          bodyTypeSuitability: parsed['bodyTypeSuitability'] ?? '',
          suggestions: List<String>.from(parsed['suggestions'] ?? []),
        );
      } else {
        throw Exception('OpenAI API Hatası');
      }
    } catch (e) {
      return MockAIService().analyzeOutfitPhoto(imagePath, profile);
    }
  }

  @override
  Future<String> getChatRecommendation(String query, List<ClothingItem> wardrobe, UserProfile profile) async {
    try {
      final wardrobeSummary = wardrobe.map((item) => '- ${item.color} ${item.pattern} ${item.category} (${item.style}, ${item.season})').join('\n');
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'Sen premium bir yapay zeka stil danışmanısın. Kullanıcıya gardırobuna ve stiline göre Türkçe kişiselleştirilmiş kombin tavsiyesi sun. Kibar, bilgilendirici ve modadan anlayan bir üslup kullan.'
            },
            {
              'role': 'user',
              'content': 'Kullanıcı sorusu: "$query"\n\n'
                  'Kullanıcı Profili:\n'
                  '- Yaş: ${profile.age}\n'
                  '- Cinsiyet: ${profile.gender}\n'
                  '- Boy/Kilo: ${profile.height}cm / ${profile.weight}kg\n'
                  '- Tercih Ettiği Stil: ${profile.stylePreference}\n'
                  '- Çalışma Şekli: ${profile.workStyle}\n\n'
                  'Mevcut Gardırop Listesi:\n$wardrobeSummary\n\n'
                  'Öneri üret.'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        return resData['choices'][0]['message']['content'];
      } else {
        throw Exception('OpenAI Chat Hatası');
      }
    } catch (e) {
      return MockAIService().getChatRecommendation(query, wardrobe, profile);
    }
  }

  @override
  Future<Combination> getOutfitRecommendation(WeatherData weather, List<ClothingItem> wardrobe, UserProfile profile, {String type = 'Daily'}) async {
    try {
      final wardrobeSummary = wardrobe.map((item) => {
        'id': item.id,
        'category': item.category,
        'color': item.color,
        'pattern': item.pattern,
        'fabricType': item.fabricType,
        'season': item.season,
        'style': item.style,
      }).toList();

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'response_format': {'type': 'json_object'},
          'messages': [
            {
              'role': 'system',
              'content': 'Sen premium bir yapay zeka stil danışmanısın. Sana sunulan hava durumuna, kullanıcının profiline ve gardırobundaki kıyafet listesine göre en uyumlu kombinasyonu seçmelisin. Cevabı Türkçe ve JSON formatında döndür.'
            },
            {
              'role': 'user',
              'content': 'Kullanıcı Profili:\n'
                  '- Yaş: ${profile.age}\n'
                  '- Cinsiyet: ${profile.gender}\n'
                  '- Tarz: ${profile.stylePreference}\n'
                  '- Çalışma Tarzı: ${profile.workStyle}\n\n'
                  'Hava Durumu:\n'
                  '- Sıcaklık: ${weather.temperature}°C (Hissedilen: ${weather.feelsLike}°C)\n'
                  '- Durum: ${weather.condition}\n'
                  '- Yağış İhtimali: %${weather.rainProbability}\n\n'
                  'Kombin Türü: $type\n\n'
                  'Mevcut Gardırop Listesi (JSON):\n${jsonEncode(wardrobeSummary)}\n\n'
                  'Lütfen bu gardıroptan 1 adet Üst (Tişört veya Gömlek), 1 adet Alt (Pantolon veya Şort) ve 1 adet Ayakkabı seç. Eğer hava soğuksa (< 18°C) ek olarak 1 adet Dış Giyim (Mont veya Ceket) seçebilirsin. İstersen 1 adet Aksesuar da ekleyebilirsin. Seçtiğin kıyafetlerin id değerlerini döndürmelisin.\n\n'
                  'Cevabı şu JSON şemasına uygun olarak döndür:\n'
                  '{\n'
                  '  "selected_item_ids": ["id1", "id2", "id3"],\n'
                  '  "harmony_score": 95, // 0-100 arası uyum puanı tam sayı\n'
                  '  "season_suitability": "Çok Uygun", // Çok Uygun, Orta Uygun, Düşük\n'
                  '  "formality_level": "Smart Casual", // Spor, Casual, Smart Casual, Resmi\n'
                  '  "description": "Neden bu kombini seçtiğine dair Türkçe açıklama (1-2 cümle)."\n'
                  '}'
            }
          ]
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        final content = resData['choices'][0]['message']['content'];
        final parsed = jsonDecode(content);

        final List<dynamic> ids = parsed['selected_item_ids'] ?? [];
        final selectedItems = wardrobe.where((item) => ids.contains(item.id)).toList();

        if (selectedItems.isEmpty) {
          throw Exception('Eşleşen kıyafet bulunamadı');
        }

        return Combination(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          items: selectedItems,
          harmonyScore: parsed['harmony_score'] ?? 85,
          seasonSuitability: parsed['season_suitability'] ?? 'Çok Uygun',
          formalityLevel: parsed['formality_level'] ?? 'Casual',
          type: type,
          description: parsed['description'] ?? 'AI tarafından özel seçilmiş kombin.',
        );
      } else {
        throw Exception('API status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("OpenAI API combination failed, falling back to mock: $e");
      return MockAIService().getOutfitRecommendation(weather, wardrobe, profile, type: type);
    }
  }
}

class GeminiAIServiceImpl implements AIService {
  final String apiKey;

  GeminiAIServiceImpl({required this.apiKey});

  @override
  Future<ClothingAnalysisResult> analyzeClothingImage(String imagePath) async {
    return MockAIService().analyzeClothingImage(imagePath);
  }

  @override
  Future<OutfitAnalysisResult> analyzeOutfitPhoto(String imagePath, UserProfile profile) async {
    return MockAIService().analyzeOutfitPhoto(imagePath, profile);
  }

  @override
  Future<String> getChatRecommendation(String message, List<ClothingItem> wardrobe, UserProfile profile) async {
    try {
      final wardrobeSummary = wardrobe.map((item) => {
        'id': item.id,
        'category': item.category,
        'color': item.color,
        'season': item.season,
        'style': item.style,
      }).toList();

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Kullanıcı Sorusu: $message\n\n'
                      'Kullanıcı Gardırobu:\n${jsonEncode(wardrobeSummary)}\n\n'
                      'Kullanıcı Profili:\n- Tarz: ${profile.stylePreference}\n- Yaş: ${profile.age}\n\n'
                      'Lütfen kullanıcıya gardırobuna uygun tarz tavsiyesi ve kombin ipuçları ver. Yanıtı Türkçe ve samimi bir dille yaz.'
                }
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        return resData['candidates'][0]['content']['parts'][0]['text'] as String;
      }
      throw Exception('Gemini Chat API Error');
    } catch (e) {
      return MockAIService().getChatRecommendation(message, wardrobe, profile);
    }
  }

  @override
  Future<Combination> getOutfitRecommendation(WeatherData weather, List<ClothingItem> wardrobe, UserProfile profile, {String type = 'Daily'}) async {
    try {
      final wardrobeSummary = wardrobe.map((item) => {
        'id': item.id,
        'category': item.category,
        'color': item.color,
        'pattern': item.pattern,
        'fabricType': item.fabricType,
        'season': item.season,
        'style': item.style,
      }).toList();

      final prompt = 'Sen premium bir yapay zeka stil danışmanısın. Sana sunulan hava durumuna, kullanıcının profiline ve gardırobundaki kıyafet listesine göre en uyumlu kombinasyonu seçmelisin. Cevabı Türkçe ve JSON formatında döndür.\n\n'
          'Kullanıcı Profili:\n'
          '- Yaş: ${profile.age}\n'
          '- Cinsiyet: ${profile.gender}\n'
          '- Tarz: ${profile.stylePreference}\n'
          '- Çalışma Tarzı: ${profile.workStyle}\n\n'
          'Hava Durumu:\n'
          '- Sıcaklık: ${weather.temperature}°C (Hissedilen: ${weather.feelsLike}°C)\n'
          '- Durum: ${weather.condition}\n'
          '- Yağış İhtimali: %${weather.rainProbability}\n\n'
          'Kombin Türü: $type\n\n'
          'Mevcut Gardırop Listesi (JSON):\n${jsonEncode(wardrobeSummary)}\n\n'
          'Lütfen bu gardıroptan 1 adet Üst (Tişört veya Gömlek), 1 adet Alt (Pantolon veya Şort) ve 1 adet Ayakkabı seç. Eğer hava soğuksa (< 18°C) ek olarak 1 adet Dış Giyim (Mont veya Ceket) seçebilirsin. İstersen 1 adet Aksesuar da ekleyebilirsin. Seçtiğin kıyafetlerin id değerlerini döndürmelisin.\n\n'
          'Cevabı şu JSON şemasına uygun olarak döndür:\n'
          '{\n'
          '  "selected_item_ids": ["id1", "id2", "id3"],\n'
          '  "harmony_score": 95,\n'
          '  "season_suitability": "Çok Uygun",\n'
          '  "formality_level": "Smart Casual",\n'
          '  "description": "Neden bu kombini seçtiğine dair Türkçe açıklama."\n'
          '}';

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json'
          }
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        String text = resData['candidates'][0]['content']['parts'][0]['text'] as String;
        
        text = text.trim();
        if (text.startsWith('```json')) {
          text = text.substring(7, text.length - 3).trim();
        } else if (text.startsWith('```')) {
          text = text.substring(3, text.length - 3).trim();
        }

        final parsed = jsonDecode(text);
        final List<dynamic> ids = parsed['selected_item_ids'] ?? [];
        final selectedItems = wardrobe.where((item) => ids.contains(item.id)).toList();

        if (selectedItems.isEmpty) {
          throw Exception('Eşleşen kıyafet bulunamadı');
        }

        return Combination(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          items: selectedItems,
          harmonyScore: parsed['harmony_score'] ?? 85,
          seasonSuitability: parsed['season_suitability'] ?? 'Çok Uygun',
          formalityLevel: parsed['formality_level'] ?? 'Casual',
          type: type,
          description: parsed['description'] ?? 'Gemini tarafından özel seçilmiş kombin.',
        );
      } else {
        throw Exception('Gemini status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Gemini API combination failed, falling back to mock: $e");
      return MockAIService().getOutfitRecommendation(weather, wardrobe, profile, type: type);
    }
  }
}
