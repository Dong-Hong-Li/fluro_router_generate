
import 'package:fluro_router_generate/fluro_router.dart';

/// [FluroHandler] 注册到 [FluroRouter] 上，然后当路由匹配成功时，[FluroRouter] 就会调
/// 用这个 [FluroHandler] 来处理请求。
class FluroHandler {
  FluroHandler({this.type = HandlerType.route, required this.handlerFunc});

  ///默认值为 [HandlerType.route]，即默认使用构建路由的方法。
  final HandlerType type;

  ///实现依赖于[HandlerType]类型的处理器。
  final HandlerFunc handlerFunc;
}

///方便路由注册的和管理
class RouterHandler {
  final String path;

  final FluroHandler handler;

  RouterHandler(this.path, this.handler);
}
