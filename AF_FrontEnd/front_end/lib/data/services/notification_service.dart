import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Initialize the notification system
  Future<void> init() async {
    try {
      // 1. Request Permission from user
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (kDebugMode) {
        print('[NOTIFICATION] Authorization status: ${settings.authorizationStatus}');
      }

      // 2. Setup Local Notifications (to show pop-ups while the app is OPEN)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      
      // 3. Setup Android Channel (Simplified for v17+)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'ascent_high_importance_channel', 
        'High Importance Notifications',
        description: 'This channel is used for important system alerts.',
        importance: Importance.high,
        playSound: true,
      );

      // 4. Initialize Local Notifications
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          if (kDebugMode) {
            print('[NOTIFICATION] User clicked notification: ${details.payload}');
          }
        },
      );

      // 5. Create the channel for Android
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 4. Handle Foreground Messages (App is OPEN)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('[NOTIFICATION] Received foreground message: ${message.notification?.title}');
        }
        _showLocalNotification(message, channel);
      });

      // 5. Initial Token Fetch and Sync
      String? token = await _fcm.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('[NOTIFICATION] FCM Token: $token');
        }
        await syncToken(token);
      }

      // 6. Token Refresh Listener
      _fcm.onTokenRefresh.listen((newToken) {
        syncToken(newToken);
      });

    } catch (e) {
      if (kDebugMode) {
        print('[NOTIFICATION] Initialization Error: $e');
      }
    }
  }

  /// Sync the FCM token with the backend server
  Future<void> syncToken(String token) async {
    try {
      // Only sync if the user is authenticated
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        await _apiService.post('/auth/fcm-token', data: {'fcm_token': token});
        if (kDebugMode) {
          print('[NOTIFICATION] Token successfully synced with backend.');
        }
      } else {
         if (kDebugMode) {
          print('[NOTIFICATION] User not logged in. Token sync skipped.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[NOTIFICATION] Failed to sync token with backend: $e');
      }
    }
  }

  /// Show a local notification pop-up
  void _showLocalNotification(RemoteMessage message, AndroidNotificationChannel channel) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          ),
        ),
      );
    }
  }

  /// Subscribe to a specific group topic
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    if (kDebugMode) {
      print('[NOTIFICATION] Subscribed to topic: $topic');
    }
  }

  /// Unsubscribe from a specific group topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    if (kDebugMode) {
      print('[NOTIFICATION] Unsubscribed from topic: $topic');
    }
  }
}
