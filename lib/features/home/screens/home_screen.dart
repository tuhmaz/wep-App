import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/constants/colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/classes_provider.dart';
import '../providers/articles_provider.dart';
import '../providers/subjects_provider.dart';
import '../providers/semesters_provider.dart';
import '../providers/news_provider.dart';
import '../../../core/models/news_model.dart';  // تصحيح المسار
import 'subjects_screen.dart';
import 'news_details_screen.dart';
import 'package:extended_image/extended_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // استخدم معرف الإعلان الخاص بك في الإنتاج
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          setState(() {
            _isBannerAdReady = false;
          });
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }
  
  Future<void> _loadInitialData() async {
    final newsProvider = context.read<NewsProvider>();
    await newsProvider.setDatabase(_selectedDatabase);
    await newsProvider.fetchNews(refresh: true);
    Provider.of<ClassesProvider>(context, listen: false)
        .fetchClasses(_selectedDatabase);
  }


  String _selectedDatabase = 'jo';

  final Map<String, String> _countries = {
    'jo': 'الأردن',
    'sa': 'السعودية',
    'eg': 'مصر',
    'ps': 'فلسطين',
  };

  Widget _bannerAdWidget() {
      if (!_isBannerAdReady) {
        return const SizedBox.shrink();
      }
    
      return SizedBox(

      height: 50,
      child: _isBannerAdReady ? AdWidget(ad: _bannerAd) : const SizedBox.shrink(),
    );

  }

  void _handleGradeSelection(int gradeLevel) {
    final classItem = Provider.of<ClassesProvider>(context, listen: false)
        .classes
        .firstWhere((c) => c.gradeLevel == gradeLevel);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectsScreen(
          gradeId: classItem.id,
          gradeName: classItem.gradeName,
        ),
      ),
    );
  }

  Widget _buildGradeButton(int gradeLevel, String gradeName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: InkWell(
        onTap: () => _handleGradeSelection(gradeLevel),
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.blue.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 65,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                ),
                child: Icon(
                  Icons.looks_one,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Colors.blue.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        gradeName,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.blue,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsSection() {
    return Consumer<NewsProvider>(
      builder: (context, newsProvider, child) {
        // عرض رسالة التحميل
        if (newsProvider.isLoading && newsProvider.news.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'جاري تحميل الأخبار...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // عرض رسالة الخطأ
        if (newsProvider.error.isNotEmpty && newsProvider.news.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  newsProvider.error,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => newsProvider.refreshNews(),
                  icon: Icon(Icons.refresh),
                  label: Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        // عرض رسالة عند عدم وجود أخبار
        if (newsProvider.news.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.newspaper, color: Colors.grey[400], size: 48),
                SizedBox(height: 16),
                Text(
                  'لا توجد أخبار متاحة',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (newsProvider.selectedDatabase.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'الرجاء اختيار قاعدة بيانات',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
              ],
            ),
          );
        }

        final categories = newsProvider.uniqueCategories.where((cat) => cat != 'الكل').toList();
        
        return Column(
          children: [
            // عنوان القسم
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.category, color: Theme.of(context).primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'أقسام الأخبار',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // شبكة بطاقات الفئات
            GridView.builder(
              padding: EdgeInsets.all(16),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final color = newsProvider.getCategoryColor(category);
                final icon = newsProvider.getCategoryIcon(category);
                
                return _buildCategoryCard(context, category, newsProvider);
              },
            ),

            // عرض الأخبار المصفاة
            if (newsProvider.selectedCategory != null)
              ..._buildFilteredNews(newsProvider),
          ],
        );
      },
    );
  }

  List<Widget> _buildFilteredNews(NewsProvider newsProvider) {
    final filteredNews = newsProvider.getGroupedNews();
    
    return [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              newsProvider.getCategoryIcon(newsProvider.selectedCategory!),
              color: newsProvider.getCategoryColor(newsProvider.selectedCategory!),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'أخبار ${newsProvider.selectedCategory}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => newsProvider.selectCategory('الكل'),
              child: Text('عرض الكل'),
            ),
          ],
        ),
      ),
      ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: filteredNews.length,
        itemBuilder: (context, index) {
          final newsItem = filteredNews[index];
          return _buildNewsCard(newsItem);
        },
      ),
    ];
  }

  Widget _buildCategoryCard(BuildContext context, String category, NewsProvider newsProvider) {
    final isSelected = newsProvider.selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => newsProvider.selectCategory(category),
        child: Container(
          width: 140,
          height: 160,
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                if (isSelected)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PatternPainter(),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? Colors.white.withOpacity(0.2)
                            : Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          newsProvider.getCategoryIcon(category),
                          size: 28,
                          color: isSelected 
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsModel news) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailsScreen(news: news),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (news.image != null && news.image!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: ExtendedImage.network(
                  news.image!,
                  height: 200,
                  fit: BoxFit.cover,
                  cache: true,
                  loadStateChanged: (state) {
                    if (state.extendedImageLoadState == LoadState.loading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state.extendedImageLoadState == LoadState.failed) {
                      return const Center(
                        child: Icon(Icons.error_outline, size: 50),
                      );
                    }
                    return null;
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(news.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.category,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          news.category?.name ?? 'عام',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }





  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final classesProvider = Provider.of<ClassesProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // تحديث عدد الأعمدة: 1 للشاشات الصغيرة، 2 للشاشات الكبيرة
    final crossAxisCount = screenWidth > 600 ? 2 : 1;
    // تعديل نسبة العرض إلى الارتفاع لتقليل الارتفاع
    final childAspectRatio = crossAxisCount == 1 ? 5.0 : 3.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          'Alemedu',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDatabase,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white),
              dropdownColor: AppColors.primaryColor, 
              items: _countries.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }).toList(),
               onChanged: (String? newValue) async {
                if (newValue != null) {
                  setState(() {
                    _selectedDatabase = newValue;
                  });
                  // تحديث قاعدة البيانات في جميع الـ providers
                  await Provider.of<NewsProvider>(context, listen: false)
                      .setDatabase(newValue);
                  await Provider.of<NewsProvider>(context, listen: false)
                      .fetchNews(refresh: true);
                  classesProvider.fetchClasses(newValue);
                  Provider.of<ArticlesProvider>(context, listen: false)
                      .updateSelectedDatabase(newValue);
                  Provider.of<SubjectsProvider>(context, listen: false)
                      .updateSelectedDatabase(newValue);
                  Provider.of<SemestersProvider>(context, listen: false)
                      .updateSelectedDatabase(newValue);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          if (auth.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.dashboard, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/dashboard');
              },
            )
          else
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: const Text(
                'تسجيل الدخول',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _bannerAdWidget(),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (classesProvider.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (classesProvider.error.isNotEmpty)
                      Center(
                        child: Column(
                          children: [
                            Text(
                              classesProvider.error,
                              style: const TextStyle(color: Colors.red),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  classesProvider.fetchClasses(_selectedDatabase),
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: classesProvider.classes.length,
                            itemBuilder: (context, index) {
                              final classItem = classesProvider.classes[index];
                              return _buildGradeButton(classItem.gradeLevel, classItem.gradeName);
                            },
                          ),
                       const SizedBox(height: 32),
                       _buildNewsSection(),
                  ],
                ),
                  ),
              ),
          ],
        ),
      ),
    );
  }




}

// Custom Pattern Painter for Selected Category Cards
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final tileSize = 20.0;

    for (var i = 0; i < size.width / tileSize; i++) {
      for (var j = 0; j < size.height / tileSize; j++) {
        if ((i + j) % 2 == 0) {
          path.addRect(
            Rect.fromLTWH(
              i * tileSize,
              j * tileSize,
              tileSize,
              tileSize,
            ),
          );
        }
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
