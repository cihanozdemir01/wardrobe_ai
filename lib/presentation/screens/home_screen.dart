import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../core/services/weather_service.dart';
import '../../data/models/combination.dart';
import '../../data/models/clothing_item.dart';
import '../../domain/state/wardrobe_state.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/update_service.dart';
import 'package:url_launcher/url_launcher.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WeatherData? _weather;
  Combination? _dailyCombination;
  bool _loadingWeather = true;
  final WeatherService _weatherService = MockWeatherService();

  @override
  void initState() {
    super.initState();
    _fetchWeatherAndRecommendation();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await UpdateService.checkForUpdates();
    if (updateInfo.isUpdateAvailable && mounted) {
      _showUpdateDialog(updateInfo);
    }
  }

  void _showUpdateDialog(AppUpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.system_update_alt_rounded, color: theme.primaryColor),
              const SizedBox(width: 12),
              const Text('Güncelleme Mevcut!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yeni Sürüm: ${info.latestVersion}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text('Değişiklikler:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Text(info.releaseNotes.isEmpty ? 'Hata düzeltmeleri ve performans iyileştirmeleri.' : info.releaseNotes),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Daha Sonra'),
            ),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse(info.downloadUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Hemen Güncelle'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchWeatherAndRecommendation() async {
    setState(() {
      _loadingWeather = true;
    });

    try {
      final weather = await _weatherService.fetchWeather();
      final wardrobeState = Provider.of<WardrobeState>(context, listen: false);
      
      final combo = wardrobeState.generateOutfitRecommendation(weather, type: 'Daily');

      setState(() {
        _weather = weather;
        _dailyCombination = combo;
        _loadingWeather = false;
      });

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService.showMorningNotification(context);
          if (weather.rainProbability > 50) {
            NotificationService.showWeatherWarningNotification(context, weather);
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading weather: $e");
      setState(() => _loadingWeather = false);
    }
  }

  void _showAlternativeCombo(String styleType) {
    if (_weather == null) return;
    
    final wardrobeState = Provider.of<WardrobeState>(context, listen: false);
    final combo = wardrobeState.generateOutfitRecommendation(_weather!, type: styleType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                styleType,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildComboItemDetails(combo),
              const SizedBox(height: 24),
              _buildMetricsRow(combo),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  wardrobeState.recordWearToday(combo);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.amber),
                          SizedBox(width: 12),
                          Text('Kombin bugün giyildi olarak kaydedildi!'),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: const Text('Bu Kombini Giydim'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final wardrobeState = Provider.of<WardrobeState>(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchWeatherAndRecommendation,
          color: theme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Merhaba, ${wardrobeState.profile?.name ?? 'Stil Sahibi'}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bugün harika görünüyorsun.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        child: Text(
                          (wardrobeState.profile?.name ?? 'S').substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Weather Card
                  _loadingWeather
                      ? Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: SpinKitPulse(
                              color: theme.primaryColor,
                              size: 40.0,
                            ),
                          ),
                        )
                      : _buildWeatherCard(),

                  const SizedBox(height: 24),

                  // Recommended Outfit Title
                  Text(
                    'Bugün İçin Önerilen Kombin',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Combination Card
                  _loadingWeather
                      ? Container(
                          height: 350,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: SpinKitPulse(
                              color: theme.primaryColor,
                              size: 40.0,
                            ),
                          ),
                        )
                      : _buildDailyComboCard(),

                  const SizedBox(height: 32),

                  // Alternative Combo Buttons Section
                  Text(
                    'Kombin Üretici',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      _buildAlternativeButton('İş Kombini', Icons.business_center_outlined, Colors.blue),
                      _buildAlternativeButton('Günlük Kombin', Icons.wb_sunny_outlined, Colors.orange),
                      _buildAlternativeButton('Akşam Kombini', Icons.nightlife_outlined, Colors.purple),
                      _buildAlternativeButton('Hafta Sonu Kombini', Icons.sports_tennis_outlined, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_weather == null) return const SizedBox();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Weather Icon & Temp
            Icon(
              _weather!.rainProbability > 50
                  ? Icons.grain_rounded
                  : _weather!.temperature < 15
                      ? Icons.ac_unit_rounded
                      : Icons.wb_sunny_rounded,
              size: 48,
              color: theme.primaryColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_weather!.temperature.round()}°C',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _weather!.condition,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hissedilen: ${_weather!.feelsLike.round()}°C  •  Yağış İhtimali: %${_weather!.rainProbability.round()}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyComboCard() {
    if (_dailyCombination == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text('Gardırobunuzda kombin üretecek yeterli kıyafet yok.'),
        ),
      );
    }

    final theme = Theme.of(context);
    final state = Provider.of<WardrobeState>(context, listen: false);

    return Card(
      elevation: 0,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildComboItemDetails(_dailyCombination!),
            const Divider(height: 32, thickness: 1),
            _buildMetricsRow(_dailyCombination!),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      state.recordWearToday(_dailyCombination!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: const [
                              Icon(Icons.check_circle, color: Colors.amber),
                              SizedBox(width: 12),
                              Text('Bugünün kombini giyildi olarak kaydedildi!'),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    child: const Text('Mark as Worn Today'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _fetchWeatherAndRecommendation,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Icon(Icons.refresh, color: theme.primaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComboItemDetails(Combination combo) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...combo.items.map((item) {
          IconData icon = Icons.help_outline;
          switch (item.category) {
            case 'Tişört':
              icon = Icons.dry_cleaning_rounded;
              break;
            case 'Gömlek':
              icon = Icons.dry_cleaning_outlined;
              break;
            case 'Pantolon':
              icon = Icons.layers;
              break;
            case 'Şort':
              icon = Icons.crop_portrait;
              break;
            case 'Ceket':
            case 'Mont':
              icon = Icons.checkroom_rounded;
              break;
            case 'Ayakkabı':
              icon = Icons.directions_walk;
              break;
            case 'Aksesuar':
              icon = Icons.watch_rounded;
              break;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.color} ${item.category}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${item.pattern}  •  ${item.fabricType}  •  ${item.style}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 12),
        Text(
          combo.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(Combination combo) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricItem('Uyum Skoru', '${combo.harmonyScore}%', Icons.auto_awesome),
        _buildMetricItem('Mevsim', combo.seasonSuitability, Icons.cloud),
        _buildMetricItem('Resmiyet', combo.formalityLevel, Icons.business),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: theme.primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: label == 'Uyum Skoru' ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildAlternativeButton(String label, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => _showAlternativeCombo(label),
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
