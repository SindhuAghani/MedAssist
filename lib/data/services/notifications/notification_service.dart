import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../../routes/routes.dart';
import '../../../utils/popups/loaders.dart';
import 'notification_model.dart';

// Top-level function to handle background notifications
@pragma('vm:entry-point') // Ensures the function can be accessed in the background
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // await Firebase.initializeApp();
  // // Handle your background message here
  // NotificationService()._showLocalNotification(message);
  // TLoaders.customToast(message: 'Background Handler');
}

class TNotificationService extends GetxService {
  static TNotificationService get instance => Get.find();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final List<NotificationModel> notifications = [];

  @override
  void onInit() {
    super.onInit();
    initializeNotifications();
  }

  initializeNotifications() async {
    await requestPermission();
    await _initializeLocalNotifications();
    _setupFirebaseListeners();
    await _syncFcmToken();
  }

  /// -- Request Permission on App Launch
  Future<void> requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      TLoaders.warningSnackBar(title: 'No Permission', message: "Notification permissions denied.");
      //TCrashlyticsHelper.recordError('Notification permissions denied');
    } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      TLoaders.warningSnackBar(title: 'No Permission', message: "Notification permissions not determined.");
      //TCrashlyticsHelper.recordError('Notification permissions not determined');
    } else {
      if (kDebugMode) print("Notification permissions granted.");
      //TCrashlyticsHelper.logSuccess('Notification permissions granted.');
    }
  }

  /// -- Get User's FCMToken
  static Future<String> getToken() async {
    await Future.delayed(const Duration(milliseconds: 5000)); // Optional delay
    final token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) print('FCM Token: $token');
    return token ?? '';
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'medication_reminders',
            'Medication reminders',
            description: 'Dose reminders and caregiver alerts',
            importance: Importance.max,
          ),
        );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );
  }


  void _setupFirebaseListeners() {
    FirebaseMessaging.onMessage.listen(_onMessageReceived);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpenedApp);
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenForCurrentUser);
    // Use the top-level background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _syncFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await _saveTokenForCurrentUser(token);
    }
  }

  Future<void> _saveTokenForCurrentUser(String token) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) return;

      await FirebaseFirestore.instance.collection('Users').doc(userId).set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print('Failed to save FCM token: $e');
    }
  }

  void _onMessageReceived(RemoteMessage message) async {
    _showLocalNotification(message);
  }

  void _onNotificationOpenedApp(RemoteMessage message) {
    _handleNotificationRedirect(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // if (_receivedMessageIds.contains(message.messageId)) return; // Skip duplicate notification
    // _receivedMessageIds.add(message.messageId ?? '');

    final String? route = message.data['route'];
    final String? parameter = message.data['id'];

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'medication_reminders', 'Medication reminders',
        importance: Importance.max, priority: Priority.high, ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: '$route?id=$parameter', // Route passed as payload
    );
  }

  void addNotification(RemoteMessage message, {String? route, String? routeId}) {
    final notification = NotificationModel(
      id: message.messageId ?? '',
      title: message.notification?.title ?? 'No Title',
      body: message.notification?.body ?? 'No Body',
      route: route ?? '',
      routeId: routeId ?? '',
      createdAt: DateTime.now(),
      seenBy: {},
      isBroadcast: false,
      type: '',
      recipientIds: [],
      senderId: '',
    );

    notifications.add(notification);
  }

  Future<void> _onSelectNotification(NotificationResponse notificationResponse) async {
    if (notificationResponse.payload != null && notificationResponse.payload!.isNotEmpty) {
      final uri = Uri.tryParse(notificationResponse.payload!);
      if (uri != null) {
        Get.toNamed(uri.path, parameters: uri.queryParameters);
      } else {
        Get.toNamed(notificationResponse.payload!);
      }
    }
  }

  Future<void> _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) async {
    if (payload != null) {
      Get.toNamed(payload);
    }
  }

  Future<void> handleInitialMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleNotificationRedirect(initialMessage);
    // Get.toNamed(TRoutes.notification);
  }

  void _handleNotificationRedirect(RemoteMessage message) {
    final String? route = message.data['route'];
    final String? parameter = message.data['id'];
    final String? parameters = message.data['parameter'];

    if (route != null) {
      Get.toNamed(route, parameters: {'id': parameter ?? ''});
    } else {
      Get.toNamed(TRoutes.notification);
    }
  }
}
