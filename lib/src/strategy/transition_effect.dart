import 'package:fluro_router_generate/src/strategy/swipe_back_wrapper.dart';
import 'package:flutter/material.dart';

/// 过渡效果工厂类
///
/// 提供各种预设的过渡效果，支持自定义动画曲线
class TransitionEffect {
  static Widget _maybeWrapSwipeBack(
    BuildContext context,
    Widget child, {
    SwipeDirection direction = SwipeDirection.leftToRight,
    bool disableSwipeBack = false,
  }) {
    if (disableSwipeBack) return child;
    return SwipeBackWrapper.wrap(context, child, direction: direction);
  }

  /// 创建带曲线的淡入淡出效果
  static RouteTransitionsBuilder fadeTransitionWithCurve(
    Curve curve, {
    bool disableSwipeBack = false,
  }) =>
      (context, animation, secondaryAnimation, child) => _maybeWrapSwipeBack(
        context,
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: curve),
          child: child,
        ),
        disableSwipeBack: disableSwipeBack,
      );

  /// 淡入淡出效果（默认曲线）
  static RouteTransitionsBuilder get fadeTransition =>
      fadeTransitionWithCurve(Curves.easeInOut);

  /// 创建带曲线的从左侧进入效果
  static RouteTransitionsBuilder inFromLeftTransitionWithCurve(
    Curve curve, {
    bool disableSwipeBack = false,
  }) =>
      (context, animation, secondaryAnimation, child) => _maybeWrapSwipeBack(
        context,
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        ),
        direction: SwipeDirection.rightToLeft,
        disableSwipeBack: disableSwipeBack,
      );

  /// 从左侧进入的过渡效果（默认曲线）
  static RouteTransitionsBuilder get inFromLeftTransition =>
      inFromLeftTransitionWithCurve(Curves.easeInOut);

  /// 创建带曲线的从顶部进入效果
  static RouteTransitionsBuilder inFromTopTransitionWithCurve(
    Curve curve, {
    bool disableSwipeBack = false,
  }) =>
      (context, animation, secondaryAnimation, child) => _maybeWrapSwipeBack(
        context,
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        ),
        direction: SwipeDirection.bottomToTop,
        disableSwipeBack: disableSwipeBack,
      );

  /// 从顶部进入的过渡效果（默认曲线）
  static RouteTransitionsBuilder get inFromTopTransition =>
      inFromTopTransitionWithCurve(Curves.easeInOut);

  /// 创建带曲线的从右侧进入效果
  static RouteTransitionsBuilder inFromRightTransitionWithCurve(
    Curve curve, {
    bool disableSwipeBack = false,
  }) =>
      (context, animation, secondaryAnimation, child) => _maybeWrapSwipeBack(
        context,
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        ),
        direction: SwipeDirection.leftToRight,
        disableSwipeBack: disableSwipeBack,
      );

  /// 从右侧进入的过渡效果（默认曲线）
  static RouteTransitionsBuilder get inFromRightTransition =>
      inFromRightTransitionWithCurve(Curves.easeInOut);

  /// 创建带曲线的从底部进入效果
  static RouteTransitionsBuilder inFromBottomTransitionWithCurve(
    Curve curve, {
    bool disableSwipeBack = false,
  }) =>
      (context, animation, secondaryAnimation, child) => _maybeWrapSwipeBack(
        context,
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        ),
        direction: SwipeDirection.topToBottom,
        disableSwipeBack: disableSwipeBack,
      );

  /// 从底部进入的过渡效果（默认曲线）
  static RouteTransitionsBuilder get inFromBottomTransition =>
      inFromBottomTransitionWithCurve(Curves.easeInOut);

  /// 创建带曲线的淡入 + 从底部进入效果
  static RouteTransitionsBuilder fadeInAndFromBottomTransitionWithCurve(
    Curve curve, {
    bool disableSwipeBack = false,
  }) =>
      (context, animation, secondaryAnimation, child) => _maybeWrapSwipeBack(
        context,
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: curve),
            child: child,
          ),
        ),
        direction: SwipeDirection.topToBottom,
        disableSwipeBack: disableSwipeBack,
      );

  /// 淡入 + 从底部进入效果（默认曲线）
  static RouteTransitionsBuilder get fadeInAndFromBottomTransition =>
      fadeInAndFromBottomTransitionWithCurve(Curves.easeInOut);

  /// 没有过渡效果
  static RouteTransitionsBuilder noneTransition({
    bool disableSwipeBack = false,
  }) =>
      (context, animation, secondaryAnimation, child) => _maybeWrapSwipeBack(
        context,
        child,
        disableSwipeBack: disableSwipeBack,
      );

  /// 根据过渡类型和曲线获取对应的过渡构建器
  static RouteTransitionsBuilder getTransitionBuilder(
    String transitionType,
    Curve curve, {
    bool disableSwipeBack = false,
  }) {
    switch (transitionType) {
      case 'fadeIn':
        return fadeTransitionWithCurve(
          curve,
          disableSwipeBack: disableSwipeBack,
        );
      case 'inFromLeft':
        return inFromLeftTransitionWithCurve(
          curve,
          disableSwipeBack: disableSwipeBack,
        );
      case 'inFromTop':
        return inFromTopTransitionWithCurve(
          curve,
          disableSwipeBack: disableSwipeBack,
        );
      case 'inFromRight':
        return inFromRightTransitionWithCurve(
          curve,
          disableSwipeBack: disableSwipeBack,
        );
      case 'inFromBottom':
        return inFromBottomTransitionWithCurve(
          curve,
          disableSwipeBack: disableSwipeBack,
        );
      case 'fadeInAndFromBottom':
        return fadeInAndFromBottomTransitionWithCurve(
          curve,
          disableSwipeBack: disableSwipeBack,
        );
      case 'none':
        return noneTransition(disableSwipeBack: disableSwipeBack);
      default:
        return inFromRightTransitionWithCurve(
          curve,
          disableSwipeBack: disableSwipeBack,
        );
    }
  }
}
