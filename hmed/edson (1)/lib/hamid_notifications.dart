// ignore_for_file: avoid_print
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// =============================================================================
// دالة الخلفية (يجب أن تكون خارج الـ Class وحاصلة على علامة entry-point)
// تعمل عندما يكون التطبيق مغلقاً (Terminated) أو في الخلفية (Background)
// =============================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // تهيئة الفايربيس في الخلفية
  await Firebase.initializeApp();
  print("🔥 إشعار في الخلفية تم استلامه: ${message.messageId}");
  // هنا يمكنك إضافة كود لحفظ بيانات الإشعار في SharedPreferences إذا أردت
}

class HamidNotifications {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // قناة إشعارات الأندرويد (ضرورية للأندرويد 8 وما فوق لإظهار الإشعار بصوت وأهمية عالية)
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel', // معرف القناة (يجب أن يكون فريداً)
    'إشعارات حميد أكاديمي', // اسم القناة (يظهر للمستخدم في إعدادات الجهاز)
    description: 'هذه القناة مخصصة للإشعارات المهمة والتنبيهات.',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> initNotifications() async {
    // 1. طلب الصلاحيات (ضروري جداً لـ iOS وأندرويد 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('✅ حالة الصلاحية: ${settings.authorizationStatus}');

    // 2. إعداد الـ Local Notifications (لإظهار الإشعارات والتطبيق مفتوح)
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // إذا كان عندك iOS، يمكنك إضافة إعداداته هنا
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInitSettings);

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // هنا تضع الكود الذي يتم تنفيذه عند الضغط على الإشعار والتطبيق مفتوح
        print("👆 تم الضغط على الإشعار: ${response.payload}");
      },
    );

    // 3. إنشاء قناة الأندرويد للإشعارات عالية الأهمية
    final androidImplementation =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_androidChannel);
    }

    // 4. الحصول على التوكن (Token)
    // يفيدك إذا أردت إرسال إشعار لطالب معين من لوحة التحكم (Backend)
    try {
      String? token = await _firebaseMessaging.getToken();
      print("📲 التوكن الخاص بهذا الجهاز: $token");
      // في التطبيقات الحقيقية، هنا تقوم بإرسال التوكن إلى قاعدة البيانات الخاصة بك
    } catch (e) {
      print("⚠️ خطأ في جلب التوكن: $e");
    }

    // 5. ربط دالة الخلفية (Background)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 6. الاستماع للإشعارات عندما يكون التطبيق مفتوحاً (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 وصل إشعار والتطبيق مفتوح!');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // التأكد من أن الإشعار يحتوي على بيانات وأنه على جهاز أندرويد
      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: _androidChannel.importance,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: message.data.toString(), // البيانات الإضافية مع الإشعار
        );
      }
    });

    // 7. الاستماع لحدث "الضغط على الإشعار" والتطبيق في الخلفية (Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🚀 تم فتح التطبيق من إشعار في الخلفية!');
      // يمكنك قراءة message.data لتوجيه المستخدم لشاشة معينة
      // مثلاً: if (message.data['type'] == 'video') { Navigator.push(...) }
    });

    // 8. الاستماع لحدث "الضغط على الإشعار" والتطبيق كان مغلقاً تماماً (Terminated)
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('💥 تم فتح التطبيق من إشعار وكان التطبيق مغلقاً تماماً!');
      // تعامل مع الـ initialMessage.data لتوجيه المستخدم
    }
  }
}
