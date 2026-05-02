// ignore_for_file: deprecated_member_use, use_build_context_synchronously, must_be_immutable, avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// 🔥 استدعاء مكاتب الفايربيس وملف الإشعارات
import 'package:firebase_core/firebase_core.dart';
import 'hamid_notifications.dart';

// 🔥 استدعاء ملف واجهة حميد الفخمة (تأكد من وجوده في مشروعك)
import 'hamid_ui.dart';

// -----------------------------------------------------------------------------
//  HAMID ACADEMY - MODERN FUTURE EDITION 🚀 (Bug Fixed & Stable)
// -----------------------------------------------------------------------------

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await HamidNotifications().initNotifications();
  } catch (e) {
    print("Firebase Init Error: $e");
  }

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));

  await PreferencesService().init();
  await DownloadManager().init();

  runApp(const HamidApp());
}

// =============================================================================
//  THEME & UTILS
// =============================================================================

class AppTheme {
  static const bg = Color(0xFF0F111A);
  static const primary = Color(0xFF4F46E5);
  static const accent = Color(0xFF0EA5E9);
  static const surface = Color(0xFF1E202A);
  static const surfaceLight = Color(0xFF2A2D3E);
  static const gold = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
  static const error = Color(0xff20428d);

  static const futuristicWhite = Color(0xFFF8FAFC);

  static ThemeData get theme => ThemeData.dark().copyWith(
        scaffoldBackgroundColor: bg,
        primaryColor: primary,
        colorScheme: const ColorScheme.dark(
            primary: primary,
            secondary: accent,
            surface: surface,
            error: error),
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: futuristicWhite,
              letterSpacing: 0.5),
        ),
      );
}

Map<String, String> getPythonHeaders() {
  return {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
    'Referer': 'https://iframe.mediadelivery.net/',
    'Origin': 'https://iframe.mediadelivery.net',
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Upgrade-Insecure-Requests': '1'
  };
}

String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) return "$hours:$minutes:$seconds";
  return "$minutes:$seconds";
}

// =============================================================================
//  MANAGERS & LOGIC
// =============================================================================

class PythonLikeExtractor {
  static Future<String?> extractVideoUrl(String pageUrl) async {
    try {
      final response = await http
          .get(
            Uri.parse(pageUrl),
            headers: getPythonHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;
      final html = response.body;

      final metaRegex = RegExp(
        r'<meta\s+property="og:video:(?:url|secure_url)"\s+content="([^"]+)"',
        caseSensitive: false,
      );
      final metaMatch = metaRegex.firstMatch(html);
      if (metaMatch != null) return metaMatch.group(1);

      final mp4Regex = RegExp(r'https?://[^\s<>"]+\.mp4[^\s<>"]*');
      final mp4Match = mp4Regex.firstMatch(html);
      if (mp4Match != null) return mp4Match.group(0);

      return null;
    } catch (e) {
      return null;
    }
  }
}

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  late SharedPreferences _prefs;
  final ValueNotifier<List<String>> favoriteTeachers = ValueNotifier([]);
  final ValueNotifier<List<String>> completedLectures = ValueNotifier([]);

  // 🔥 ميزة سجل المشاهدة
  final ValueNotifier<Map<String, dynamic>?> lastWatchedLecture =
      ValueNotifier(null);

  bool get isSubscribedToTelegram =>
      _prefs.getBool('telegram_subscribed') ?? false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    favoriteTeachers.value = _prefs.getStringList('fav_teachers') ?? [];
    completedLectures.value = _prefs.getStringList('completed_lectures') ?? [];

