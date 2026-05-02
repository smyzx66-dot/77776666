import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HamidAcademyApp());
}

class HamidAcademyApp extends StatelessWidget {
  const HamidAcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hamid Academy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.tajawalTextTheme(Theme.of(context).textTheme),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HamidIntroScreen(),
        '/home': (context) => const HamidHomeScreen(),
      },
    );
  }
}

// =============================================================================
// شاشة الترحيب الفخمة
// =============================================================================
class HamidIntroScreen extends StatefulWidget {
  const HamidIntroScreen({super.key});

  @override
  State<HamidIntroScreen> createState() => _HamidIntroScreenState();
}

class _HamidIntroScreenState extends State<HamidIntroScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
    _checkExistingUser();
  }

  void _checkExistingUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_full_name');
    if (name != null && name.isNotEmpty) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  void _saveNameAndContinue() async {
    if (_nameController.text.trim().length > 2) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_full_name', _nameController.text.trim());
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("يا بطل اكتب اسمك الحقيقي حتى نرحب بيك!",
            style: GoogleFonts.tajawal()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // تأثيرات الإضاءة الخلفية بأداء عالي (Static Blur)
          Positioned(
            top: -100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3B82F6).withOpacity(0.2)),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF06B6D4).withOpacity(0.2)),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFC107), size: 80),
                      const SizedBox(height: 20),
                      Text(
                        "أهلاً بك في عالمك الهادئ\nللدراسة بشكل أفضل 🇮🇶",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.5,
                            shadows: [
                              const Shadow(
                                  color: Colors.black45,
                                  blurRadius: 10,
                                  offset: Offset(0, 5))
                            ]),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "منصة حميد أكاديمي - لطلاب السادس العلمي",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                            fontSize: 14, color: Colors.white70),
                      ),
                      const SizedBox(height: 50),

                      // حقل إدخال الاسم بتصميم زجاجي
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.1)),
                            ),
                            child: TextField(
                              controller: _nameController,
                              style: GoogleFonts.tajawal(
                                  color: Colors.white, fontSize: 18),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "اكتب اسمك الأول ...",
                                hintStyle:
                                    GoogleFonts.tajawal(color: Colors.white54),
                                icon: const Icon(Icons.person_outline,
                                    color: Color(0xFF06B6D4)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // زر الدخول الفخم
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            elevation: 10,
                            shadowColor:
                                const Color(0xFF3B82F6).withOpacity(0.5),
                          ),
                          onPressed: _saveNameAndContinue,
                          child: Text("الاستمرار  🚀",
                              style: GoogleFonts.tajawal(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// الشاشة الرئيسية (Home Screen) - تصميم جديد وخيالي
// =============================================================================
class HamidHomeScreen extends StatefulWidget {
  const HamidHomeScreen({super.key});

  @override
  State<HamidHomeScreen> createState() => _HamidHomeScreenState();
}

class _HamidHomeScreenState extends State<HamidHomeScreen> {
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  void _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_full_name') ?? "بطل السادس";
    });
  }

  // قائمة المواد الدراسية
  final List<Map<String, dynamic>> _subjects = [
    {
      "name": "الرياضيات",
      "icon": Icons.calculate,
      "color": const Color(0xFFF43F5E)
    },
    {"name": "الفيزياء", "icon": Icons.bolt, "color": const Color(0xFFEAB308)},
    {
      "name": "الكيمياء",
      "icon": Icons.science,
      "color": const Color(0xFF10B981)
    },
    {
      "name": "الأحياء",
      "icon": Icons.biotech,
      "color": const Color(0xFF8B5CF6)
    },
    {
      "name": "العربي",
      "icon": Icons.menu_book,
      "color": const Color(0xFF3B82F6)
    },
    {
      "name": "الإنكليزي",
      "icon": Icons.language,
      "color": const Color(0xFF06B6D4)
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const HamidDrawer(),
      body: Stack(
        children: [
          // خلفية هادئة
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الشريط العلوي المخصص (Custom AppBar)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (ctx) => IconButton(
                          icon: const Icon(Icons.sort,
                              color: Colors.white, size: 30),
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
                      Text("أكاديمية حميد",
                          style: GoogleFonts.tajawal(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF3B82F6),
                        child: Icon(Icons.person, color: Colors.white),
                      )
                    ],
                  ),
                ),

                // رسالة الترحيب
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("مرحباً يا،",
                          style: GoogleFonts.cairo(
                              fontSize: 18, color: Colors.white70)),
                      Text("$_userName 👋",
                          style: GoogleFonts.tajawal(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const SizedBox(height: 5),
                      Text("اختر المادة وابدأ رحلة التفوق...",
                          style: GoogleFonts.cairo(
                              fontSize: 14, color: const Color(0xFF06B6D4))),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // شبكة المواد الدراسية (Grid)
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      return _buildSubjectCard(
                          subject['name'], subject['icon'], subject['color']);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // تصميم كرت المادة
  Widget _buildSubjectCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            // هنا تضع مسار الانتقال لدروس المادة
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// القائمة الجانبية (Drawer) الاحترافية
// =============================================================================
class HamidDrawer extends StatefulWidget {
  const HamidDrawer({super.key});

  @override
  State<HamidDrawer> createState() => _HamidDrawerState();
}

class _HamidDrawerState extends State<HamidDrawer> {
  String _userName = "طالب سادس";

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  void _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_full_name') ?? "طالب سادس";
    });
  }

  void _launchTelegram() async {
    const url = "https://t.me/od7cc";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.school, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 15),
                Text(
                  "أهلاً بك يا،",
                  style: GoogleFonts.cairo(fontSize: 14, color: Colors.white70),
                ),
                Text(
                  _userName,
                  style: GoogleFonts.tajawal(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_circle,
                      color: Color(0xFFFFC107), size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "تذكر: التعب يروح وتبقى النتيجة، ادرس بذكاء يا بطل!",
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: InkWell(
              onTap: _launchTelegram,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0088CC), Color(0xFF00A2F5)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF0088CC).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.telegram, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text("قناة التليجرام",
                        style: GoogleFonts.tajawal(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
