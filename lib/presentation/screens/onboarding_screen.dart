import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/user_profile.dart';
import '../../domain/state/wardrobe_state.dart';
import 'main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _age = 25;
  String _gender = 'Belirtmek İstemiyorum';
  double _height = 175.0;
  double _weight = 70.0;
  String _workStyle = 'Ofis';
  String _stylePreference = 'Smart Casual';

  final List<String> _genderOptions = ['Erkek', 'Kadın', 'Belirtmek İstemiyorum'];
  final List<String> _workStyles = ['Ofis', 'Serbest', 'Hibrit', 'Öğrenci'];
  final List<String> _stylePreferences = ['Klasik', 'Casual', 'Smart Casual', 'Spor'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // Title / Brand
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.primaryColor.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 40,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Wardrobe AI',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 36,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yapay Zeka Destekli Kişisel Stil Asistanınız',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name Field
                  Text(
                    'Adınız Soyadınız',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Örn: Ahmet Yılmaz',
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.primaryColor, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Lütfen adınızı girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Age Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Yaşınız: $_age',
                        style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                  Slider(
                    value: _age.toDouble(),
                    min: 15,
                    max: 80,
                    divisions: 65,
                    label: _age.toString(),
                    activeColor: theme.primaryColor,
                    inactiveColor: theme.primaryColor.withOpacity(0.2),
                    onChanged: (val) {
                      setState(() {
                        _age = val.round();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Gender Selector
                  Text(
                    'Cinsiyet',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _genderOptions.map((option) {
                      final isSelected = _gender == option;
                      return ChoiceChip(
                        label: Text(option),
                        selected: isSelected,
                        selectedColor: theme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : theme.textTheme.bodyLarge?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _gender = option);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Height & Weight Slider
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Boy: ${_height.round()} cm',
                              style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                            ),
                            Slider(
                              value: _height,
                              min: 140,
                              max: 220,
                              activeColor: theme.primaryColor,
                              onChanged: (val) => setState(() => _height = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kilo: ${_weight.round()} kg',
                              style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                            ),
                            Slider(
                              value: _weight,
                              min: 40,
                              max: 150,
                              activeColor: theme.primaryColor,
                              onChanged: (val) => setState(() => _weight = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Work Style
                  Text(
                    'Çalışma Şekli',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _workStyles.map((style) {
                      final isSelected = _workStyle == style;
                      return ChoiceChip(
                        label: Text(style),
                        selected: isSelected,
                        selectedColor: theme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : theme.textTheme.bodyLarge?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _workStyle = style);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Style Preference
                  Text(
                    'Tarz Tercihiniz',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _stylePreferences.map((pref) {
                      final isSelected = _stylePreference == pref;
                      return ChoiceChip(
                        label: Text(pref),
                        selected: isSelected,
                        selectedColor: theme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : theme.textTheme.bodyLarge?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _stylePreference = pref);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final profile = UserProfile(
                          name: _nameController.text.trim(),
                          age: _age,
                          gender: _gender,
                          height: _height,
                          weight: _weight,
                          workStyle: _workStyle,
                          stylePreference: _stylePreference,
                        );
                        
                        await Provider.of<WardrobeState>(context, listen: false).saveProfile(profile);
                        
                        if (mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const MainNavigation()),
                          );
                        }
                      }
                    },
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Stil Profilimi Kaydet'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
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
}
