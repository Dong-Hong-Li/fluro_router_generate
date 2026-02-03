import 'package:flutter/material.dart';
import 'package:fluro_router_generate/src/enum.dart';
import 'package:fluro_router_generate/src/mixin_fluro_router_tools.dart';
import 'package:fluro_router_generate/src/strategy/route_strategy.dart';
import 'package:fluro_router_generate/src/strategy/transition_effect.dart';

class RouteStrategyFactory {
  /// 不需要曲线参数的静态策略（原生、Material、Cupertino）
  static final Map<TransitionType, RouteStrategy> _staticStrategies = {
    TransitionType.native: NativeRouteStrategy(),
    TransitionType.nativeModal: NativeRouteStrategy(),
    TransitionType.material: MaterialRouteStrategy(),
    TransitionType.materialFullScreenDialog: MaterialRouteStrategy(),
    TransitionType.cupertino: CupertinoRouteStrategy(),
    TransitionType.cupertinoFullScreenDialog: CupertinoRouteStrategy(),
    TransitionType.custom: CustomRouteStrategy(),
  };

  /// 获取路由策略
  ///
  /// - [transition] 过渡类型
  /// - [curve] 动画曲线（可选，默认使用 easeInOut）
  static RouteStrategy getStrategy(TransitionType? transition, {Curve? curve}) {
    // 如果是静态策略类型，直接返回
    if (_staticStrategies.containsKey(transition)) {
      return _staticStrategies[transition]!;
    }

    // 动态创建带曲线的策略
    final effectiveCurve = curve ?? FluroRouterTools.defaultTransitionCurve;

    switch (transition) {
      case TransitionType.inFromLeft:
        return SimpleTransitionStrategy(
          TransitionEffect.inFromLeftTransitionWithCurve(effectiveCurve),
        );
      case TransitionType.inFromTop:
        return SimpleTransitionStrategy(
          TransitionEffect.inFromTopTransitionWithCurve(effectiveCurve),
        );
      case TransitionType.inFromRight:
        return SimpleTransitionStrategy(
          TransitionEffect.inFromRightTransitionWithCurve(effectiveCurve),
        );
      case TransitionType.inFromBottom:
        return SimpleTransitionStrategy(
          TransitionEffect.inFromBottomTransitionWithCurve(effectiveCurve),
        );
      case TransitionType.fadeIn:
        return SimpleTransitionStrategy(
          TransitionEffect.fadeTransitionWithCurve(effectiveCurve),
        );
      case TransitionType.fadeInAndFromBottom:
        return SimpleTransitionStrategy(
          TransitionEffect.fadeInAndFromBottomTransitionWithCurve(
            effectiveCurve,
          ),
        );
      case TransitionType.none:
        return SimpleTransitionStrategy(TransitionEffect.noneTransition);
      default:
        return CustomRouteStrategy();
    }
  }
}
