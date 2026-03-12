import 'dart:async';

import 'package:flutter/material.dart';

typedef DeferredWidgetBuilder = Widget Function(BuildContext context);

typedef DeferredLoadingBuilder =
    Widget Function(BuildContext context, AsyncSnapshot<void> snapshot);

typedef DeferredErrorBuilder =
    Widget Function(BuildContext context, Object error, StackTrace? stackTrace);

/// 自定义「加载过程 → 内容」的包装器，用于完全接管 loading/动画/错误展示。
///
/// 参数：
/// - [context]：当前 BuildContext
/// - [loadFuture]：由 [DeferredRoutePage] 内部调用 [loader] 得到的一次性 Future，可直接交给自封装 FutureBuilder
/// - [buildContent]：加载完成后用于构建目标页面的回调，在 Future 完成后调用即可得到内容 Widget
///
/// 示例：自封装 FutureBuilder + 动画
/// ```dart
/// wrapper: (context, loadFuture, buildContent) => FutureBuilder<void>(
///   future: loadFuture,
///   builder: (context, snapshot) {
///     if (snapshot.connectionState != ConnectionState.done) {
///       return YourLoadingAnimation();
///     }
///     if (snapshot.hasError) return YourErrorPage(snapshot.error!);
///     return buildContent(context);
///   },
/// )
/// ```
typedef DeferredRouteWrapper = Widget Function(
  BuildContext context,
  Future<void> loadFuture,
  Widget Function(BuildContext context) buildContent,
);

/// 用于配置 Deferred 路由的加载中/失败 UI，可在 [FluroConfig] 中设置全局默认或按 path 覆盖。
class DeferredRouteUIOptions {
  const DeferredRouteUIOptions({
    this.loadingBuilder,
    this.errorBuilder,
    this.wrapper,
  });

  final DeferredLoadingBuilder? loadingBuilder;
  final DeferredErrorBuilder? errorBuilder;

  /// 若设置，将完全接管「加载过程 → 内容」的展示，[loadingBuilder] / [errorBuilder] 仅在默认逻辑下生效。
  final DeferredRouteWrapper? wrapper;
}

/// 用于承载 deferred import 的通用加载页。
///
/// 由于 Fluro 的 handler 约定是同步返回 Widget，这个组件把 `loadLibrary()`
/// 的异步过程封装到页面内部，避免改动现有 HandlerFunc 签名。
///
/// **两种用法：**
///
/// 1. **默认逻辑**（不传 [wrapper]）：内部使用 [FutureBuilder]，可通过 [loadingBuilder] / [errorBuilder] 定制加载中/失败 UI。
///
/// 2. **完全自定义**（传 [wrapper]）：由你自封装 FutureBuilder 并集成动画，[loadFuture] 与 [buildContent] 交给 [wrapper]；此时 [loadingBuilder] / [errorBuilder] 无效。
class DeferredRoutePage extends StatelessWidget {
  const DeferredRoutePage({
    super.key,
    required this.loader,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.debugLabel,
    this.wrapper,
  });

  final Future<void> Function() loader;
  final DeferredWidgetBuilder builder;
  final DeferredLoadingBuilder? loadingBuilder;
  final DeferredErrorBuilder? errorBuilder;
  final String? debugLabel;

  /// 可选。若提供，将完全接管「加载过程 → 内容」的展示，便于自封装 FutureBuilder 与动画；[loadingBuilder] / [errorBuilder] 不再使用。
  final DeferredRouteWrapper? wrapper;

  @override
  Widget build(BuildContext context) {
    final loadFuture = loader();

    if (wrapper != null) {
      return wrapper!(context, loadFuture, builder);
    }

    return FutureBuilder<void>(
      future: loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          if (loadingBuilder != null) return loadingBuilder!(context, snapshot);
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          if (errorBuilder != null) {
            return errorBuilder!(context, snapshot.error!, snapshot.stackTrace);
          }
          final msg = debugLabel == null
              ? 'Deferred load failed'
              : 'Deferred load failed: $debugLabel';
          return Scaffold(
            body: Center(child: Text(msg, textAlign: TextAlign.center)),
          );
        }
        return builder(context);
      },
    );
  }
}
