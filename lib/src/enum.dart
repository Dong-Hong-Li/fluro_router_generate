/// 路由被匹配时，路由的处理方式
enum HandlerType {
  route,
  function,
}

/// 用于表示在路由切换时所使用的过渡动画类型。
enum TransitionType {
  /// 使用平台的原生过渡效果。
  native,

  /// 使用平台的原生模态过渡效果
  nativeModal,

  /// 从左侧进入的过渡效果。
  inFromLeft,

  /// 从顶部进入的过渡效果。
  inFromTop,

  /// 从右侧进入的过渡效果。
  inFromRight,

  /// 从底部进入的过渡效果。
  inFromBottom,

  ///淡入效果。
  fadeIn,

  /// 淡入并从底部进入的过度效果。
  fadeInAndFromBottom,

  /// 支持自定义,使用时必须提供自定义过渡效果。
  custom,

  /// Material设计风格的过渡效果。
  material,

  /// Material设计风格的全屏对话框过渡效果。
  materialFullScreenDialog,

  /// Cupertino设计风格的过渡效果。
  cupertino,

  /// Cupertino设计风格的全屏对话框过渡效果。
  cupertinoFullScreenDialog,

  /// 没有过渡效果。
  none,
}

/// 路由匹配结果
enum RouteMatchType {
  /// 该路由是一个可视的页面
  visual,

  /// 路由不一定会显示为一个可视的页面
  nonVisual,

  /// 表示没有找到匹配的路由路径。
  noMatch,
}

/// 表示路由树中的不同类型节点
///
/// ```dart
///
/// 假设有一个动态路由 /user/:id，其中 :id 是一个参数。我们可以将路由路径解析成一棵树：
///
/// /user
///  └── :id
///
/// ```
enum RouteTreeNodeType {
  component,
  parameter,
}
