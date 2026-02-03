import 'package:flutter/material.dart';

/// 这个回调函数用于处理路由匹配后应该执行的操作，具体是根据路径和参数构建并返回一个 [Widget] 屏幕。
///
/// ```dart
/// 1. 定义处理函数
///  HandlerFunc handlerFunction =
///      (BuildContext? context, Map<String, List<String>> parameters) {
///    final String? id = parameters['id']?.first; // 获取 'id' 参数
///    return DetailsPage(id: id); // 返回一个根据参数构建的页面
/// };
///
/// 2. 创建 Handler 对象
///  Handler handler = Handler(
///    type: HandlerType.function, // 使用函数类型的 Handler
///    handlerFunc: handlerFunction, // 将 handlerFunction 赋给 handlerFunc
///  );
///
///  3. 注册路由
///  router.define('/details/:id', handler: handler);
///
/// ```
typedef HandlerFunc = Widget? Function(
  BuildContext? context,
  Map<String, List<String>> parameters,
);

/// 当没有找到路由时。抛出异常
class RouteNotFoundException implements Exception {
  RouteNotFoundException(
    this.message,
    this.path,
  );

  final String message;
  final String path;

  @override
  String toString() {
    return "No registered route was found to handle '$path'";
  }
}

///方便访问路由设置和参数的方法
extension FluroBuildContextX on BuildContext {
  /// `ModalRoute.of(context).settings`
  RouteSettings? get settings => ModalRoute.of(this)?.settings;

  /// `ModalRoute.of(context).settings.arguments`
  Object? get arguments => ModalRoute.of(this)?.settings.arguments;
}

/// 列表扩展方法
extension ListExtension<E> on List<E> {
  /// 返回第一个满足条件的元素，如果没有则返回 null
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
