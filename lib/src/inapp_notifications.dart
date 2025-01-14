import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_notifications/animations/inapp_notification_animation.dart';
import 'package:flutter_inapp_notifications/animations/offset_animation.dart';
import 'package:flutter_inapp_notifications/animations/opacity_animation.dart';
import 'package:flutter_inapp_notifications/animations/scale_animation.dart';
import 'package:indexed/indexed.dart';

import 'inapp_notifications_container.dart';
import 'inapp_notifications_overlay.dart';
import 'inapp_notifications_overlay_entry.dart';

/// Status for In-App Notification callbacks.
///
/// [show] when the status is currently showing.
/// [dismiss] when the status is dismissed.
enum InAppNotificationsStatus {
  show,
  dismiss,
}

/// Animation style used to show/hide In-App notification.
///
/// [opacity] uses [OpacityAnimation]
/// [offset] uses [OffsetAnimation]
/// [scale] uses [ScaleAnimation]
/// [custom] uses a custom [InAppNotificationAnimation] set to customAnimation value
enum InAppNotificationsAnimationStyle {
  opacity,
  offset,
  scale,
  custom,
}

typedef InAppNotificationsStatusCallback = void Function(
    InAppNotificationsStatus status);

class InAppNotifications {
  static final InAppNotifications _instance = InAppNotifications._internal();

  static InAppNotifications get instance => _instance;

  InAppNotifications._internal() {
    titleFontSize = 14.0;
    descriptionFontSize = 14.0;
    textColor = Colors.black;
    backgroundColor = Colors.white;
    shadow = true;
    showAnimation = true;
    animationStyle = InAppNotificationsAnimationStyle.offset;
  }

  final List<InAppNotificationsStatusCallback> _statusCallbacks =
      <InAppNotificationsStatusCallback>[];

  InAppNotificationsOverlayEntry? overlayEntry;

  // GlobalKey<InAppNotificationsContainerState>? _key;
  // final List<GlobalKey<InAppNotificationsContainerState>?> _keyList = [];

  // Widget? _container;
  Stack _container = const Stack(children: []);

  // Timer? _timer;
  // final List<Timer?> _timerList = [];
  final List<InAppNotificationItem> itemList = [];

  Widget? get container => _container;

  // GlobalKey<InAppNotificationsContainerState>? get key => _keyList.first;

  /// Title font size, default: 14.0.
  late double titleFontSize;

  /// Description font size, default: 14.0.
  late double descriptionFontSize;

  /// Background color, default: [Colors.white]
  late Color backgroundColor;

  /// Text color, default: [Colors.black]
  late Color textColor;

  /// Set if notification should show shadow, default: true
  late bool shadow;

  /// Set if to show animation
  late bool showAnimation;

  /// Animation style, default: [InAppNotificationsAnimationStyle.offset].
  late InAppNotificationsAnimationStyle animationStyle;

  /// Custom animation, default: null.
  ///
  /// Set a custom animation only when [animationStyle] is [InAppNotificationsAnimationStyle.custom]
  late InAppNotificationAnimation? customAnimation;

  static TransitionBuilder init({
    TransitionBuilder? builder,
  }) {
    return (BuildContext context, Widget? child) {
      if (builder != null) {
        return builder(context, InAppNotificationsOverlay(child: child));
      } else {
        return InAppNotificationsOverlay(child: child);
      }
    };
  }

  /// Shows the In-App notification.
  ///
  /// [title] Title of the notification
  /// [description] Description of the notification
  /// [leading] Widget show leading the content
  /// [ending] Widget show ending the content
  /// [onTap] Function to be called when gesture onTap is detected
  /// [duration] Duration which the notification will be shown
  /// [persistent] Persistent mode will keep the notification visible until dismissed
  static Future<void> show({
    String? title,
    String? description,
    Widget? leading,
    Widget? ending,
    VoidCallback? onTap,
    Duration? duration,
    bool persistent = false,
    int index = 0,
    String? id,
    Widget Function()? customWidgetBuilder,
  }) {
    return _instance._show(
      title: title,
      description: description,
      leading: leading != null
          ? SizedBox(
              height: 50,
              child: leading,
            )
          : null,
      ending: ending != null
          ? SizedBox(
              height: 50,
              child: ending,
            )
          : null,
      onTap: onTap,
      persistent: persistent,
      duration: duration ?? const Duration(seconds: 5),
      index: index,
      id: id,
      customWidgetBuilder: customWidgetBuilder,
    );
  }

