enum HandlerConstructorParams {
  /// 不传参
  none,

  /// 传入路径参数
  pathParams,

  /// 传入查询参数
  queryParams,

  /// 传入 RouteSettings 参数
  routeSettingsArguments,
}

/// 路由注解
class RouterAnnotation {
  /// 路由路径。支持 FluroRouter 自带传参：
  /// - 路径参数：如 `/home/:id`，匹配 `/home/123` 时 parameters['id'] = ['123']
  /// - 查询参数：如 `/home?id=1`，匹配时 parameters['id'] = ['1']
  final String path;

  /// 默认参数：路由传参一般通过 push/navigateTo 传入，未传时使用此处默认值，减少报错。
  /// 键为构造参数名，值为默认值（如 defaultParams: {'id': '-', 'title': '详情'}）。
  final Map<String, dynamic>? defaultParams;

  /// 描述
  final String? description;

  /// 可选模块名，用于在生成代码中按模块分组路由，便于阅读（如 'auth'、'user'、'home'）。
  /// 未设置时归入 default 组。
  final String? module;

  /// 在构造函数传入参数
  ///
  /// ```dart
  /// @RouterAnnotation(path: '/home/:id', constructorParams: HandlerConstructorParams.pathParams)
  /// class HomePage extends StatelessWidget {
  ///   final String id;
  ///   const HomePage({super.key, required this.id});
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return Text('HomePage: $id');
  ///   }
  /// }
  ///
  /// ------------------------------------------------------------
  /// FluroConfig.push('/home/1', context: context);
  ///
  /// 如果 constructorParams 为 HandlerConstructorParams.pathParams，则会在构造函数传入 path 参数
  /// RouterHandler(
  ///    '/home/:id',
  ///    FluroHandler(handlerFunc: (context, parameters) => HomePage(id: parameters['id']?.first ?? '-')),
  ///  ),
  ///
  /// ------------------------------------------------------------
  /// FluroConfig.push('/home?id=1', context: context);
  ///
  ///
  /// 如果 constructorParams 为 HandlerConstructorParams.queryParams，则会在构造函数传入 query 参数
  /// RouterHandler(
  ///    '/home?id=1',
  ///    FluroHandler(handlerFunc: (context, parameters) => HomePage(id: parameters['id']?.first ?? '-')),
  ///  ),
  ///
  /// ------------------------------------------------------------
  ///
  /// FluroConfig.push('/home', context: context, routeSettings: RouteSettings(name: '/home', arguments: {'name': '张三'}));
  ///
  /// 如果 constructorParams 为 HandlerConstructorParams.routeSettingsArguments，则会在构造函数传入 routeSettings 参数
  /// RouterHandler(
  ///    '/home',
  ///    FluroHandler(handlerFunc: (context, parameters){
  ///      final routeSettings = context.settings;
  ///      final arguments = routeSettings?.arguments;
  ///      final argsMap = arguments is Map<dynamic, dynamic> ? arguments : null;
  ///      final name = argsMap?['name']?.toString() ?? '未传 name';
  ///      return HomePage(name: name);
  /// }),
  ///  ),
  /// ```
  final HandlerConstructorParams constructorParams;

  const RouterAnnotation({
    required this.path,
    this.defaultParams,
    this.description,
    this.module,
    this.constructorParams = HandlerConstructorParams.none,
  });
}

/// 入口标记注解
class EntranceAnnotation {
  const EntranceAnnotation();
}

// TransitionType.native: NativeRouteStrategy(),
// TransitionType.nativeModal: NativeRouteStrategy(),
// TransitionType.material: MaterialRouteStrategy(),
// TransitionType.materialFullScreenDialog: MaterialRouteStrategy(),
// TransitionType.cupertino: CupertinoRouteStrategy(),
// TransitionType.cupertinoFullScreenDialog: CupertinoRouteStrategy(),
// TransitionType.custom: CustomRouteStrategy(),