    // استرجاع آخر فيديو شافه الطالب
    String? lastWatchedJson = _prefs.getString('last_watched_lecture');
    if (lastWatchedJson != null) {
      lastWatchedLecture.value = json.decode(lastWatchedJson);
    }
  }

  // 🔥 ميزة حفظ وقراءة الملاحظات الخاصة بكل محاضرة
  Future<void> saveNoteForLecture(String lectureId, String note) async {
    await _prefs.setString('note_$lectureId', note);
  }

  String getNoteForLecture(String lectureId) {
    return _prefs.getString('note_$lectureId') ?? "";
  }

  // 🔥 دالة التحقق من التليجرام (مرتين باليوم فقط)
  bool canShowTelegramDialog() {
    if (isSubscribedToTelegram) return false;

    String today =
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    int count = _prefs.getInt('tg_dialog_count_$today') ?? 0;

    if (count < 2) {
      _prefs.setInt('tg_dialog_count_$today', count + 1);
      return true;
    }
    return false;
  }

  void toggleFavorite(String teacherName) {
    List<String> current = List.from(favoriteTeachers.value);
    if (current.contains(teacherName)) {
      current.remove(teacherName);
    } else {
      current.add(teacherName);
    }
    _prefs.setStringList('fav_teachers', current);
    favoriteTeachers.value = current;
  }

  void toggleLectureCompletion(String lectureId) {
    List<String> current = List.from(completedLectures.value);
    if (current.contains(lectureId)) {
      current.remove(lectureId);
    } else {
      current.add(lectureId);
    }
    _prefs.setStringList('completed_lectures', current);
    completedLectures.value = current;
  }

  Future<void> setTelegramSubscribed() async {
    await _prefs.setBool('telegram_subscribed', true);
  }

  // 🔥 حفظ وتحديث موقع المشاهدة
  Future<void> saveVideoProgress(
      String url, String title, Duration position, Duration duration) async {
    final data = {
      'url': url,
      'title': title,
      'position': position.inSeconds,
      'duration': duration.inSeconds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // نحفظ موقع هذا الرابط تحديداً
    await _prefs.setInt('pos_$url', position.inSeconds);

    // نحفظه كآخر شيء انشاف
    await _prefs.setString('last_watched_lecture', json.encode(data));
    lastWatchedLecture.value = data;
  }

  int getVideoPosition(String url) {
    return _prefs.getInt('pos_$url') ?? 0;
  }
}

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final Dio _dio = Dio();
  final ValueNotifier<List<Map<String, dynamic>>> savedFiles =
      ValueNotifier([]);

  final ValueNotifier<Map<String, Map<String, dynamic>>> activeDownloads =
      ValueNotifier({});

  Future<void> init() async {
    await refreshFiles();
  }

  Future<void> refreshFiles() async {
    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download/HamidAcademy');
        if (!await dir.exists()) {
          try {
            dir = await getExternalStorageDirectory();
          } catch (_) {
            dir = await getApplicationDocumentsDirectory();
          }
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir != null && await dir.exists()) {
        final List<FileSystemEntity> files = dir.listSync();
        List<Map<String, dynamic>> temp = [];
        for (var file in files) {
          if (file.path.endsWith(".mp4") && (file as File).lengthSync() > 0) {
            temp.add({
              'name': file.path.split('/').last.replaceAll('.mp4', ''),
              'path': file.path,
              'size': (file.lengthSync() / (1024 * 1024)).toStringAsFixed(1)
            });
          }
        }
        savedFiles.value = temp;
      }
    } catch (_) {}
  }

  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        await refreshFiles();
      }
    } catch (_) {}
  }

  Future<void> _showProgressNotification(
      int id, String title, int progress) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_channel_id',
      'التحميلات',
      channelDescription: 'إشعارات التحميلات النشطة',
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      ongoing: true,
      icon: '@mipmap/ic_launcher',
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        id, 'جاري تحميل: $title', '$progress%', platformChannelSpecifics);
  }

  Future<void> _showCompletionNotification(
      int id, String title, bool isSuccess) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_channel_id',
      'التحميلات',
      channelDescription: 'إشعارات التحميلات النشطة',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
        id,
        isSuccess ? 'اكتمل التحميل ✅' : 'فشل التحميل ❌',
        title,
        platformChannelSpecifics);
  }

  Future<void> startDownload(
      BuildContext context, String url, String fileName) async {
    if (activeDownloads.value.containsKey(url)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("هذا الملف قيد التحميل حالياً!",
              style: GoogleFonts.tajawal()),
          backgroundColor: AppTheme.gold));
      return;
    }

    if (Platform.isAndroid) {
      if (await Permission.storage.request().isDenied) {
        await Permission.photos.request();
        await Permission.videos.request();
      }
      if (await Permission.notification.request().isDenied) {
        await Permission.notification.request();
      }
    }

    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download/HamidAcademy');
      try {
        if (!await dir.exists()) await dir.create(recursive: true);
      } catch (e) {
        dir = await getExternalStorageDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final cleanName =
        fileName.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim();
    final savePath = "${dir!.path}/$cleanName.mp4";

    if (File(savePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("الملف موجود بالفعل!", style: GoogleFonts.tajawal()),
          backgroundColor: AppTheme.success));
      return;
    }

    _updateProgress(url, cleanName, 0.01, 0, 100);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text("بدأ التحميل في الخلفية 🚀", style: GoogleFonts.tajawal()),
        backgroundColor: AppTheme.primary));

    WakelockPlus.enable();

    final int notificationId = url.hashCode;
    int lastProgressPercent = 0;

    try {
      await _showProgressNotification(notificationId, cleanName, 0);

      await _dio.download(
        url,
        savePath,
        options: Options(
          headers: getPythonHeaders(),
          responseType: ResponseType.stream,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;
            _updateProgress(url, cleanName, progress, received, total);

            int currentPercent = (progress * 100).toInt();
            if (currentPercent != lastProgressPercent &&
                currentPercent % 2 == 0) {
              lastProgressPercent = currentPercent;
              _showProgressNotification(
                  notificationId, cleanName, currentPercent);
            }
          }
        },
      );

      _removeDownload(url);
      await refreshFiles();

      await _showCompletionNotification(notificationId, cleanName, true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text("اكتمل تحميل: $cleanName", style: GoogleFonts.tajawal()),
            backgroundColor: AppTheme.success));
      }
    } catch (e) {
      print("Download Error: $e");
      _removeDownload(url);

      await flutterLocalNotificationsPlugin.cancel(notificationId);
      await _showCompletionNotification(notificationId, cleanName, false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("فشل التحميل! تأكد من الاتصال.",
                style: GoogleFonts.tajawal()),
            backgroundColor: AppTheme.error));
      }
    } finally {
      if (activeDownloads.value.isEmpty) {
        WakelockPlus.disable();
      }
    }
  }

  void _updateProgress(
      String url, String title, double progress, int received, int total) {
    final newMap =
        Map<String, Map<String, dynamic>>.from(activeDownloads.value);
    newMap[url] = {
      'title': title,
      'progress': progress,
      'received': received,
      'total': total,
    };
    activeDownloads.value = newMap;
  }

  void _removeDownload(String url) {
    final newMap =
        Map<String, Map<String, dynamic>>.from(activeDownloads.value);
    newMap.remove(url);
    activeDownloads.value = newMap;
  }
}

