import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_ai/core/services/weather_service.dart';
import 'package:wardrobe_ai/data/models/clothing_item.dart';
import 'package:wardrobe_ai/data/models/combination.dart';
import 'package:wardrobe_ai/domain/state/wardrobe_state.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Wardrobe AI Engine Tests', () {
    late WardrobeState wardrobeState;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      wardrobeState = WardrobeState();
      
      // Wait for async preference load to complete
      while (wardrobeState.isLoading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    });

    test('Preloaded wardrobe items should contain at least 8 items', () {
      expect(wardrobeState.items.length, greaterThanOrEqualTo(8));
    });

    test('Outfit Recommendation filters items correctly based on hot temperature', () async {
      final hotWeather = WeatherData(
        temperature: 30.0,
        feelsLike: 31.0,
        rainProbability: 0,
        windSpeed: 5,
        condition: 'Güneşli',
        cityName: 'TestCity',
      );

      final recommendation = await wardrobeState.generateOutfitRecommendation(hotWeather);

      // Verify that no heavy coats or jackets are in the recommendation when hot
      final containsHeavyLayers = recommendation.items.any((item) => 
        item.category == 'Mont' || item.category == 'Ceket' || item.season == 'Kış'
      );
      expect(containsHeavyLayers, isFalse);
    });

    test('Outfit Recommendation filters items correctly based on cold temperature', () async {
      final coldWeather = WeatherData(
        temperature: 8.0,
        feelsLike: 5.0,
        rainProbability: 30,
        windSpeed: 25,
        condition: 'Rüzgarlı',
        cityName: 'TestCity',
      );

      final recommendation = await wardrobeState.generateOutfitRecommendation(coldWeather);

      // Verify that no shorts are in the recommendation when cold
      final containsShorts = recommendation.items.any((item) => item.category == 'Şort');
      expect(containsShorts, isFalse);
    });

    test('Wardrobe score calculations match expected ranges', () {
      final scores = wardrobeState.getWardrobeScoreMetrics();
      
      expect(scores.containsKey('total'), isTrue);
      expect(scores['total'], greaterThanOrEqualTo(0));
      expect(scores['total'], lessThanOrEqualTo(100));

      expect(scores.containsKey('yazlik'), isTrue);
      expect(scores.containsKey('kislik'), isTrue);
      expect(scores.containsKey('ayakkabi'), isTrue);
    });

    test('Smart suggestions generate capacity-increasing recommendations', () {
      final suggestions = wardrobeState.getSmartSuggestions();

      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.first.containsKey('item'), isTrue);
      expect(suggestions.first.containsKey('description'), isTrue);
      expect(suggestions.first.containsKey('percentage'), isTrue);
    });
  });
}
