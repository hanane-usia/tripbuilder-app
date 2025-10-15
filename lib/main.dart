import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initLocalNotifications() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
  );
  await _flutterLocalNotificationsPlugin.initialize(initSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'updates',
    'Updates',
    description: 'Trip updates and notifications',
    importance: Importance.high,
    playSound: true,
  );
  await _flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

Future<void> _initFirebaseMessaging() async {
  print('🔔 Initializing Firebase Messaging...');
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final messaging = FirebaseMessaging.instance;

  // Request permissions with more detailed options
  final permission = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );

  print('🔔 Notification permission status: ${permission.authorizationStatus}');
  print('🔔 Alert permission: ${permission.alert}');
  print('🔔 Badge permission: ${permission.badge}');
  print('🔔 Sound permission: ${permission.sound}');

  // Get and print FCM token with error handling
  try {
    final token = await messaging.getToken();
    print(
      '🔔 FCM Token: ${token != null ? token.substring(0, 20) + '...' : 'null'}',
    );

    if (token == null) {
      print(
        '❌ FCM Token is null! This will prevent notifications from working.',
      );
    }
  } catch (e) {
    print('❌ Failed to get FCM token: $e');
    print(
      '⚠️ Firebase Messaging will not work properly. This might be due to:',
    );
    print('   - Network connectivity issues');
    print('   - Google Play Services not available');
    print('   - Firebase configuration issues');
    print(
      '   - The app will continue to work, but notifications may not function.',
    );
  }

  // Listen for token refresh
  messaging.onTokenRefresh.listen((newToken) {
    print('🔔 FCM Token refreshed: ${newToken.substring(0, 20)}...');
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('🔔 Received foreground message: ${message.notification?.title}');
    print('🔔 Message data: ${message.data}');

    final notification = message.notification;
    if (notification != null) {
      print('🔔 Showing local notification...');
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'updates',
            'Updates',
            channelDescription: 'Trip updates and notifications',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            showWhen: true,
            enableVibration: true,
          ),
        ),
        payload: message.data['type'],
      );
    }
  });

  // Handle background messages
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print(
      '🔔 App opened from background message: ${message.notification?.title}',
    );
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _initLocalNotifications();
  await _initFirebaseMessaging();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          final localeProvider = Provider.of<LocaleProvider>(context);
          return MaterialApp(
            title: 'Trip Builder',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness:
                  themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
              primaryColor: const Color(0xFF7B68EE),
              scaffoldBackgroundColor: themeProvider.backgroundColor,
              cardColor: themeProvider.cardColor,
              textTheme: TextTheme(
                bodyLarge: TextStyle(color: themeProvider.textColor),
                bodyMedium: TextStyle(color: themeProvider.textColor),
                bodySmall: TextStyle(color: themeProvider.subTextColor),
              ),
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            locale: localeProvider.locale,
            routes: {
              '/dashboard': (context) => AdminDashboardScreen(),
              '/login': (context) => LoginScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
