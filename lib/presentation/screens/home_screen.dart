import 'dart:math';
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

  // Manual combination builder state
  String _seasonFilter = 'Tümü';
  String _styleFilter = 'Tümü';
  String _colorFilter = 'Tümü';

  ClothingItem? _selectedManualTop;
  ClothingItem? _selectedManualBottom;
  ClothingItem? _selectedManualShoe;

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

  void _showApiKeyDialog() {
    final state = Provider.of<WardrobeState>(context, listen: false);
    final controller = TextEditingController(text: state.openAiApiKey ?? '');

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: theme.primaryColor),
              const SizedBox(width: 12),
              const Text('OpenAI API Anahtarı'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Yapay zeka kombin önerilerini gerçek zamanlı OpenAI API kullanarak üretmek için API anahtarınızı girin.'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'sk-proj-xxxxxxxxxxxxxxxxxxxxxxxx',
                  labelText: 'API Key',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await state.saveApiKey(controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(controller.text.trim().isEmpty 
                          ? 'API anahtarı temizlendi. Mock servise geçildi.' 
                          : 'API anahtarı kaydedildi!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _fetchWeatherAndRecommendation();
                }
              },
              child: const Text('Kaydet'),
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
      
      final combo = await wardrobeState.generateOutfitRecommendation(weather, type: 'Daily');

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

  void _showAlternativeCombo(String styleType) async {
    if (_weather == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final wardrobeState = Provider.of<WardrobeState>(context, listen: false);
      final combo = await wardrobeState.generateOutfitRecommendation(_weather!, type: styleType);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading indicator

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
                    Navigator.pop(context); // Close bottom sheet
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
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kombin üretilemedi: $e')),
        );
      }
    }
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
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.vpn_key_outlined),
                            tooltip: 'API Anahtarı',
                            onPressed: _showApiKeyDialog,
                          ),
                          const SizedBox(width: 8),
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
                  const Divider(height: 48, thickness: 1),
                  _buildManualComboBuilder(wardrobeState),
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

  Widget _buildManualComboBuilder(WardrobeState wardrobeState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter items
    List<ClothingItem> filteredItems = wardrobeState.items.where((item) {
      final matchesSeason = _seasonFilter == 'Tümü' || item.season == _seasonFilter || item.season == 'Mevsimsiz';
      final matchesStyle = _styleFilter == 'Tümü' || item.style == _styleFilter;
      final matchesColor = _colorFilter == 'Tümü' || item.color == _colorFilter;
      return matchesSeason && matchesStyle && matchesColor;
    }).toList();

    List<ClothingItem> tops = filteredItems.where((i) => i.category == 'Tişört' || i.category == 'Gömlek').toList();
    List<ClothingItem> bottoms = filteredItems.where((i) => i.category == 'Pantolon' || i.category == 'Şort').toList();
    List<ClothingItem> shoes = filteredItems.where((i) => i.category == 'Ayakkabı').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kendi Kombinini Yap',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Dolabındaki parçaları filtrele ve üzerine dokunarak kombinini oluştur.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),

        _buildFilterControls(),
        const SizedBox(height: 20),

        _buildHorizontalItemSelector('Üst Giyim (Tişört & Gömlek)', tops, _selectedManualTop, (item) {
          setState(() {
            _selectedManualTop = _selectedManualTop?.id == item.id ? null : item;
          });
        }),
        const SizedBox(height: 20),

        _buildHorizontalItemSelector('Alt Giyim (Pantolon & Şort)', bottoms, _selectedManualBottom, (item) {
          setState(() {
            _selectedManualBottom = _selectedManualBottom?.id == item.id ? null : item;
          });
        }),
        const SizedBox(height: 20),

        _buildHorizontalItemSelector('Ayakkabılar', shoes, _selectedManualShoe, (item) {
          setState(() {
            _selectedManualShoe = _selectedManualShoe?.id == item.id ? null : item;
          });
        }),
        const SizedBox(height: 28),

        _buildManualComboPreviewCard(wardrobeState),
      ],
    );
  }

  Widget _buildFilterControls() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterMenu(
            label: 'Mevsim: $_seasonFilter',
            icon: Icons.filter_drama_outlined,
            options: ['Tümü', 'Yaz', 'Kış', 'İlkbahar/Sonbahar', 'Mevsimsiz'],
            onSelected: (val) => setState(() => _seasonFilter = val),
          ),
          const SizedBox(width: 8),
          _buildFilterMenu(
            label: 'Tarz: $_styleFilter',
            icon: Icons.palette_outlined,
            options: ['Tümü', 'Casual', 'Smart Casual', 'Klasik', 'Spor'],
            onSelected: (val) => setState(() => _styleFilter = val),
          ),
          const SizedBox(width: 8),
          _buildFilterMenu(
            label: 'Renk: $_colorFilter',
            icon: Icons.color_lens_outlined,
            options: ['Tümü', 'Siyah', 'Beyaz', 'Bej', 'Lacivert', 'Gri', 'Haki', 'Bordo', 'Mavi'],
            onSelected: (val) => setState(() => _colorFilter = val),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterMenu({
    required String label,
    required IconData icon,
    required List<String> options,
    required Function(String) onSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (context) {
        return options.map((opt) {
          return PopupMenuItem<String>(
            value: opt,
            child: Text(opt),
          );
        }).toList();
      },
      child: Chip(
        avatar: Icon(icon, size: 16, color: theme.primaryColor),
        label: Text(label),
        backgroundColor: theme.cardColor,
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildHorizontalItemSelector(
    String title,
    List<ClothingItem> items,
    ClothingItem? selectedItem,
    Function(ClothingItem) onTap,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            '$title (${items.length})',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        items.isEmpty
            ? Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Eşleşen kıyafet bulunamadı.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              )
            : SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = selectedItem?.id == item.id;

                    return GestureDetector(
                      onTap: () => onTap(item),
                      child: Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.primaryColor.withOpacity(0.15) : theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected 
                                ? theme.primaryColor 
                                : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                            width: isSelected ? 2 : 1.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 20,
                                            color: theme.primaryColor.withOpacity(0.4),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.color} ${item.pattern}',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item.style,
                                    style: const TextStyle(fontSize: 8, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Positioned(
                                top: 4,
                                right: 4,
                                child: CircleAvatar(
                                  radius: 8,
                                  backgroundColor: Colors.amber,
                                  child: Icon(Icons.check, size: 10, color: Colors.black),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildManualComboPreviewCard(WardrobeState wardrobeState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_selectedManualTop == null && _selectedManualBottom == null && _selectedManualShoe == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
          ),
        ),
        child: const Center(
          child: Text('Kombin önizlemesi için yukarıdan kıyafet seçin.'),
        ),
      );
    }

    final harmony = _calculateManualHarmonyScore();
    final List<ClothingItem> selectedList = [];
    if (_selectedManualTop != null) selectedList.add(_selectedManualTop!);
    if (_selectedManualBottom != null) selectedList.add(_selectedManualBottom!);
    if (_selectedManualShoe != null) selectedList.add(_selectedManualShoe!);

    final tempCombo = Combination(
      id: 'manual',
      items: selectedList,
      harmonyScore: harmony,
      seasonSuitability: _seasonFilter == 'Tümü' ? 'Uyumlu' : _seasonFilter,
      formalityLevel: _selectedManualTop?.style ?? 'Casual',
      type: 'Kendi Kombinim',
      description: 'Sizin tarafınızdan manuel olarak oluşturulmuş özel kombin.',
    );

    return Card(
      elevation: 0,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Oluşturulan Kombin',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildComboItemDetails(tempCombo),
            const Divider(height: 32, thickness: 1),
            _buildMetricsRow(tempCombo),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      wardrobeState.recordWearToday(tempCombo);
                      
                      setState(() {
                        _selectedManualTop = null;
                        _selectedManualBottom = null;
                        _selectedManualShoe = null;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: const [
                              Icon(Icons.check_circle, color: Colors.amber),
                              SizedBox(width: 12),
                              Text('Manuel kombin bugün giyildi olarak kaydedildi!'),
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
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedManualTop = null;
                      _selectedManualBottom = null;
                      _selectedManualShoe = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Icon(Icons.clear_all),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _calculateManualHarmonyScore() {
    if (_selectedManualTop == null || _selectedManualBottom == null) return 50;
    int score = 75;
    final topColor = _selectedManualTop!.color.toLowerCase();
    final bottomColor = _selectedManualBottom!.color.toLowerCase();

    if (topColor == bottomColor) {
      score += 5;
    } else if ((topColor == 'siyah' || topColor == 'beyaz') || (bottomColor == 'siyah' || bottomColor == 'beyaz')) {
      score += 15;
    } else if (topColor == 'lacivert' && bottomColor == 'bej') {
      score += 18;
    } else if (topColor == 'gri' && bottomColor == 'siyah') {
      score += 15;
    } else if (topColor == 'haki' && bottomColor == 'siyah') {
      score += 12;
    } else {
      score -= 10;
    }

    if (_selectedManualShoe != null) {
      final shoeColor = _selectedManualShoe!.color.toLowerCase();
      if (shoeColor == topColor || shoeColor == bottomColor) {
        score += 7;
      }
    }
    
    if (_selectedManualTop!.style == _selectedManualBottom!.style) {
      score += 8;
    }

    return min(100, max(40, score));
  }
}
