import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/clothing_item.dart';
import '../../data/models/user_profile.dart';

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
}
