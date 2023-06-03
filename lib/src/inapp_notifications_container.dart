import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../flutter_inapp_notifications.dart';
import '../theme.dart';

class InAppNotificationsContainer extends StatefulWidget {
  final Widget? leading;
  final Widget? ending;
  final String? title;
  final String? description;
  final VoidCallback? onTap;
  final Completer<void>? completer;
  final bool animation;

  const InAppNotificationsContainer({
    required Key key,
    this.leading,
    this.ending,
    this.title,
    this.description,
    this.onTap,
    this.completer,
    this.animation = true,
  }) : super(key: key);

  @override
  InAppNotificationsContainerState createState() =>
      InAppNotificationsContainerState();
}

class InAppNotificationsContainerState
    extends State<InAppNotificationsContainer>
    with SingleTickerProviderStateMixin {
  String? _title;
  String? _description;
  late AnimationController _animationController;

  bool get isPersistentCallbacks =>
      SchedulerBinding.instance.schedulerPhase ==
      SchedulerPhase.persistentCallbacks;

  @override
  void initState() {
    super.initState();
    if (!mounted) return;

    _title = widget.title;
    _description = widget.description;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((status) {
        bool isCompleted = widget.completer?.isCompleted ?? false;
        if (status == AnimationStatus.completed && !isCompleted) {
          widget.completer?.complete();
        }
      });

    show(widget.animation);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> show(bool animation) {
    if (isPersistentCallbacks) {
      Completer<TickerFuture> completer = Completer<TickerFuture>();
      SchedulerBinding.instance.addPostFrameCallback((_) => completer
          .complete(_animationController.forward(from: animation ? 0 : 1)));
      return completer.future;
    } else {
      return _animationController.forward(from: animation ? 0 : 1);
    }
  }

  Future<void> dismiss(bool animation) {
    if (isPersistentCallbacks) {
      Completer<TickerFuture> completer = Completer<TickerFuture>();
      SchedulerBinding.instance.addPostFrameCallback((_) => completer
          .complete(_animationController.reverse(from: animation ? 1 : 0)));
      return completer.future;
    } else {
      return _animationController.reverse(from: animation ? 1 : 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.topCenter,
      children: <Widget>[
        AnimatedBuilder(
          animation: _animationController,
          builder: (BuildContext context, Widget? child) {
            return Opacity(
              opacity: _animationController.value,
              child: const SizedBox(
                width: double.infinity,
                height: double.infinity,
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _animationController,
          builder: (BuildContext context, Widget? child) {
            return InAppNotificationsTheme.showAnimation.buildWidget(
              _Notification(
                stateKey: widget.key!,
                title: _title,
                description: _description,
                leading: widget.leading,
                ending: widget.ending,
                onTap: widget.onTap,
              ),
              _animationController,
              AlignmentDirectional.topCenter,
            );
          },
        ),
      ],
    );
  }
}

class _Notification extends StatelessWidget {
  final Widget? leading;
  final Widget? ending;
  final String? title;
  final String? description;
  final VoidCallback? onTap;

  const _Notification(
      {required this.stateKey,
      required this.leading,
      required this.ending,
      required this.title,
      required this.description,
      required this.onTap});

  final Key stateKey;

  Widget _buildNotification(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: InAppNotificationsTheme.backgroundColor,
        // borderRadius: BorderRadius.circular(8.0),
        // boxShadow: InAppNotificationsTheme.shadow
        //     ? const [
        //         BoxShadow(blurRadius: 10.0, color: Colors.black26),
        //       ]
        //     : null,
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).viewPadding.top + 16,
        16,
        16,
      ),
      child: Row(
        children: <Widget>[
          if (leading != null) leading ?? const SizedBox(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: InAppNotificationsTheme.titleFontSize,
                      color: InAppNotificationsTheme.textColor,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (description != null)
                  Flexible(
                    child: Text(
                      description!,
                      style: TextStyle(
                        fontSize: InAppNotificationsTheme.descriptionFontSize,
                        color: InAppNotificationsTheme.textColor,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (ending != null)
            Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: ending,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return onTap == null
        ? _buildNotification(context)
        : GestureDetector(
            onTap: () {
              InAppNotifications.dismiss(
                  key: stateKey as GlobalKey<InAppNotificationsContainerState>);
              onTap?.call();
            },
            onVerticalDragUpdate: (details) {
              int sensitivity = 8;
              if (details.delta.dy > sensitivity) {
                // Down Swipe
              } else if (details.delta.dy < -sensitivity) {
                InAppNotifications.dismiss(
                    key: stateKey
                        as GlobalKey<InAppNotificationsContainerState>);
              }
            },
            onHorizontalDragUpdate: (details) {
              // Note: Sensitivity is integer used when you don't want to mess up vertical drag
              int sensitivity = 8;
              if (details.delta.dx > sensitivity) {
                // Right Swipe
                InAppNotifications.dismiss(
                    key: stateKey
                        as GlobalKey<InAppNotificationsContainerState>);
              } else if (details.delta.dx < -sensitivity) {
                //Left Swipe
                InAppNotifications.dismiss(
                    key: stateKey
                        as GlobalKey<InAppNotificationsContainerState>);
              }
            },
            child: _buildNotification(context),
          );
  }
}
