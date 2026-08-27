import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

// import 'auth_manager.dart';

class NotificationService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';

  Future<NotificationService> init() async {
    log("In notification service");
    await _initializeLocalNotifications();
    await _requestPermissions();
    _listenToMessages();
    return this;
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        log('Notification clicked: ${response.payload}');
        // Get.toNamed('/notifications');
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.max,
    );

    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      log('User granted provisional permission');
    } else {
      log('User declined or has not accepted permission');
    }
  }

  void _listenToMessages() {
    try {
      _messaging.onTokenRefresh.listen(
            (newToken) async {
          try {
            log('FCM Token refreshed: $newToken');
            // await _syncTokenToBackend(newToken);
          } catch (e, stackTrace) {
            log('Error syncing token: $e');
            log(stackTrace.toString());
          }
        },
        onError: (error) {
          log('Token refresh listener error: $error');
        },
      );

      // Foreground messages
      FirebaseMessaging.onMessage.listen(
            (RemoteMessage message) async {
          try {
            log('Got a message whilst in the foreground!');
            log('Message data: ${message.data}');

            if (message.notification != null) {
              log('Notification payload: ${message.notification}');
              await _showLocalNotification(message);   // add await
            }
          } catch (e, stackTrace) {
            log('Error handling foreground message: $e');
            log(stackTrace.toString());
          }
        },
        onError: (error) {
          log('Foreground message listener error: $error');
        },
      );

      // Notification tapped, app was in background
      FirebaseMessaging.onMessageOpenedApp.listen(
            (RemoteMessage message) {
          try {
            log('A new onMessageOpenedApp event was published!');
            Get.toNamed('/notifications');
          } catch (e, stackTrace) {
            log('Error handling onMessageOpenedApp: $e');
            log(stackTrace.toString());
          }
        },
        onError: (error) {
          log('onMessageOpenedApp listener error: $error');
        },
      );

      // App opened from terminated state via notification tap
      _messaging.getInitialMessage().then((RemoteMessage? message) {
        try {
          if (message != null) {
            log('App opened from terminated state via notification');
            Get.toNamed('/notifications');
          }
        } catch (e, stackTrace) {
          log('Error handling initial message: $e');
          log(stackTrace.toString());
        }
      }).catchError((error) {
        log('getInitialMessage error: $error');
      });
    } catch (e, stackTrace) {
      log('Error in _listenToMessages: $e');
      log(stackTrace.toString());
    }
  }

  // Future<void> _syncTokenToBackend(String token) async {
  //   try {
  //     final isLoggedIn = await Get.find<AuthManager>().isLoggedIn();
  //     if (isLoggedIn) {
  //       final userIdStr = await Get.find<AuthManager>().getUserId();
  //       if (userIdStr != null && userIdStr.isNotEmpty) {
  //         final userId = int.tryParse(userIdStr);
  //         if (userId != null) {
  //           log('Syncing new FCM token to backend for user $userId');
  //           final Map<String, dynamic> updateData = {
  //             'device_token': token,
  //             'fcm_token': token,
  //           };
  //           // TODO: hook this into your actual profile/token-sync API
  //           // await Get.find<UserProfileService>().updateUserProfile(userId: userId, userData: updateData);
  //         }
  //       }
  //     }
  //   } catch (e) {
  //     log('Error syncing token to backend: $e');
  //   }
  // }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    final AndroidNotification? android = message.notification?.android;

    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.high,
          icon: android?.smallIcon,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  Future<String?> getFcmToken() async {
    try {
      String? token = await _messaging.getToken();
      log('FCM Token: $token');
      return token;
    } catch (e) {
      log('Error getting FCM token: $e');
      return null;
    }
  }
}