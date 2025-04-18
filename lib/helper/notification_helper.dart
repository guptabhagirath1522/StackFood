import 'dart:convert';
import 'dart:io';
import 'package:stackfood_multivendor/common/widgets/demo_reset_dialog_widget.dart';
import 'package:stackfood_multivendor/features/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor/features/chat/controllers/chat_controller.dart';
import 'package:stackfood_multivendor/features/dashboard/screens/dashboard_screen.dart';
import 'package:stackfood_multivendor/features/notification/controllers/notification_controller.dart';
import 'package:stackfood_multivendor/features/notification/domain/models/notification_body_model.dart';
import 'package:stackfood_multivendor/features/order/controllers/order_controller.dart';
import 'package:stackfood_multivendor/features/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor/features/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor/features/wallet/controllers/wallet_controller.dart';
import 'package:stackfood_multivendor/helper/route_helper.dart';
import 'package:stackfood_multivendor/common/enums/user_type.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:stackfood_multivendor/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';

class NotificationHelper {
  static Future<void> initialize(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    // Create Android notification channels
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'stackfood',
        'StackFood Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      const AndroidNotificationChannel otpChannel = AndroidNotificationChannel(
        'otp_channel',
        'OTP Notifications',
        description: 'This channel is used for OTP verification codes.',
        importance: Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        await androidPlugin.createNotificationChannel(otpChannel);
        await androidPlugin.requestNotificationsPermission();
      }
    }

    // Initialize notification settings
    var androidInitialize =
        const AndroidInitializationSettings('notification_icon');
    var iOSInitialize = const DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    var initializationsSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSInitialize);

    // Handle notification tap
    await flutterLocalNotificationsPlugin.initialize(
      initializationsSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        try {
          if (response.payload!.isNotEmpty) {
            NotificationBodyModel payload =
                NotificationBodyModel.fromJson(jsonDecode(response.payload!));
            _handleNotificationNavigation(payload);
          }
        } catch (e) {
          debugPrint('Error handling notification tap: $e');
        }
      },
    );

    // Ensure iOS foreground notifications
    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Request Android permissions
    if (Platform.isAndroid) {
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        debugPrint('Error requesting permission: $e');
      }
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("onMessage: ${message.data}");
      _processNotification(message, flutterLocalNotificationsPlugin);
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("onOpenApp: ${message.data}");
      try {
        if (message.data.isNotEmpty) {
          NotificationBodyModel payload = convertNotification(message.data);
          _handleNotificationNavigation(payload);
        }
      } catch (e) {
        debugPrint('Error handling opened app notification: $e');
      }
    });
  }

  // Process notification based on type
  static void _processNotification(
      RemoteMessage message, FlutterLocalNotificationsPlugin fln) {
    // Extract notification data
    String? title = message.notification?.title ?? message.data['title'];
    String? body = message.notification?.body ?? message.data['body'];
    NotificationBodyModel notificationBody = convertNotification(message.data);

    // Show notification based on type
    if (message.data.containsKey('order_id') &&
        (message.data['type'] == 'order_otp' ||
            message.data.containsKey('otp'))) {
      // OTP notification
      _showNotification(
          title ?? 'Verification Code',
          body ?? 'Your verification code has arrived',
          'otp_channel',
          notificationBody,
          fln);
    } else if (message.data.containsKey('order_id') ||
        message.data['type'] == 'order_status') {
      // Order notification
      _showNotification(
          title ?? 'Order Update',
          body ?? 'Your order status has been updated',
          'stackfood',
          notificationBody,
          fln);

      // Update order data if logged in
      if (Get.find<AuthController>().isLoggedIn()) {
        Get.find<OrderController>().getRunningOrders(1);
        Get.find<OrderController>().getHistoryOrders(1);
      }
    } else {
      // General notification
      _showNotification(
          title ?? 'New Notification',
          body ?? 'You have a new notification',
          'stackfood',
          notificationBody,
          fln);
    }

    // Handle special notification types
    _processSpecialNotifications(message);
  }

  // Show notification with appropriate channel
  static Future<void> _showNotification(
      String title,
      String body,
      String channelId,
      NotificationBodyModel notificationBody,
      FlutterLocalNotificationsPlugin fln) async {
    if (GetPlatform.isAndroid) {
      AndroidNotificationDetails androidDetails;

      if (channelId == 'otp_channel') {
        androidDetails = const AndroidNotificationDetails(
          'otp_channel',
          'OTP Notifications',
          channelDescription: 'This channel is used for OTP notifications',
          importance: Importance.max,
          priority: Priority.high,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
          sound: RawResourceAndroidNotificationSound('notification'),
        );
      } else {
        androidDetails = const AndroidNotificationDetails(
          'stackfood',
          'StackFood Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
        );
      }

      final NotificationDetails details =
          NotificationDetails(android: androidDetails);
      await fln.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: jsonEncode(notificationBody.toJson()),
      );
    } else if (GetPlatform.isIOS) {
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.wav',
      );
      const NotificationDetails details = NotificationDetails(iOS: iOSDetails);
      await fln.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: jsonEncode(notificationBody.toJson()),
      );
    }
  }

  // Process special notification types
  static void _processSpecialNotifications(RemoteMessage message) {
    if (message.data['type'] == AppConstants.demoResetTopic) {
      Get.dialog(const DemoResetDialogWidget(), barrierDismissible: false);
    } else if (message.data['type'] == 'maintenance') {
      Get.find<SplashController>().getConfigData(handleMaintenanceMode: true);
    } else if (message.data['type'] == 'message') {
      _handleChatNotification(message);
    } else if (message.data['type'] == 'add_fund') {
      if (Get.find<AuthController>().isLoggedIn()) {
        Get.find<ProfileController>().getUserInfo();
        Get.find<WalletController>()
            .getWalletTransactionList('1', false, 'all');
      }
    } else if (message.data['type'] != 'maintenance' &&
        message.data['type'] != AppConstants.demoResetTopic) {
      if (Get.find<AuthController>().isLoggedIn()) {
        Get.find<NotificationController>().getNotificationList(true);
      }
    }
  }

  // Handle chat notifications
  static void _handleChatNotification(RemoteMessage message) {
    if (!Get.find<AuthController>().isLoggedIn()) return;

    if (Get.currentRoute.startsWith(RouteHelper.messages)) {
      Get.find<ChatController>().getConversationList(1, fromTab: false);
      if (Get.find<ChatController>()
              .messageModel!
              .conversation!
              .id
              .toString() ==
          message.data['conversation_id'].toString()) {
        Get.find<ChatController>().getMessages(
          1,
          NotificationBodyModel(
            notificationType: NotificationType.message,
            adminId:
                message.data['sender_type'] == UserType.admin.name ? 0 : null,
            restaurantId:
                message.data['sender_type'] == UserType.vendor.name ? 0 : null,
            deliverymanId:
                message.data['sender_type'] == UserType.delivery_man.name
                    ? 0
                    : null,
          ),
          null,
          int.parse(message.data['conversation_id'].toString()),
        );
      }
    } else if (Get.currentRoute.startsWith(RouteHelper.conversation)) {
      Get.find<ChatController>().getConversationList(1, fromTab: false);
    }
  }

  // Navigate based on notification payload
  static void _handleNotificationNavigation(NotificationBodyModel payload) {
    if (payload.notificationType == NotificationType.order) {
      if (Get.find<AuthController>().isGuestLoggedIn()) {
        Get.to(() => const DashboardScreen(pageIndex: 3, fromSplash: false));
      } else {
        Get.toNamed(RouteHelper.getOrderDetailsRoute(
            int.parse(payload.orderId.toString()),
            fromNotification: true));
      }
    } else if (payload.notificationType == NotificationType.message) {
      Get.toNamed(RouteHelper.getChatRoute(
          notificationBody: payload,
          conversationID: payload.conversationId,
          fromNotification: true));
    } else if (payload.notificationType == NotificationType.block ||
        payload.notificationType == NotificationType.unblock) {
      Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.notification));
    } else if (payload.notificationType == NotificationType.add_fund ||
        payload.notificationType == NotificationType.referral_earn ||
        payload.notificationType == NotificationType.CashBack) {
      Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true));
    } else {
      Get.toNamed(RouteHelper.getNotificationRoute(fromNotification: true));
    }
  }

  // Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // Convert notification data to model
  static NotificationBodyModel convertNotification(Map<String, dynamic> data) {
    if (data['type'] == 'order_status') {
      return NotificationBodyModel(
          notificationType: NotificationType.order,
          orderId: int.parse(data['order_id']));
    } else if (data['type'] == 'message') {
      return NotificationBodyModel(
        notificationType: NotificationType.message,
        deliverymanId: data['sender_type'] == 'delivery_man' ? 0 : null,
        adminId: data['sender_type'] == 'admin' ? 0 : null,
        restaurantId: data['sender_type'] == 'vendor' ? 0 : null,
        conversationId: data['conversation_id'] != ''
            ? int.parse(data['conversation_id'].toString())
            : 0,
      );
    } else if (data['type'] == 'referral_earn') {
      return NotificationBodyModel(
          notificationType: NotificationType.referral_earn);
    } else if (data['type'] == 'CashBack') {
      return NotificationBodyModel(notificationType: NotificationType.CashBack);
    } else if (data['type'] == 'block') {
      return NotificationBodyModel(notificationType: NotificationType.block);
    } else if (data['type'] == 'unblock') {
      return NotificationBodyModel(notificationType: NotificationType.unblock);
    } else if (data['type'] == 'add_fund') {
      return NotificationBodyModel(notificationType: NotificationType.add_fund);
    } else {
      return NotificationBodyModel(notificationType: NotificationType.general);
    }
  }
}