  /// Add status callback
  static void addStatusCallback(InAppNotificationsStatusCallback callback) {
    if (!_instance._statusCallbacks.contains(callback)) {
      _instance._statusCallbacks.add(callback);
    }
  }

  /// Remove single status callback
  static void removeCallback(InAppNotificationsStatusCallback callback) {
    if (_instance._statusCallbacks.contains(callback)) {
      _instance._statusCallbacks.remove(callback);
    }
  }

  /// Remove all status callback
  static void removeAllCallbacks() {
    _instance._statusCallbacks.clear();
  }

  Future<void> _show({
    Widget? leading,
    Widget? ending,
    String? title,
    String? description,
    VoidCallback? onTap,
    Duration? duration,
    bool persistent = false,
    int index = 0,
    String? id,
    Widget Function()? customWidgetBuilder,
  }) async {
    log('inapp: show');
    assert(
      overlayEntry != null,
      'you should call InAppNotifications.init() in your MaterialApp',
    );

    if (animationStyle == InAppNotificationsAnimationStyle.custom) {
      assert(
        customAnimation != null,
        'while animationStyle is custom, customAnimation should not be null',
      );
    }

    // if (_key != null) await dismiss(animation: false);

    Completer<void> completer = Completer<void>();
    final key = GlobalKey<InAppNotificationsContainerState>();
    // _keyList.add(_key);
    final container = InAppNotificationsContainer(
      key: key,
      title: title,
      description: description,
      leading: leading,
      ending: ending,
      onTap: onTap,
      animation: showAnimation,
      completer: completer,
      customWidgetBuilder: customWidgetBuilder,
    );
    final item = InAppNotificationItem(
      id: id,
      container: Indexed(index: index, child: container),
      key: key,
    );
    if (itemList.where((e) => e.id == id).isEmpty) {
      itemList.add(item);
    }

    _container = Indexer(
      children: itemList.map((e) => e.container).toList(),
    );
    // _container = InAppNotificationsContainer(
    //   key: _key,
    //   title: title,
    //   description: description,
    //   leading: leading,
    //   ending: ending,
    //   onTap: onTap,
    //   animation: showAnimation,
    //   completer: completer,
    // );

    completer.future.whenComplete(() {
      _callback(InAppNotificationsStatus.show);

      if (duration != null && !persistent) {
        item.timer = Timer(duration, () {
          dismiss(key: item.key);
        });
        // _cancelTimer();
        // _timerList.add(Timer(duration, dismiss));
      }
    });
    _markNeedsBuild();
    return completer.future;
  }

  static Future<void> dismiss({
    required GlobalKey<InAppNotificationsContainerState> key,
    bool animation = true,
  }) {
    return _instance._dismiss(key, animation);
  }

  void dismissById(String itemId) {
    try {
      final item = itemList.firstWhere((e) => e.id == itemId);
      dismiss(key: item.key, animation: true);
    } catch (e, st) {
      log('matched item not found: $e, $st');
    }
  }

  Future<void> _dismiss(
    GlobalKey<InAppNotificationsContainerState> key,
    bool animation,
  ) async {
    log('inapp _dismiss: $animation');
    if (key.currentState == null) {
      _reset(key);
      return;
    }

    return key.currentState?.dismiss(animation).whenComplete(() {
      _reset(key);
    });
  }

  void _reset(GlobalKey<InAppNotificationsContainerState> key) {
    // _container = null;
    // _container.children.removeAt(0);
    // containerList.removeAt(0);
    // _keyList.removeAt(0);
    try {
      final item = itemList.firstWhere((item) => item.key == key);

      item.timer?.cancel();
      itemList.remove(item);
      _cancelTimer();
      _markNeedsBuild();
      _callback(InAppNotificationsStatus.dismiss);
    } catch (e, st) {
      log('firstWhere exception: $e, $st');
    }
  }

  void _callback(InAppNotificationsStatus status) {
    for (final InAppNotificationsStatusCallback callback in _statusCallbacks) {
      callback(status);
    }
  }

  void _markNeedsBuild() {
    overlayEntry?.markNeedsBuild();
  }

  void _cancelTimer() {
    log('inapp _cancelTimer');
    // if (_timerList.isEmpty) return;
    // _timerList.first?.cancel();
    // _timerList.removeAt(0);
    // _timer = null;
  }
}

class InAppNotificationItem {
  InAppNotificationItem({
    required this.container,
    required this.key,
    this.id,
    this.timer,
  });

  final Widget container;
  final GlobalKey<InAppNotificationsContainerState> key;
  final String? id;
  Timer? timer;
}
