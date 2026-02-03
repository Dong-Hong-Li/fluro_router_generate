import 'package:fluro_router_generate/src/strategy/swipe_back_wrapper.dart';
import 'package:flutter/material.dart';

/// 过渡效果工厂类
///
/// 提供各种预设的过渡效果，支持自定义动画曲线
class TransitionEffect {
  /// 创建带曲线的淡入淡出效果
  static RouteTransitionsBuilder fadeTransitionWithCurve(Curve curve) =>
      (context, animation, secondaryAnimation, child) => SwipeBackWrapper.wrap(
        context,
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: curve),
          child: child,
        ),
      );

  /// 淡入淡出效果（默认曲线）
  static RouteTransitionsBuilder get fadeTransition =>
      fadeTransitionWithCurve(Curves.easeInOut);

  /// 创建带曲线的从左侧进入效果
  static RouteTransitionsBuilder inFromLeftTransitionWithCurve(Curve curve) =>
      (context, animation, secondaryAnimation, child) => SwipeBackWrapper.wrap(
        context,
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        ),
        direction: SwipeDirection.rightToLeft,
      );

  /// 从左侧进入的过渡效果（默认曲线）
  static RouteTransitionsBuilder get inFromLeftTransition =>
      inFromLeftTransitionWithCurve(Curves.easeInOut);

  /// 创建带曲线的从顶部进入效果
  static RouteTransitionsBuilder inFromTopTransitionWithCurve(Curve curve) =>
      (context, animation, secondaryAnimation, child) => SwipeBackWrapper.wrap(
        context,
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        ),
        direction: SwipeDirection.bottomToTop,
      );

  /// 从顶部进入的过渡效果（默认曲线）
  static RouteTransitionsBuilder get inFromTopTransition =>
      inFromTopTransitionWithCurve(Curves.easeInOut);

  /// 创建带曲线的从右侧进入效果
  static RouteTransitionsBuilder inFromRightTransitionWithCurve(Curve curve) =>
      (context, animation, secondaryAnimation, child) => SwipeBackWrapper.wrap(
        context,
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        ),
        direction: SwipeDirection.leftToRight,
      );

  /// 从右侧进入的过渡效果（默认曲线）
  static RouteTransitionsBuilder get inFromRightTransition =>
      inFromRightTransitionWithCurve(Curves.easeInOut);

  /// 创建带曲线的从底部进入效果
  static RouteTransitionsBuilder inFromBottomTransitionWithCurve(Curve curve) =>
      (context, animation, secondaryAnimation, child) => SwipeBackWrapper.wrap(
        context,
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        ),
        direction: SwipeDirection.topToBottom,
      );

  /// 从底部进入的过渡效果（默认曲线）
  static RouteTransitionsBuilder get inFromBottomTransition =>
      inFromBottomTransitionWithCurve(Curves.easeInOut);

  /// 创建带曲线的淡入 + 从底部进入效果
  static RouteTransitionsBuilder fadeInAndFromBottomTransitionWithCurve(
    Curve curve,
  ) =>
      (context, animation, secondaryAnimation, child) => SwipeBackWrapper.wrap(
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
      );

  /// 淡入 + 从底部进入效果（默认曲线）
  static RouteTransitionsBuilder get fadeInAndFromBottomTransition =>
      fadeInAndFromBottomTransitionWithCurve(Curves.easeInOut);

  /// 没有过渡效果
  static RouteTransitionsBuilder get noneTransition =>
      (context, animation, secondaryAnimation, child) =>
          SwipeBackWrapper.wrap(context, child);

  /// 根据过渡类型和曲线获取对应的过渡构建器
  static RouteTransitionsBuilder getTransitionBuilder(
    String transitionType,
    Curve curve,
  ) {
    switch (transitionType) {
      case 'fadeIn':
        return fadeTransitionWithCurve(curve);
      case 'inFromLeft':
        return inFromLeftTransitionWithCurve(curve);
      case 'inFromTop':
        return inFromTopTransitionWithCurve(curve);
      case 'inFromRight':
        return inFromRightTransitionWithCurve(curve);
      case 'inFromBottom':
        return inFromBottomTransitionWithCurve(curve);
      case 'fadeInAndFromBottom':
        return fadeInAndFromBottomTransitionWithCurve(curve);
      case 'none':
        return noneTransition;
      default:
        return inFromRightTransitionWithCurve(curve);
    }
  }
}
