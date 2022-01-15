import 'dart:math';

import 'package:flutter/material.dart';

class ExpandableSidebar extends StatefulWidget {
  const ExpandableSidebar({
    Key? key,
    required this.child,
    this.controller,
    this.duration,
    this.sidebar,
    this.sidebarWidth,
    this.angle,
    this.yOffset,
    this.openBySwipe,
    this.stateChangeTrigger,
    this.sidebarColor,
    this.curve,
    this.backgroundColor,
    this.scale,
  }) : super(key: key);

  /// The [Widget] that is displayed next to the sidebar.
  final Widget child;

  /// Can be used to control the sidebar programmatically.
  final ExpandableSidebarController? controller;

  /// Duration of how long it takes to fully open up the sidebar.
  final Duration? duration;

  /// The actual content of the sidebar.
  final Widget? sidebar;

  /// The width of the sidebar.
  ///
  /// Defaults to `350`
  final double? sidebarWidth;

  /// Rotates the [child] when the sidebar is opened.
  final double? angle;

  /// Offsets the [child] on the y-axis.
  final double? yOffset;

  /// Determines wether the sidebar can be opened by swipe gestures or not.
  ///
  /// Defaults to `true`
  final bool? openBySwipe;

  /// Determines at which percentage of the [sidebarWidth] the sidebar will snap when it is dragged.
  final double? stateChangeTrigger;

  /// The sidebar's background color.
  final Color? sidebarColor;

  /// The curve with which the sidebar is animated.
  final Curve? curve;

  /// The child's background color.
  final Color? backgroundColor;

  /// The scale at which the child is shown when the sidebar is opened.
  final double? scale;

  @override
  _ExpandableSidebarState createState() => _ExpandableSidebarState();
}