// =============================================================================
//  WIDGETS & DIALOGS
// =============================================================================

class CompletionButton extends StatelessWidget {
  final String lectureId;
  const CompletionButton({super.key, required this.lectureId});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: PreferencesService().completedLectures,
      builder: (context, completedList, child) {
        final isCompleted = completedList.contains(lectureId);
        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            PreferencesService().toggleLectureCompletion(lectureId);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.success : AppTheme.surface,
              border: Border.all(
                  color: isCompleted ? AppTheme.success : Colors.white24,
                  width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      },
    );
  }
}

class SmartDownloadButton extends StatefulWidget {
  final String title;
  final String iframeUrl;

  const SmartDownloadButton({
    super.key,
    required this.title,
    required this.iframeUrl,
  });

  @override
  State<SmartDownloadButton> createState() => _SmartDownloadButtonState();
}

class _SmartDownloadButtonState extends State<SmartDownloadButton> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24)),
      child: IconButton(
        tooltip: "تحميل الفيديو",
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.download_rounded, size: 28, color: Colors.white),
        onPressed: loading ? null : _executePythonLogic,
      ),
    );
  }

  Future<void> _executePythonLogic() async {
    setState(() => loading = true);
    String? videoUrl =
        await PythonLikeExtractor.extractVideoUrl(widget.iframeUrl);
    setState(() => loading = false);

    if (videoUrl != null) {
      DownloadManager().startDownload(
        context,
        videoUrl,
        widget.title,
      );
    } else {
      _showError("لم يتم العثور على رابط MP4");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.tajawal()),
        backgroundColor: AppTheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// 🚀 نافذة التليجرام
class TelegramDialog extends StatelessWidget {
  const TelegramDialog({super.key});

  final String channelUrl = "https://t.me/od7ss";
  final String logoUrl = "https://i.ibb.co/ywgrYxq/upload-1776424444.jpg";

  void _launchUrl() async {
    if (await canLaunchUrl(Uri.parse(channelUrl))) {
      await launchUrl(Uri.parse(channelUrl),
          mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                  color: AppTheme.futuristicWhite.withOpacity(0.15),
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: -5,
                )
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withOpacity(0.3),
                          Colors.transparent
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(25)),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppTheme.futuristicWhite, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 20)
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: CachedNetworkImage(
                          imageUrl: logoUrl,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(
                                  color: AppTheme.futuristicWhite),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      "تنبيه مهم  ",
                      style: GoogleFonts.tajawal(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.futuristicWhite),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "انضم لقناتي على تلي حتى ماتضيع عليك المنصة او التحديثات يوزر OD7SS.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(
                          fontSize: 14, color: Colors.white70, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    InkWell(
                      onTap: _launchUrl,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.accent]),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.primary.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5))
                          ],
                        ),
                        child: Column(
                          children: [
                            Text("انضم للقناة الآن",
                                style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.futuristicWhite)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.telegram,
                                    color: AppTheme.futuristicWhite, size: 16),
                                const SizedBox(width: 5),
                                Text("@od7ss",
                                    style: GoogleFonts.tajawal(
                                        color: AppTheme.futuristicWhite,
                                        fontSize: 14,
                                        letterSpacing: 1)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        await PreferencesService().setTelegramSubscribed();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text("تخطي، أنا مشترك بالفعل",
                          style: GoogleFonts.tajawal(
                              color: Colors.white38, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  SCREENS & ROUTING
// =============================================================================

class HamidApp extends StatelessWidget {
  const HamidApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'أكاديمية حميد✨',
          theme: AppTheme.theme,
          initialRoute: '/',
          routes: {
            '/': (context) => const IntroScreen(),
            '/home': (context) => const HomeScreen(),
          });
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.school_rounded,
            size: 100, color: AppTheme.futuristicWhite),
        const SizedBox(height: 20),
        Text("أكاديمية حميد",
            style: GoogleFonts.tajawal(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: AppTheme.futuristicWhite)),
      ])),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTelegramSubscription();
    });
  }

  void _checkTelegramSubscription() {
    if (PreferencesService().canShowTelegramDialog()) {
      showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          builder: (context) => const TelegramDialog());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("اختار الدفعة وبلش بكل حماسك ✨ "),
        actions: [
          ValueListenableBuilder(
            valueListenable: DownloadManager().activeDownloads,
            builder: (context, active, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.download_rounded,
                        size: 28, color: AppTheme.futuristicWhite),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DownloadsScreen())),
                  ),
                  if (active.isNotEmpty)
                    Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                color: AppTheme.error,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: AppTheme.bg, width: 2))))
                ],
              );
            },
          ),
          const SizedBox(width: 10),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(30),
              border:
                  Border.all(color: AppTheme.futuristicWhite.withOpacity(0.05)),
            ),
            child: TabBar(
              controller: _tab,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: AppTheme.primary.withOpacity(0.8),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.primary.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1)
                  ]),
              labelColor: AppTheme.futuristicWhite,
              unselectedLabelColor: Colors.white54,
              labelStyle: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold, fontSize: 16),
              tabs: const [
                Tab(child: Center(child: Text("دفعة 2026"))),
                Tab(child: Center(child: Text("دفعة 2025")))
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          ValueListenableBuilder<Map<String, dynamic>?>(
            valueListenable: PreferencesService().lastWatchedLecture,
            builder: (context, lastData, _) {
              if (lastData == null) return const SizedBox.shrink();

              double progress = 0;
              if (lastData['duration'] != null && lastData['duration'] > 0) {
                progress = lastData['position'] / lastData['duration'];
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PlayerContainer(
                                  url: lastData['url'],
                                  title: lastData['title'],
                                )));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded,
                                color: AppTheme.accent),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "متابعة المشاهدة",
                                  style: GoogleFonts.tajawal(
                                    fontSize: 12,
                                    color: Colors.white54,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lastData['title'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.futuristicWhite,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.black26,
                                    valueColor: const AlwaysStoppedAnimation(
                                        AppTheme.primary),
                                    minHeight: 4,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: TabBarView(controller: _tab, children: const [
              GridContent(url: "https://edson.my/mm.json"),
              GridContent(url: "https://edson.my/ss.json")
            ]),
          ),
        ],
      ),
    );
  }
}

