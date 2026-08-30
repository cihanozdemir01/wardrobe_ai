import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../data/models/clothing_item.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../domain/state/wardrobe_state.dart';
import '../../core/services/ai_service.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({Key? key}) : super(key: key);

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _HomeScreenCategory {
  final String label;
  final IconData icon;

  _HomeScreenCategory(this.label, this.icon);
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  String _selectedCategory = 'Tümü';

  ImageProvider _getUniversalImageProvider(String path) {
    if (path.startsWith('http') || path.startsWith('https')) {
      return NetworkImage(
        path,
        headers: const {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        },
      );
    } else {
      return FileImage(File(path));
    }
  }

  Widget _buildUniversalImage(String path, {BoxFit fit = BoxFit.cover, Widget? errorWidget}) {
    if (path.isEmpty) {
      return errorWidget ?? const Icon(Icons.image_not_supported_outlined);
    }
    if (path.startsWith('http') || path.startsWith('https')) {
      return Image.network(
        path,
        fit: fit,
        headers: const {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const Icon(Icons.image_not_supported_outlined);
        },
      );
    } else {
      return Image.file(
        File(path),
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const Icon(Icons.image_not_supported_outlined);
        },
      );
    }
  }

  Future<void> _pickImage(ImageSource source, StateSetter setModalState, Function(String) onPicked) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, maxWidth: 1000, maxHeight: 1000, imageQuality: 85);
      if (image != null) {
        onPicked(image.path);
      }
    } catch (e) {
      debugPrint("Görsel seçme hatası: $e");
    }
  }

  final List<String> _categories = [
    'Tümü',
    'Tişört',
    'Gömlek',
    'Pantolon',
    'Şort',
    'Ceket',
    'Mont',
    'Ayakkabı',
    'Aksesuar'
  ];

  String _getMockImageForCategoryAndColor(String category, String color) {
    final normColor = color.toLowerCase().trim();
    switch (category) {
      case 'Tişört':
        if (normColor == 'siyah') {
          return 'https://images.pexels.com/photos/1043474/pexels-photo-1043474.jpeg?auto=compress&cs=tinysrgb&w=500'; // Black t-shirt
        } else if (normColor == 'lacivert' || normColor == 'mavi') {
          return 'https://images.pexels.com/photos/1232459/pexels-photo-1232459.jpeg?auto=compress&cs=tinysrgb&w=500'; // Blue t-shirt
        } else if (normColor == 'kırmızı' || normColor == 'bordo') {
          return 'https://images.pexels.com/photos/2294342/pexels-photo-2294342.jpeg?auto=compress&cs=tinysrgb&w=500'; // Red t-shirt
        } else if (normColor == 'gri') {
          return 'https://images.pexels.com/photos/428338/pexels-photo-428338.jpeg?auto=compress&cs=tinysrgb&w=500'; // Grey t-shirt
        } else if (normColor == 'haki' || normColor == 'yeşil') {
          return 'https://images.pexels.com/photos/5693889/pexels-photo-5693889.jpeg?auto=compress&cs=tinysrgb&w=500'; // Green/Khaki t-shirt
        } else if (normColor == 'bej' || normColor == 'sarı') {
          return 'https://images.pexels.com/photos/3053824/pexels-photo-3053824.jpeg?auto=compress&cs=tinysrgb&w=500'; // Beige t-shirt
        }
        return 'https://images.pexels.com/photos/991509/pexels-photo-991509.jpeg?auto=compress&cs=tinysrgb&w=500'; // White t-shirt
      case 'Gömlek':
        if (normColor == 'siyah') {
          return 'https://images.pexels.com/photos/1040855/pexels-photo-1040855.jpeg?auto=compress&cs=tinysrgb&w=500'; // Black shirt
        }
        return 'https://images.pexels.com/photos/3772506/pexels-photo-3772506.jpeg?auto=compress&cs=tinysrgb&w=500'; // White shirt
      case 'Pantolon':
        if (normColor == 'bej') {
          return 'https://images.pexels.com/photos/2068349/pexels-photo-2068349.jpeg?auto=compress&cs=tinysrgb&w=500'; // Beige pants
        }
        return 'https://images.pexels.com/photos/1598507/pexels-photo-1598507.jpeg?auto=compress&cs=tinysrgb&w=500'; // Jeans
      case 'Şort':
        return 'https://images.pexels.com/photos/11038283/pexels-photo-11038283.jpeg?auto=compress&cs=tinysrgb&w=500'; // Shorts
      case 'Ceket':
      case 'Mont':
        return 'https://images.pexels.com/photos/9834884/pexels-photo-9834884.jpeg?auto=compress&cs=tinysrgb&w=500'; // Jacket
      case 'Ayakkabı':
        return 'https://images.pexels.com/photos/1464625/pexels-photo-1464625.jpeg?auto=compress&cs=tinysrgb&w=500'; // Sneakers
      case 'Aksesuar':
      default:
        return 'https://images.pexels.com/photos/13050849/pexels-photo-13050849.jpeg?auto=compress&cs=tinysrgb&w=500'; // Watch
    }
  }

  void _showAddClothingDialog() {
    String mockImgPath = 'https://images.pexels.com/photos/1043474/pexels-photo-1043474.jpeg?auto=compress&cs=tinysrgb&w=500'; // Default black tshirt mockup (Using Pexels)
    bool analyzing = false;

    // AI parsed form fields
    String? category = 'Tişört';
    String? color = 'Siyah';
    String? pattern = 'Düz';
    String? fabric = 'Pamuk';
    String? season = 'Yaz';
    String? style = 'Casual';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
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
                    const SizedBox(height: 16),
                    Text(
                      'Yeni Kıyafet Ekle',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Image selector mock
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.grey.withOpacity(0.1),
                              image: DecorationImage(
                                image: _getUniversalImageProvider(mockImgPath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: theme.primaryColor,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (subContext) {
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.photo_library),
                                              title: const Text('Galeriden Fotoğraf Seç'),
                                              onTap: () {
                                                Navigator.pop(subContext);
                                                _pickImage(ImageSource.gallery, setModalState, (path) {
                                                  setModalState(() {
                                                    mockImgPath = path;
                                                  });
                                                });
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.camera_alt),
                                              title: const Text('Kamera ile Fotoğraf Çek'),
                                              onTap: () {
                                                Navigator.pop(subContext);
                                                _pickImage(ImageSource.camera, setModalState, (path) {
                                                  setModalState(() {
                                                    mockImgPath = path;
                                                  });
                                                });
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.image_search),
                                              title: const Text('Varsayılan Stok Görsele Sıfırla'),
                                              onTap: () {
                                                Navigator.pop(subContext);
                                                setModalState(() {
                                                  mockImgPath = _getMockImageForCategoryAndColor(category ?? 'Tişört', color ?? 'Siyah');
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // AI Scan Button
                    analyzing
                        ? Center(
                            child: SpinKitThreeBounce(
                              color: theme.primaryColor,
                              size: 30.0,
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () async {
                              setModalState(() => analyzing = true);
                              
                              final aiService = Provider.of<WardrobeState>(context, listen: false).aiService;
                              final result = await aiService.analyzeClothingImage(mockImgPath);
                              
                              setModalState(() {
                                category = result.category;
                                color = result.color;
                                pattern = result.pattern;
                                fabric = result.fabricType;
                                season = result.season;
                                style = result.style;
                                mockImgPath = _getMockImageForCategoryAndColor(category ?? 'Tişört', color ?? 'Siyah');
                                analyzing = false;
                              });
                            },
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Yapay Zeka ile Analiz Et'),
                          ),
                    const SizedBox(height: 24),

                    // Classification Form
                    _buildFormDropdown('Kategori', category, _categories.where((c) => c != 'Tümü').toList(), (val) {
                      setModalState(() {
                        category = val;
                        mockImgPath = _getMockImageForCategoryAndColor(category ?? 'Tişört', color ?? 'Siyah');
                      });
                    }),
                    _buildFormDropdown('Renk', color, ['Siyah', 'Beyaz', 'Bej', 'Lacivert', 'Gri', 'Haki', 'Bordo', 'Kırmızı', 'Mavi', 'Sarı'], (val) {
                      setModalState(() {
                        color = val;
                        mockImgPath = _getMockImageForCategoryAndColor(category ?? 'Tişört', color ?? 'Siyah');
                      });
                    }),
                    _buildFormDropdown('Desen', pattern, ['Düz', 'Çizgili', 'Kareli', 'Desenli', 'Baskılı'], (val) {
                      setModalState(() => pattern = val);
                    }),
                    _buildFormDropdown('Kumaş Türü', fabric, ['Pamuk', 'Keten', 'Denim', 'Deri', 'Yün', 'Süet'], (val) {
                      setModalState(() => fabric = val);
                    }),
                    _buildFormDropdown('Mevsim', season, ['Yaz', 'Kış', 'İlkbahar/Sonbahar', 'Mevsimsiz'], (val) {
                      setModalState(() => season = val);
                    }),
                    _buildFormDropdown('Stil', style, ['Casual', 'Smart Casual', 'Klasik', 'Spor'], (val) {
                      setModalState(() => style = val);
                    }),

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: () {
                        final newItem = ClothingItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          imagePath: mockImgPath,
                          category: category!,
                          color: color!,
                          pattern: pattern!,
                          fabricType: fabric!,
                          season: season!,
                          style: style!,
                        );

                        Provider.of<WardrobeState>(context, listen: false).addItem(newItem);
                        Navigator.pop(context);
                      },
                      child: const Text('Gardıroba Ekle'),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormDropdown(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: value,
            items: options.map((opt) {
              return DropdownMenuItem(value: opt, child: Text(opt));
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showItemOptions(ClothingItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: _getUniversalImageProvider(item.imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.color} ${item.category}', style: theme.textTheme.titleLarge),
                        Text('${item.season}  •  Giyme Sayısı: ${item.usageCount}', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Kıyafeti Sil', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Provider.of<WardrobeState>(context, listen: false).deleteItem(item.id);
                  Navigator.pop(context);
                },
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
    final wardrobe = Provider.of<WardrobeState>(context);
    
    // Filter list
    final filteredItems = wardrobe.items.where((item) {
      if (_selectedCategory == 'Tümü') return true;
      return item.category == _selectedCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dijital Gardırop',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {},
          )
        ],
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter chip list
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: theme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : theme.textTheme.bodyLarge?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Items grid
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Text(
                      'Bu kategoride kıyafetiniz bulunmuyor.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return GestureDetector(
                        onTap: () => _showItemOptions(item),
                        child: Card(
                          margin: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildUniversalImage(
                                  item.imagePath,
                                  fit: BoxFit.cover,
                                  errorWidget: Container(
                                    color: Colors.grey.withOpacity(0.1),
                                    child: Icon(Icons.checkroom, color: theme.primaryColor),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.color} ${item.category}',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClothingDialog,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Kıyafet Ekle'),
      ),
    );
  }
}
