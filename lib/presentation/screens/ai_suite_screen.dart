import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../domain/state/wardrobe_state.dart';
import '../../core/services/ai_service.dart';

class AISuiteScreen extends StatefulWidget {
  const AISuiteScreen({Key? key}) : super(key: key);

  @override
  State<AISuiteScreen> createState() => _AISuiteScreenState();
}

class _AISuiteScreenState extends State<AISuiteScreen> {
  final AIService _aiService = MockAIService();
  bool _analyzingOutfit = false;
  OutfitAnalysisResult? _analysisResult;
  String _uploadImagePath = 'https://images.pexels.com/photos/291762/pexels-photo-291762.jpeg?auto=compress&cs=tinysrgb&w=500'; // Default model photo (Using Pexels)
  
  // Chat stylist fields
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _chatLoading = false;

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _triggerOutfitAnalysis() async {
    setState(() {
      _analyzingOutfit = true;
      _analysisResult = null;
    });

    final state = Provider.of<WardrobeState>(context, listen: false);
    final result = await _aiService.analyzeOutfitPhoto(_uploadImagePath, state.profile!);

    setState(() {
      _analysisResult = result;
      _analyzingOutfit = false;
    });
  }

  void _sendChatMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({'sender': 'user', 'text': text});
      _chatController.clear();
      _chatLoading = true;
    });

    final state = Provider.of<WardrobeState>(context, listen: false);
    final response = await _aiService.getChatRecommendation(text, state.items, state.profile!);

    setState(() {
      _chatMessages.add({'sender': 'ai', 'text': response});
      _chatLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = Provider.of<WardrobeState>(context);
    final metrics = state.getWardrobeScoreMetrics();
    final suggestions = state.getSmartSuggestions();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Yapay Zeka Stili',
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
              // 1. Wardrobe Score section
              _buildWardrobeScoreHeader(metrics['total'] ?? 0),
              const SizedBox(height: 16),
              _buildMetricsSubgrid(metrics),
              const SizedBox(height: 32),

              // 2. Smart Missing Piece Suggestion
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Akıllı Eksik Parça Önerileri',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildPremiumBadge(),
                ],
              ),
              const SizedBox(height: 16),
              ...suggestions.map((sug) => _buildMissingPieceCard(sug)).toList(),
              const SizedBox(height: 32),

              // 3. Combination Photo Analysis
              Text(
                'Kombin Fotoğrafı Analizi',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildOutfitAnalyzerCard(),
              const SizedBox(height: 32),

              // 4. Style Advisor Chat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Stil Danışmanı (Premium)',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildPremiumBadge(),
                ],
              ),
              const SizedBox(height: 16),
              _buildChatContainer(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFF3E5AB)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'PREMIUM',
        style: TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWardrobeScoreHeader(int totalScore) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            // Big dynamic circle gauge
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: totalScore / 100,
                    strokeWidth: 8,
                    color: theme.primaryColor,
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                  ),
                ),
                Text(
                  '$totalScore',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gardırop Skoru',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalScore > 80
                        ? 'Harika bir gardırop çeşitliliği! Renk dengeniz ve kombin verimliliğiniz üst seviyede.'
                        : 'Gardırobunuzu zenginleştirmek için eksik parçaları tamamlamanızı öneririz.',
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

  Widget _buildMetricsSubgrid(Map<String, int> metrics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.8,
      children: [
        _buildMetricTile('Yazlık Çeşitlilik', metrics['yazlik'] ?? 0),
        _buildMetricTile('Kışlık Çeşitlilik', metrics['kislik'] ?? 0),
        _buildMetricTile('İş Kombinleri', metrics['is'] ?? 0),
        _buildMetricTile('Günlük Kombinler', metrics['gunluk'] ?? 0),
        _buildMetricTile('Renk Dengesi', metrics['renkDengesi'] ?? 0),
        _buildMetricTile('Ayakkabı Çeşitliliği', metrics['ayakkabi'] ?? 0),
      ],
    );
  }

  Widget _buildMetricTile(String label, int val) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: val / 100,
                  color: theme.primaryColor,
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$val%',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissingPieceCard(Map<String, dynamic> sug) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.add_shopping_cart, color: theme.primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sug['item'] ?? '',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${sug['percentage']}% Çeşitlilik',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sug['description'] ?? '',
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

  Widget _buildOutfitAnalyzerCard() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(_uploadImagePath),
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
                        'Bugünkü Kombininizi Yükleyin',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Renk, stil, mevsim ve vücut tipi uyumunu test edin.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          // Toggle sample picture
                          setState(() {
                            _uploadImagePath = _uploadImagePath.contains('291762')
                                ? 'https://images.pexels.com/photos/991509/pexels-photo-991509.jpeg?auto=compress&cs=tinysrgb&w=500' // alternative (Using Pexels)
                                : 'https://images.pexels.com/photos/291762/pexels-photo-291762.jpeg?auto=compress&cs=tinysrgb&w=500';
                          });
                        },
                        child: const Text('Fotoğraf Değiştir'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _analyzingOutfit
                ? Center(
                    child: SpinKitPulse(
                      color: theme.primaryColor,
                      size: 40.0,
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _triggerOutfitAnalysis,
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Kombini Analiz Et'),
                  ),
            if (_analysisResult != null) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Uyum Skoru:', style: theme.textTheme.titleLarge),
                  Text(
                    '${_analysisResult!.score}/100',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFeedbackItem('Renk Uyumu', _analysisResult!.colorHarmony, Icons.color_lens_outlined),
              _buildFeedbackItem('Tarz Uyumu', _analysisResult!.styleHarmony, Icons.style_outlined),
              _buildFeedbackItem('Mevsim Uygunluğu', _analysisResult!.seasonSuitability, Icons.cloud_done_outlined),
              _buildFeedbackItem('Vücut Tipi Dengesi', _analysisResult!.bodyTypeSuitability, Icons.accessibility_new_outlined),
              const SizedBox(height: 16),
              Text(
                'Geliştirme Tavsiyeleri:',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._analysisResult!.suggestions.map((sug) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                        Expanded(child: Text(sug, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  )),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackItem(String title, String feedback, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(feedback, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatContainer() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.primaryColor.withOpacity(0.08),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.primaryColor,
                  radius: 16,
                  child: const Icon(Icons.face_retouching_natural, size: 18, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Yapay Zeka Stil Danışmanı', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const Text('Çevrimiçi • Gardırop Analisti', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),

          // Messages View
          Expanded(
            child: _chatMessages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Örn: "Bugün iş görüşmem var, gardırobundaki hangi parçaları kombinleyebilirim?"',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = _chatMessages[index];
                      final isUser = msg['sender'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isUser
                                ? theme.primaryColor
                                : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                              bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                            ),
                          ),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                          child: Text(
                            msg['text'] ?? '',
                            style: TextStyle(
                              color: isUser ? Colors.black : theme.textTheme.bodyLarge?.color,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          if (_chatLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SpinKitThreeBounce(color: theme.primaryColor, size: 20.0),
            ),

          // Chat Input
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Sorunuzu buraya yazın...',
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: theme.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black, size: 18),
                    onPressed: _sendChatMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
