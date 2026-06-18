import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final double feelsLike;
  final double rainProbability; // 0.0 to 1.0 (or percentage 0-100)
  final double windSpeed; // km/h
  final String condition; // e.g., Açık, Yağmurlu, Bulutlu, Karlı
  final String cityName;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.rainProbability,
    required this.windSpeed,
    required this.condition,
    required this.cityName,
  });

  factory WeatherData.mockSunny() {
    return WeatherData(
      temperature: 28.5,
      feelsLike: 29.5,
      rainProbability: 5,
      windSpeed: 12.0,
      condition: 'Güneşli',
      cityName: 'İstanbul',
    );
  }

  factory WeatherData.mockRainy() {
    return WeatherData(
      temperature: 14.0,
      feelsLike: 12.5,
      rainProbability: 85,
      windSpeed: 22.0,
      condition: 'Yağmurlu',
      cityName: 'İstanbul',
    );
  }

  factory WeatherData.mockCold() {
    return WeatherData(
      temperature: 4.5,
      feelsLike: 1.0,
      rainProbability: 40,
      windSpeed: 18.0,
      condition: 'Karlı Karışık',
      cityName: 'İstanbul',
    );
  }
}

abstract class WeatherService {
  Future<WeatherData> fetchWeather({double? lat, double? lon});
}

class MockWeatherService implements WeatherService {
  @override
  Future<WeatherData> fetchWeather({double? lat, double? lon}) async {
    // Simulate API network call delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Return weather based on local hour or randomly
    final hour = DateTime.now().hour;
    if (hour >= 20 || hour < 6) {
      // Night weather
      return WeatherData(
        temperature: 19.0,
        feelsLike: 18.0,
        rainProbability: 15,
        windSpeed: 8.5,
        condition: 'Bulutlu',
        cityName: 'İstanbul',
      );
    } else {
      // Daytime weather: Summer simulation by default
      return WeatherData(
        temperature: 26.5,
        feelsLike: 27.0,
        rainProbability: 10,
        windSpeed: 10.2,
        condition: 'Güneşli',
        cityName: 'İstanbul',
      );
    }
  }
}

class OpenWeatherService implements WeatherService {
  final String apiKey;
  final String city;

  OpenWeatherService({required this.apiKey, this.city = 'Istanbul'});

  @override
  Future<WeatherData> fetchWeather({double? lat, double? lon}) async {
    try {
      String url = '';
      if (lat != null && lon != null) {
        url = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=tr';
      } else {
        url = 'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=tr';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        double temp = (data['main']['temp'] as num).toDouble();
        double feels = (data['main']['feels_like'] as num).toDouble();
        double wind = (data['wind']['speed'] as num).toDouble() * 3.6; // convert to km/h
        
        // Rain probability - OpenWeather 5-day forecast would show pop, current weather doesn't.
        // We will approximate or use rain volume if exists
        double rainProb = 0.0;
        if (data['rain'] != null) {
          rainProb = 80.0; // high chance if currently raining
        } else if (data['clouds'] != null) {
          rainProb = (data['clouds']['all'] as num).toDouble() * 0.3; // estimate based on cloud cover
        }

        String condition = 'Açık';
        if (data['weather'] != null && data['weather'].isNotEmpty) {
          condition = data['weather'][0]['description'];
          // Capitalize first letter
          condition = condition.substring(0, 1).toUpperCase() + condition.substring(1);
        }

        return WeatherData(
          temperature: temp,
          feelsLike: feels,
          rainProbability: rainProb,
          windSpeed: wind,
          condition: condition,
          cityName: data['name'] ?? city,
        );
      } else {
        throw Exception('Hava durumu alınamadı');
      }
    } catch (e) {
      // Fallback to mock on error
      return MockWeatherService().fetchWeather();
    }
  }
}