class GridContent extends StatelessWidget {
  final String url;
  const GridContent({super.key, required this.url});

  Future<List<dynamic>> _getData() async {
    try {
      final r = await http.get(Uri.parse(url));
      if (r.statusCode == 200) {
        String b = utf8.decode(r.bodyBytes);
        if (!b.trim().startsWith("{")) {
          b = utf8.decode(base64.decode(b.replaceAll(RegExp(r'\s+'), '')));
        }
        final d = json.decode(b);
        return d is Map ? d['teachers'] : d;
      }
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _getData(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.futuristicWhite));
        }

        return ValueListenableBuilder<List<String>>(
          valueListenable: PreferencesService().favoriteTeachers,
          builder: (context, favorites, _) {
            List<dynamic> sortedList = List.from(snap.data!);
            sortedList.sort((a, b) {
              bool isAFav = favorites.contains(a['name']);
              bool isBFav = favorites.contains(b['name']);
              if (isAFav && !isBFav) return -1;
              if (!isAFav && isBFav) return 1;
              return 0;
            });

            return GridView.builder(
              cacheExtent: 1500,
              padding: const EdgeInsets.only(
                  top: 15, left: 16, right: 16, bottom: 30),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
              ),
              itemCount: sortedList.length,
              itemBuilder: (context, i) {
                final t = sortedList[i];
                final isFav = favorites.contains(t['name']);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    splashColor: AppTheme.primary.withOpacity(0.3),
                    highlightColor: Colors.transparent,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DetailsScreen(data: t))),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: AppTheme.futuristicWhite.withOpacity(0.08),
                            width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24)),
                                  child: CachedNetworkImage(
                                    imageUrl: t['image'] ?? "",
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    memCacheWidth: 300,
                                    alignment: Alignment.topCenter,
                                    placeholder: (context, url) =>
                                        Container(color: AppTheme.surfaceLight),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 50,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                      colors: [
                                        AppTheme.surface,
                                        Colors.transparent
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    )),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      PreferencesService()
                                          .toggleFavorite(t['name']);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppTheme.futuristicWhite
                                                  .withOpacity(0.1))),
                                      child: Icon(
                                          isFav
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isFav
                                              ? AppTheme.gold
                                              : AppTheme.futuristicWhite,
                                          size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    t['name'] ?? "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.tajawal(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppTheme.futuristicWhite),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color:
                                            AppTheme.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: AppTheme.primary
                                                .withOpacity(0.3))),
                                    child: Text(
                                      t['subject'] ?? "",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          color: AppTheme.accent,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class DetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const DetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final list = data['classes'] ?? [];
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            iconTheme: const IconThemeData(color: AppTheme.futuristicWhite),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(bottom: 16, right: 16, left: 16),
              title: Text(data['name'],
                  style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.futuristicWhite,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 10)
                      ])),
              background: CachedNetworkImage(
                  imageUrl: data['image'] ?? "",
                  fit: BoxFit.cover,
                  memCacheWidth: 600,
                  alignment: Alignment.topCenter,
                  color: Colors.black.withOpacity(0.5),
                  colorBlendMode: BlendMode.darken),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final ch = list[i];
                final chapterName = ch['name'] ?? "فصل $i";
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: AppTheme.surface,
                      child: ExpansionTile(
                        iconColor: AppTheme.primary,
                        collapsedIconColor: Colors.white54,
                        title: Text(ch['name'] ?? "",
                            style: GoogleFonts.tajawal(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: AppTheme.futuristicWhite)),
                        children: [
                          for (var lec in (ch['lectures'] ?? []))
                            Builder(builder: (context) {
                              final title = lec['title'] ?? "";
                              final uniqueId = "${chapterName}_$title";
                              return Container(
                                decoration: BoxDecoration(
                                    border: Border(
                                        top: BorderSide(
                                            color: AppTheme.futuristicWhite
                                                .withOpacity(0.05)))),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: const Icon(Icons.play_circle_fill,
                                      color: AppTheme.accent, size: 32),
                                  title: Text(title,
                                      style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  trailing:
                                      CompletionButton(lectureId: uniqueId),
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => PlayerContainer(
                                              url: lec['url'], title: title))),
                                ),
                              );
                            })
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: list.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50))
        ],
      ),
    );
  }
}

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    DownloadManager().refreshFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("المكتبة والتحميلات")),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<Map<String, Map<String, dynamic>>>(
              valueListenable: DownloadManager().activeDownloads,
              builder: (context, activeDownloads, _) {
                if (activeDownloads.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("جاري التحميل...",
                          style: GoogleFonts.tajawal(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accent)),
                      const SizedBox(height: 10),
                      ...activeDownloads.entries.map((e) {
                        final data = e.value;
                        final progress = data['progress'] as double;
                        final received =
                            (data['received'] as int) / (1024 * 1024);
                        final total = (data['total'] as int) / (1024 * 1024);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: AppTheme.surface,
                              border: Border.all(
                                  color: AppTheme.futuristicWhite
                                      .withOpacity(0.05)),
                              borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.tajawal(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.futuristicWhite)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      "${received.toStringAsFixed(1)} MB / ${total > 0 ? total.toStringAsFixed(1) : '...'} MB",
                                      style: GoogleFonts.cairo(
                                          fontSize: 12, color: Colors.white70)),
                                  Text(
                                      "${(progress * 100).toStringAsFixed(0)}%",
                                      style: GoogleFonts.tajawal(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: Colors.white12,
                                  valueColor: const AlwaysStoppedAnimation(
                                      AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(color: Colors.white12, height: 30),
                    ],
                  ),
                );
              },
            ),
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: DownloadManager().savedFiles,
              builder: (context, files, _) {
                if (files.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.video_library_outlined,
                                size: 80, color: Colors.white10),
                            const SizedBox(height: 15),
                            Text("لا توجد ملفات محفوظة بعد",
                                style: GoogleFonts.cairo(
                                    color: Colors.white54, fontSize: 16))
                          ]),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("الفيديوهات المحفوظة",
                          style: GoogleFonts.tajawal(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.futuristicWhite)),
                      const SizedBox(height: 10),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: files.length,
                        itemBuilder: (context, i) {
                          final file = files[i];
                          return Dismissible(
                            key: Key(file['path']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                decoration: BoxDecoration(
                                    color: AppTheme.error,
                                    borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.delete,
                                    color: Colors.white)),
                            onDismissed: (_) =>
                                DownloadManager().deleteFile(file['path']),
                            child: Card(
                              color: AppTheme.surface,
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      color: AppTheme.futuristicWhite
                                          .withOpacity(0.05)),
                                  borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                leading: const Icon(Icons.play_circle_outline,
                                    color: AppTheme.primary, size: 36),
                                title: Text(file['name'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.tajawal(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.futuristicWhite,
                                        fontSize: 14)),
                                subtitle: Text("${file['size']} MB",
                                    style: GoogleFonts.cairo(
                                        fontSize: 12, color: AppTheme.accent)),
                                trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.white30),
                                    onPressed: () => DownloadManager()
                                        .deleteFile(file['path'])),
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => PlayerContainer(
                                            url: file['path'],
                                            title: file['name'],
                                            isLocal: true))),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 🔥 هنا صار التعديل الخرافي اللي طلبته يا بطل
