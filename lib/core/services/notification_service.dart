import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class NotificationService {
  static void showMorningNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Günaydın! Bugün için stil kombin öneriniz hazır.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static void showWeatherWarningNotification(BuildContext context, WeatherData weather) {
    if (weather.rainProbability > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.umbrella, color: Colors.blueAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bugün yağmur bekleniyor. Su geçirmez ayakkabılar ve mont öneriyoruz!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.blueGrey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }
}
