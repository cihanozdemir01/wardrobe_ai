import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/state/wardrobe_state.dart';
import '../../data/models/clothing_item.dart';
import 'onboarding_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = Provider.of<WardrobeState>(context);
    
    final totalClothes = state.items.length;
    
    // Estimate combination capacity: Tops * Bottoms * Shoes
    int tops = state.items.where((i) => i.category == 'Tişört' || i.category == 'Gömlek').length;
    int bottoms = state.items.where((i) => i.category == 'Pantolon' || i.category == 'Şort').length;
    int shoes = state.items.where((i) => i.category == 'Ayakkabı').length;
    final comboCapacity = tops * bottoms * shoes;

    // Get sorted lists for most/least used
    List<ClothingItem> sortedByUsageDesc = List.from(state.items);
    sortedByUsageDesc.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    
    List<ClothingItem> sortedByUsageAsc = List.from(state.items);
    sortedByUsageAsc.sort((a, b) => a.usageCount.compareTo(b.usageCount));

    final topUsed = sortedByUsageDesc.take(3).toList();
    final forgottenUsed = sortedByUsageAsc.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'İstatistikler',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. General Metrics
              Row(
                children: [
                  Expanded(child: _buildCountCard('Toplam Parça', '$totalClothes', Icons.checkroom)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCountCard('Kombin Gücü', '$comboCapacity', Icons.auto_awesome)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCountCard('30 Gün Giyme', '18 Kez', Icons.today)),
                ],
              ),
              const SizedBox(height: 32),

              // 2. Category Distribution Chart
              Text(
                'Gardırop Dağılımı',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildCategoryPieChart(),
              const SizedBox(height: 32),

              // 3. Usage Frequency
              Text(
                'Giyim Alışkanlıkları',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildUsageFrequencySection(topUsed, forgottenUsed),
              const SizedBox(height: 32),

              // 4. App controls / Profile Reset
              Text(
                'Hesap & Ayarlar',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.cardColor,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Profil Bilgilerini Düzenle'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.brightness_medium_outlined),
                      title: const Text('Tema Ayarları'),
                      trailing: const Text('Sistem Teması'),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Destek & SSS'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountCard(String title, String val, IconData icon) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          children: [
            Icon(icon, color: theme.primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(
              val,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    final theme = Theme.of(context);
    final state = Provider.of<WardrobeState>(context, listen: false);

    // Count categories
    Map<String, int> catCounts = {};
    for (var item in state.items) {
      catCounts[item.category] = (catCounts[item.category] ?? 0) + 1;
    }

    if (catCounts.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: Text('Yeterli veri yok.')),
      );
    }

    final colors = [
      theme.primaryColor,
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFF9E9E9E),
    ];

    List<PieChartSectionData> sections = [];
    int colorIdx = 0;
    
    catCounts.forEach((cat, count) {
      final isTouched = sections.length == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 65.0 : 55.0;
      final double percentage = (count / state.items.length) * 100;

      sections.add(
        PieChartSectionData(
          color: colors[colorIdx % colors.length],
          value: count.toDouble(),
          title: '$cat\n%${percentage.round()}',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 4),
            ],
          ),
        ),
      );
      colorIdx++;
    });

    return Card(
      elevation: 0,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 4,
                  centerSpaceRadius: 35,
                  sections: sections,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageFrequencySection(List<ClothingItem> topUsed, List<ClothingItem> forgotten) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Most worn
        Card(
          elevation: 0,
          color: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: theme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      'En Çok Giyilen Kıyafetler',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...topUsed.map((item) => _buildUsageItemRow(item)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Least Worn
        Card(
          elevation: 0,
          color: theme.cardColor,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_down, color: Colors.blueGrey),
                    const SizedBox(width: 12),
                    Text(
                      'Uzun Süredir Giyilmeyenler',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...forgotten.map((item) => _buildUsageItemRow(item, isMuted: true)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsageItemRow(ClothingItem item, {bool isMuted = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(item.imagePath),
                fit: BoxFit.cover,
              ),
            ),
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
                  '${item.style} • ${item.season}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isMuted ? Colors.blueGrey.withOpacity(0.1) : theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${item.usageCount} Giyme',
              style: TextStyle(
                color: isMuted ? Colors.blueGrey : theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