class PlayerContainer extends StatefulWidget {
  final String url;
  final String title;
  final bool isLocal;
  const PlayerContainer(
      {super.key,
      required this.url,
      required this.title,
      this.isLocal = false});
  @override
  State<PlayerContainer> createState() => _PlayerContainerState();
}

class _PlayerContainerState extends State<PlayerContainer> {
  WebViewController? _webController;
  final TextEditingController _noteController =
      TextEditingController(); // كنترولر الملاحظات

  bool get useWebView {
    if (widget.isLocal) return false;
    if (widget.url.startsWith("https://9bf9f797be0a4677a8-akamai-cdn.com") ||
        widget.url.startsWith("https://vidcdn.akamai-cdn-delivery.com/cdn/")) {
      return false;
    }
    if (widget.url.endsWith(".mp4")) return false;
    if (widget.url.contains("iframe") ||
        widget.url.contains("embed") ||
        widget.url.contains("vz-")) {
      return true;
    }
    return false;
  }

  final List<String> verses = [
    "وَأَن لَّيْسَ لِلْإِنسَانِ إِلَّا مَا سَعَىٰ",
    "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا",
    "وَقُل رَّبِّ زِدْنِي عِلْمًا",
    "وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ",
    "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
    "وَاصْبِرْ لِحُكْمِ رَبِّكَ فَإِنَّكَ بِأَعْيُنِنَا"
  ];
  String currentVerse = "";