@pragma('vm:entry-point')
Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("onBackground: ${message.data}");

  // Initialize notification plugin for background messages
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  var androidInitialize =
      const AndroidInitializationSettings('notification_icon');
  var iOSInitialize = const DarwinInitializationSettings();
  var initializationsSettings =
      InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
  await flutterLocalNotificationsPlugin.initialize(initializationsSettings);

  try {
    // Extract notification data
    String? title = message.notification?.title ?? message.data['title'];
    String? body = message.notification?.body ?? message.data['body'];

    // Determine channel based on notification type
    String channelId = 'stackfood';
    Importance importance = Importance.high;

    if (message.data.containsKey('order_id') &&
        (message.data['type'] == 'order_otp' ||
            message.data.containsKey('otp'))) {
      channelId = 'otp_channel';
      importance = Importance.max;
      title = title ?? 'Verification Code';
      body = body ?? 'Your verification code has arrived';
    } else if (message.data.containsKey('order_id') ||
        message.data['type'] == 'order_status') {
      title = title ?? 'Order Update';
      body = body ?? 'Your order status has been updated';
    } else {
      title = title ?? 'New Notification';
      body = body ?? 'You have a new notification';
    }

    // Show notification
    if (GetPlatform.isAndroid) {
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == 'otp_channel'
            ? 'OTP Notifications'
            : 'StackFood Notifications',
        importance: importance,
        priority: Priority.high,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        visibility: NotificationVisibility.public,
        sound: const RawResourceAndroidNotificationSound('notification'),
        fullScreenIntent:
            channelId == 'otp_channel', // Full screen intent for OTP only
      );

      NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformDetails,
      );
    } else if (GetPlatform.isIOS) {
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.wav',
      );
      const NotificationDetails platformDetails =
          NotificationDetails(iOS: iOSDetails);
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformDetails,
      );
    }
  } catch (e) {
    debugPrint("Error handling background notification: $e");
  }
}
