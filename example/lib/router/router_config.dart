import 'package:fluro_router_generate/fluro_router.dart';

export 'router_config.g.dart';

@EntranceAnnotation()
class RouteConfig extends FluroConfig {
  RouteConfig._();
  static final RouteConfig instance = RouteConfig._();
}