class _ExpandableSidebarState extends State<ExpandableSidebar>
    with SingleTickerProviderStateMixin {
  late final Animation<Offset> sidebarTranslateAnimation;
  late final Animation<double> childRotateAnimation;
  late final Animation<Offset> sidebarSlideUpAnimation;
  late final Animation<double> childScaleAnimation;
  late final Animation<BorderRadius> childBorderRadiusAnimation;

  late final AnimationController sidebarAnimationController;
  late final ExpandableSidebarController expandableSidebarController;
  late final Duration animationDuration;
  late final double sidebarWidth;
  late final double yOffset;
  late final double angle;
  late final bool openBySwipe;
  late final double stateChangeTrigger;
  late final Color? sidebarColor;
  late final Curve curve;
  late final Color? backgroundColor;
  late final double scale;

  @override
  void initState() {
    scale = widget.scale ?? 0.8;
    backgroundColor = widget.backgroundColor;
    curve = widget.curve ?? Curves.linear;
    sidebarColor = widget.sidebarColor;
    stateChangeTrigger = widget.stateChangeTrigger ?? 0.10;
    openBySwipe = widget.openBySwipe ?? true;
    angle = widget.angle ?? 0.0;
    sidebarWidth = widget.sidebarWidth ?? 350;
    yOffset = widget.yOffset ?? 0.0;
    animationDuration = widget.duration ?? const Duration(milliseconds: 200);
    sidebarAnimationController = AnimationController(
      vsync: this,
      duration: animationDuration,
    );
    sidebarSlideUpAnimation = Tween<Offset>(
      begin: const Offset(0, 400),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: sidebarAnimationController,
      curve: curve,
    ));

    childScaleAnimation =
        Tween<double>(begin: 1.0, end: 0.8).animate(CurvedAnimation(
      parent: sidebarAnimationController,
      curve: curve,
    ));

    childBorderRadiusAnimation = Tween<BorderRadius>(
            begin: BorderRadius.circular(0.0), end: BorderRadius.circular(15.0))
        .animate(CurvedAnimation(
      parent: sidebarAnimationController,
      curve: curve,
    ));

    sidebarTranslateAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: Offset(sidebarWidth, yOffset),
    ).animate(CurvedAnimation(
      parent: sidebarAnimationController,
      curve: curve,
    ));
    childRotateAnimation = Tween<double>(begin: 0.0, end: angle).animate(
        CurvedAnimation(
            parent: sidebarAnimationController,
            curve: Interval(0.3, 1, curve: curve)));
    expandableSidebarController =
        widget.controller ?? ExpandableSidebarController();
    expandableSidebarController.addListener(() {
      if (!expandableSidebarController.isDoingManualSwipe) {
        if (expandableSidebarController.isOpening) {
          sidebarAnimationController.forward();
        } else if (expandableSidebarController.isClosing) {
          sidebarAnimationController.reverse();
        }
      }
    });

    sidebarAnimationController.addListener(() {
      expandableSidebarController
          ._setOpenedBy(sidebarAnimationController.value);
    });

    super.initState();
  }

  @override
  void dispose() {
    if (mounted) {
      try {
        expandableSidebarController.dispose();
      } catch (_) {}
    }
    // sidebarAnimationController.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return GestureDetector(
      onHorizontalDragStart: (_) {
        if (openBySwipe) {
          expandableSidebarController._setIsDoingManualSwipe(true);
        }
      },
      onHorizontalDragUpdate: (details) {
        if (openBySwipe) {
          const double sensitivity = 0.5;
          final dx = details.delta.dx;

          if (dx < 0) {
            if (!expandableSidebarController.rightSwipeAllowed) return;
          }
          if (dx > 0) {
            if (!expandableSidebarController.leftSwipeAllowed) return;
          }

          if (dx < -sensitivity || dx > sensitivity) {
            // if (swipedOffset < 0.5 && swipedOffset > -0.5) return;
            sidebarAnimationController.value += dx / sidebarWidth;
          }
        }
      },
      onHorizontalDragEnd: (_) {
        if (openBySwipe) {
          expandableSidebarController._setIsDoingManualSwipe(false);
          debugPrint(
              '------------------------------------------------------------');
          debugPrint('Swipe End');
          debugPrint(
              '------------------------------------------------------------');

          // Swipe to right
          if (expandableSidebarController.isOpening) {
            if (expandableSidebarController.openedBy >= stateChangeTrigger) {
              expandableSidebarController._setIsAutomaticallyOpening(true);
              expandableSidebarController.openSidebar();
            } else {
              expandableSidebarController._setIsAutomaticallyClosing(true);

              expandableSidebarController.closeSidebar();
            }
            // Swipe to left
          } else if (expandableSidebarController.isClosing) {
            if (expandableSidebarController.openedBy >=
                1 - stateChangeTrigger) {
              expandableSidebarController._setIsAutomaticallyOpening(true);

              expandableSidebarController.openSidebar();
            } else {
              expandableSidebarController._setIsAutomaticallyClosing(true);

              expandableSidebarController.closeSidebar();
            }
          }
        }
      },
      child: Stack(
        children: [
          Container(
              width: MediaQuery.of(context).size.width,
              height: height,
              color: sidebarColor ?? Theme.of(context).backgroundColor),
          AnimatedBuilder(
            builder: (BuildContext context, Widget? child) {
              return Transform.translate(
                offset: sidebarTranslateAnimation.value,
                child: Transform.translate(
                    offset: sidebarSlideUpAnimation.value, child: child),
              );
            },
            animation: sidebarAnimationController,
            child: Transform.translate(
              offset: Offset(-sidebarWidth, 0.0),
              child: SizedBox(
                child: widget.sidebar,
                height: height,
                width: sidebarWidth,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: sidebarAnimationController,
            child: GestureDetector(
              onTap: () {
                expandableSidebarController.closeSidebar();
              },
              child: Container(
                color: backgroundColor ?? Theme.of(context).backgroundColor,
                child: widget.child,
              ),
            ),
            builder: (BuildContext context, Widget? child) {
              final offset = sidebarTranslateAnimation.value;
              final angle = childRotateAnimation.value;
              return Transform(
                transform: Matrix4.translationValues(
                  offset.dx,
                  offset.dy +
                      sidebarAnimationController.value *
                          height *
                          ((1 - scale) / 2),
                  0,
                )
                  ..rotateZ(angle)
                  ..scale(childScaleAnimation.value),
                child: ClipRRect(
                  borderRadius: childBorderRadiusAnimation.value,
                  child: child,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /*
  double sidebarOpenedBy() {
    debugPrint('swipedOffset: $swipedOffset');
    final sidebarOpenedProgress = swipedOffset / sidebarWidth;
    debugPrint(
        'sidebarOpenedProgress: ${sidebarOpenedProgress.toStringAsFixed(2)}');
    if (sidebarOpenedProgress >= 1.0) return 1.0;
    if (sidebarOpenedProgress <= -1.0) return 0.0;
    if (sidebarOpenedProgress > 0) {
      // expandableSidebarController.openSidebar();
      return sidebarOpenedProgress;
    }
    // Left swipe
    else if (sidebarOpenedProgress < 0) {
      // expandableSidebarController.closeSidebar();
      return 1 - (sidebarOpenedProgress * -1);
    } else {
      return 0.0;
    }
  }
  */
}

class ExpandableSidebarController extends ChangeNotifier {
  ExpandableSidebarState _sidebarState = ExpandableSidebarState.closed;

  ExpandableSidebarState get sidebarState => _sidebarState;
  bool get isOpen => sidebarState == ExpandableSidebarState.open;

  bool get isClosed => sidebarState == ExpandableSidebarState.closed;

  bool get isClosing => sidebarState == ExpandableSidebarState.closing;
  bool get isOpening => sidebarState == ExpandableSidebarState.opening;

  void toggleSidebar() {
    if (isClosed || isClosing) {
      _sidebarState = ExpandableSidebarState.opening;
    } else if (isOpen || isOpening) {
      _sidebarState = ExpandableSidebarState.closing;
    }
    notifyListeners();
  }

  void closeSidebar() {
    if (!isClosed || !isClosing) {
      _sidebarState = ExpandableSidebarState.closing;
      notifyListeners();
    }
  }

  void openSidebar() {
    if (!isOpen || !isOpening) {
      _sidebarState = ExpandableSidebarState.opening;
      notifyListeners();
    }
  }

  /// The percentage of the sidebar that is already opened
  double get openedBy => _openedBy;

  double _openedBy = 0.0;

  void _setOpenedBy(double openedBy) {
    if (isClosed && openedBy > 0.0) {
      _sidebarState = ExpandableSidebarState.opening;
    } else if (isOpen && openedBy < 1.0) {
      _sidebarState = ExpandableSidebarState.closing;
    }
    if (openedBy == 0.0 && (isClosing)) {
      _sidebarState = ExpandableSidebarState.closed;
      _isAutomaticallyClosing = false;
    } else if (openedBy == 1.0 && (isOpening)) {
      _sidebarState = ExpandableSidebarState.open;
      _isAutomaticallyOpening = false;
    }
    _openedBy = openedBy;
    notifyListeners();
  }

  bool get isDoingManualSwipe => _isDoingManualSwipe;

  bool _isDoingManualSwipe = false;

  void _setIsDoingManualSwipe(bool isDoingManualSwipe) {
    _isDoingManualSwipe = isDoingManualSwipe;
    notifyListeners();
  }

  bool _isAutomaticallyClosing = false;
  bool _isAutomaticallyOpening = false;

  bool get isAutomaticallyClosing => _isAutomaticallyClosing;
  bool get isAutomaticallyOpening => _isAutomaticallyOpening;

  void _setIsAutomaticallyClosing(bool value) {
    _isAutomaticallyClosing = value;
    notifyListeners();
  }

  void _setIsAutomaticallyOpening(bool value) {
    _isAutomaticallyOpening = value;
    notifyListeners();
  }

  bool get rightSwipeAllowed {
    if (isClosed) return false;
    if (isAutomaticallyClosing && isClosing) return false;
    return true;
  }

  bool get leftSwipeAllowed {
    if (isOpen) return false;
    if (isAutomaticallyOpening && isOpening) return false;
    return true;
  }

  @override
  String toString() {
    return 'ExpandableSidebarController(_sidebarState: $_sidebarState, _openedBy: $_openedBy, _isDoingManualSwipe: $_isDoingManualSwipe, _isAutomaticallyClosing: $_isAutomaticallyClosing, _isAutomaticallyOpening: $_isAutomaticallyOpening)';
  }
}

enum ExpandableSidebarState {
  opening,
  closing,
  closed,
  open,
}