  @override
  void initState() {
    super.initState();
    currentVerse = verses[Random().nextInt(verses.length)];

    if (useWebView) {
      PreferencesService().saveVideoProgress(
          widget.url, widget.title, Duration.zero, Duration.zero);
    }

    // 🔥 جلب الملاحظة الخاصة بهذي المحاضرة أول ما يفتح الصفحة
    _noteController.text = PreferencesService().getNoteForLecture(widget.url);
  }

  @override
  void dispose() {
    _noteController.dispose(); // تنظيف الذاكرة يا مبرمجنا
    super.dispose();
  }

  // 🔥 دالة حفظ الملاحظة
  void _saveNote() {
    FocusScope.of(context).unfocus(); // إخفاء الكيبورد بعد الحفظ
    PreferencesService().saveNoteForLecture(widget.url, _noteController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text("تم حفظ الملاحظة بنجاح يا بطل 🚀",
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.black,
              width: double.infinity,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(
                  child: useWebView
                      ? Stack(
                          children: [
                            WebViewPlayer(
                              url: widget.url,
                              onControllerCreated: (ctrl) {
                                setState(() {
                                  _webController = ctrl;
                                });
                              },
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: IconButton(
                                icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            if (!widget.isLocal)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: SmartDownloadButton(
                                  title: widget.title,
                                  iframeUrl: widget.url,
                                ),
                              ),
                          ],
                        )
                      : CustomVideoPlayer(
                          url: widget.url,
                          title: widget.title,
                          isLocal: widget.isLocal,
                          headers: getPythonHeaders()),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppTheme.bg,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: GoogleFonts.tajawal(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.futuristicWhite)),
                      const SizedBox(height: 25),

                      // 🌟 التصميم الفخم الجديد للآية القرآنية (Glassmorphism Effect)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 25),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary.withOpacity(0.15),
                                AppTheme.surfaceLight.withOpacity(0.4),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.primary.withOpacity(0.3),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.05),
                                blurRadius: 20,
                                spreadRadius: 2,
                              )
                            ]),
                        child: Column(
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                color: AppTheme.gold.withOpacity(0.8),
                                size: 28),
                            const SizedBox(height: 15),
                            Text(currentVerse,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.amiri(
                                    fontSize: 24,
                                    height: 1.7,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.futuristicWhite,
                                    shadows: [
                                      Shadow(
                                        color:
                                            AppTheme.primary.withOpacity(0.5),
                                        blurRadius: 10,
                                      )
                                    ])),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 📝 قسم الملاحظات الاحترافي
                      Row(
                        children: [
                          const Icon(Icons.edit_note_rounded,
                              color: AppTheme.accent, size: 26),
                          const SizedBox(width: 8),
                          Text("ملاحظات المحاضرة",
                              style: GoogleFonts.tajawal(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.futuristicWhite)),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // حقل إدخال الملاحظات
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: TextField(
                          controller: _noteController,
                          maxLines: 5,
                          minLines: 3,
                          style: GoogleFonts.cairo(
                              color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText:
                                "اكتب ملاحظاتك المهمة هنا وتذكرها دائماً...",
                            hintStyle: GoogleFonts.cairo(
                                color: Colors.white38, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // زر الحفظ بلمسة احترافية
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveNote,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            shadowColor: AppTheme.primary.withOpacity(0.5),
                          ),
                          child: Text("حفظ الملاحظة",
                              style: GoogleFonts.tajawal(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class WebViewPlayer extends StatefulWidget {
  final String url;
  final Function(WebViewController) onControllerCreated;

  const WebViewPlayer(
      {super.key, required this.url, required this.onControllerCreated});
  @override
  State<WebViewPlayer> createState() => _WebViewPlayerState();
}

class _WebViewPlayerState extends State<WebViewPlayer> {
  late WebViewController _ctrl;

  @override
  void initState() {
    super.initState();
    final headers = getPythonHeaders();
    final String htmlContent =
        """<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"><style>body{margin:0;padding:0;background:black;display:flex;justify-content:center;align-items:center;height:100vh;width:100vw;overflow:hidden}iframe{width:100%;height:100%;border:none}</style></head><body><iframe src="${widget.url}" allow="autoplay; fullscreen; picture-in-picture" allowfullscreen></iframe></body></html>""";
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);

    if (widget.url.contains("iframe") || widget.url.contains("vz-")) {
      _ctrl.loadHtmlString(htmlContent,
          baseUrl:
              headers.isNotEmpty ? "https://iframe.mediadelivery.net/" : null);
    } else {
      _ctrl.loadRequest(Uri.parse(widget.url), headers: headers);
    }
    widget.onControllerCreated(_ctrl);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _ctrl);
  }
}

class CustomVideoPlayer extends StatefulWidget {
  final String url;
  final String title;
  final bool isLocal;
  final Map<String, String> headers;

  const CustomVideoPlayer(
      {super.key,
      required this.url,
      required this.title,
      this.isLocal = false,
      this.headers = const {}});

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _vc;
  bool _ready = false;
  bool _controlsVisible = true;
  double _playbackSpeed = 1.0;
  Timer? _hideTimer;
  int _lastSavedSecond = 0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    Map<String, String> finalHeaders = widget.headers;
    if (widget.url.contains("akamai-cdn")) {
      finalHeaders = {};
    }

    _vc = widget.isLocal
        ? VideoPlayerController.file(File(widget.url))
        : VideoPlayerController.network(widget.url, httpHeaders: finalHeaders);

    _vc.addListener(_videoListener);

    _vc.initialize().then((_) {
      if (mounted) {
        int savedPos = PreferencesService().getVideoPosition(widget.url);
        if (savedPos > 0 && savedPos < _vc.value.duration.inSeconds) {
          _vc.seekTo(Duration(seconds: savedPos));
        }

        _vc.play();
        setState(() => _ready = true);
        _startHideTimer();
      }
    });
  }

  void _videoListener() {
    if (mounted) setState(() {});

    if (_vc.value.isPlaying && !widget.isLocal) {
      int currentSecond = _vc.value.position.inSeconds;
      if ((currentSecond - _lastSavedSecond).abs() >= 5) {
        _lastSavedSecond = currentSecond;
        PreferencesService().saveVideoProgress(
            widget.url, widget.title, _vc.value.position, _vc.value.duration);
      }
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _vc.removeListener(_videoListener);

    if (!widget.isLocal && _ready) {
      PreferencesService().saveVideoProgress(
          widget.url, widget.title, _vc.value.position, _vc.value.duration);
    }

    _vc.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _vc.value.isPlaying) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _startHideTimer();
  }

  void _changeSpeed(double speed) {
    _vc.setPlaybackSpeed(speed);
    setState(() => _playbackSpeed = speed);
    _startHideTimer();
  }

  void _goFullScreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenVideoPage(
          controller: _vc,
          initialSpeed: _playbackSpeed,
          url: widget.url,
          title: widget.title,
          isLocal: widget.isLocal,
        ),
      ),
    );

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    setState(() {
      _playbackSpeed = _vc.value.playbackSpeed;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _vc.value.size.width,
                height: _vc.value.size.height,
                child: VideoPlayer(_vc),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _controlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                      Colors.black87
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      left: 10,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: PopupMenuButton<double>(
                        initialValue: _playbackSpeed,
                        tooltip: "السرعة",
                        color: AppTheme.surface,
                        icon: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text("${_playbackSpeed}x",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        onSelected: _changeSpeed,
                        itemBuilder: (context) =>
                            [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 3.5]
                                .map((speed) => PopupMenuItem(
                                      value: speed,
                                      child: Text("${speed}x",
                                          style: GoogleFonts.tajawal(
                                              color: Colors.white)),
                                    ))
                                .toList(),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen_rounded,
                            color: Colors.white, size: 30),
                        onPressed: _goFullScreen,
                      ),
                    ),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.replay_10_rounded,
                                  color: Colors.white, size: 40),
                              onPressed: () {
                                _vc.seekTo(_vc.value.position -
                                    const Duration(seconds: 10));
                                _startHideTimer();
                              }),
                          GestureDetector(
                            onTap: () {
                              setState(() => _vc.value.isPlaying
                                  ? _vc.pause()
                                  : _vc.play());
                              _startHideTimer();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54),
                              child: Icon(
                                _vc.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                          IconButton(
                              icon: const Icon(Icons.forward_10_rounded,
                                  color: Colors.white, size: 40),
                              onPressed: () {
                                _vc.seekTo(_vc.value.position +
                                    const Duration(seconds: 10));
                                _startHideTimer();
                              }),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 15,
                      right: 15,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(formatDuration(_vc.value.position),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12)),
                              Text(formatDuration(_vc.value.duration),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          BufferedProgressBar(controller: _vc),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class BufferedProgressBar extends StatelessWidget {
  final VideoPlayerController controller;
  const BufferedProgressBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return VideoProgressIndicator(
      controller,
      allowScrubbing: true,
      colors: const VideoProgressColors(
        playedColor: AppTheme.primary,
        bufferedColor: Colors.white24,
        backgroundColor: Colors.white12,
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
    );
  }
}

class FullScreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;
  final double initialSpeed;
  final String url;
  final String title;
  final bool isLocal;

  const FullScreenVideoPage(
      {super.key,
      required this.controller,
      required this.initialSpeed,
      required this.url,
      required this.title,
      required this.isLocal});
  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  bool _controlsVisible = true;
  Timer? _hideTimer;
  late double _currentSpeed;
  int _lastSavedSecond = 0;

  @override
  void initState() {
    super.initState();
    _currentSpeed = widget.initialSpeed;
    _startHideTimer();
    widget.controller.addListener(_updateState);
    WakelockPlus.enable();
  }

  void _updateState() {
    if (mounted) setState(() {});

    if (widget.controller.value.isPlaying && !widget.isLocal) {
      int currentSecond = widget.controller.value.position.inSeconds;
      if ((currentSecond - _lastSavedSecond).abs() >= 5) {
        _lastSavedSecond = currentSecond;
        PreferencesService().saveVideoProgress(widget.url, widget.title,
            widget.controller.value.position, widget.controller.value.duration);
      }
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _startHideTimer();
  }

  void _changeSpeed(double speed) {
    widget.controller.setPlaybackSpeed(speed);
    setState(() => _currentSpeed = speed);
    _startHideTimer();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: vc.value.size.width,
                    height: vc.value.size.height,
                    child: VideoPlayer(vc),
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black87,
                          Colors.transparent,
                          Colors.black87
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 20,
                          right: 30,
                          child: IconButton(
                            icon: const Icon(Icons.fullscreen_exit_rounded,
                                color: Colors.white, size: 35),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          left: 30,
                          child: PopupMenuButton<double>(
                            initialValue: _currentSpeed,
                            tooltip: "السرعة",
                            color: AppTheme.surface,
                            icon: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text("${_currentSpeed}x",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                            onSelected: _changeSpeed,
                            itemBuilder: (context) =>
                                [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 3.0, 3.5]
                                    .map((speed) => PopupMenuItem(
                                          value: speed,
                                          child: Text("${speed}x",
                                              style: GoogleFonts.tajawal(
                                                  color: Colors.white)),
                                        ))
                                    .toList(),
                          ),
                        ),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_10_rounded,
                                    color: Color(0xffd23232), size: 60),
                                onPressed: () {
                                  vc.seekTo(vc.value.position -
                                      const Duration(seconds: 10));
                                  _startHideTimer();
                                },
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() => vc.value.isPlaying
                                      ? vc.pause()
                                      : vc.play());
                                  _startHideTimer();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black54),
                                  child: Icon(
                                    vc.value.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 70,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.forward_10_rounded,
                                    color: Colors.white, size: 60),
                                onPressed: () {
                                  vc.seekTo(vc.value.position +
                                      const Duration(seconds: 10));
                                  _startHideTimer();
                                },
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 40,
                          right: 40,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(formatDuration(vc.value.position),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14)),
                                  Text(formatDuration(vc.value.duration),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              BufferedProgressBar(controller: vc),
                            ],
                          ),
                        )
                      ],
                    ),
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
