# Changelog / 更新日志

---

## 1.4.2

**English**

- **`FluroRouter.pop` / `popToRoot` / `popUntil`**: Align with [`Navigator`] APIs—optional **`rootNavigator`** on all three; **`popUntil`** matches [`Navigator.popUntil`] (removed the unused positional `result` argument that was never forwarded). **`popToRoot`** is equivalent to `popUntil` until `route.isFirst`. **`pop`** uses named **`result`** (call `pop(context, result: value)` instead of a second positional argument).
- **`FluroConfig`**: **`pop`**, **`popToRoot`**, **`popUntil`** mirror the router methods, using optional **`context`** or configured **`currentContext`** (same rule as **`push`**).
- **CI**: Pre-generate `example` router code (`flutter pub get` + `dart run build_runner build --delete-conflicting-outputs` inside `example/`) before `flutter test`, so `deferred_generation_regression_test.dart` can read the `*.router.g.dart` files that are excluded by `.gitignore`. `test` and `publish` jobs are aligned; trigger `paths` now also include `example/**` and `.github/workflows/**`.
- **Static analysis**: `dart analyze --fatal-warnings --fatal-infos` is clean. Closures that bound a function to a name now use a function declaration (`route_strategy.dart`: `NativeRouteStrategy` / `MaterialRouteStrategy` / `CupertinoRouteStrategy` / `CustomRouteStrategy` / `SimpleTransitionStrategy`), `fluro_router_gen.dart` adds braces to a single-statement `if`, and the `example` `authGuard2` post-`await` `context` use is annotated like `authGuard1`.

**中文**

- **`FluroRouter.pop` / `popToRoot` / `popUntil`**：与 [`Navigator`] 对齐，三者均支持可选 **`rootNavigator`**；**`popUntil`** 与 [`Navigator.popUntil`] 一致，并移除原先未实际传入 Navigator 的无用 **`result` 位置参数**。**`popToRoot`** 等价于一直 `popUntil` 到 `route.isFirst`。**`pop`** 的返回值改为命名参数 **`result`**（写成 `pop(context, result: value)`，勿再用第二位位置参数）。
- **`FluroConfig`**：新增 **`pop`**、**`popToRoot`**、**`popUntil`**，与路由器方法对应；**`context`** 可省略时使用已配置的 **`currentContext`**（与 **`push`** 相同）。
- **CI**：在 `flutter test` 之前先在 `example/` 内执行 `flutter pub get` 与 `dart run build_runner build --delete-conflicting-outputs`，预生成 `.router.g.dart`（这些文件被 `.gitignore` 排除），修复 CI 上 `deferred_generation_regression_test.dart` 因找不到生成文件而失败的问题；`test` / `publish` 两个 job 步骤对齐；触发 `paths` 增加 `example/**` 与 `.github/workflows/**`。
- **静态分析**：`dart analyze --fatal-warnings --fatal-infos` 零告警。`route_strategy.dart` 中 `NativeRouteStrategy` / `MaterialRouteStrategy` / `CupertinoRouteStrategy` / `CustomRouteStrategy` / `SimpleTransitionStrategy` 的局部闭包改为函数声明；`fluro_router_gen.dart` 单语句 `if` 补花括号；`example` 中 `authGuard2` 的 `await` 后 `context` 使用与 `authGuard1` 对齐。

---

## 1.4.1

**English**

- **FluroConfig.push**: Forwards `disableSwipeBack` to `FluroRouter.navigateTo` (previously omitted, so the flag had no effect when using generated push).
- **disableSwipeBack**: When `true`, uses routes that set `popGestureEnabled` to `false` so iOS edge swipe-back on `MaterialPageRoute` / `CupertinoPageRoute` / custom `PageRouteBuilder` is disabled alongside `SwipeBackWrapper`.
- **Preset transitions (`inFromRight`, etc.)**: `SimpleTransitionStrategy` defaults `PageRouteBuilder.opaque` to `false` (was incorrectly opaque in debug builds), so slide transitions can show the underlying route as intended.
- **Docs / DX**: Clarified `disableSwipeBack` on `FluroRouteData` and `FluroConfig.push`; fixed typo in the missing-context exception (`FiuroConfig` → `FluroConfig`).

**中文**

- **FluroConfig.push**：将 `disableSwipeBack` 透传给 `FluroRouter.navigateTo`（此前未传递，生成式 push 时该开关不生效）。
- **disableSwipeBack**：为 `true` 时使用 `popGestureEnabled == false` 的路由子类，在关闭 `SwipeBackWrapper` 的同时禁用 iOS 上 Material/Cupertino/自定义 `PageRouteBuilder` 的左缘返回手势。
- **预设转场（如 `inFromRight`）**：`SimpleTransitionStrategy` 默认 `PageRouteBuilder.opaque` 为 `false`（此前在 debug 下错误地为不透明），侧滑/转场时可露出下层页面。
- **文档与体验**：补充 `FluroRouteData`、`FluroConfig.push` 上 `disableSwipeBack` 说明；修正未设置 context 时异常文案拼写（`FiuroConfig` → `FluroConfig`）。

---

## 1.4.0

**English**

- **Disable swipe-back wrapper**: New `disableSwipeBack` (default `false`) on `FluroRouter.define`, `navigateTo`, `FluroConfig.push`, and `matchRoute`. When `true`, preset transitions (`inFromLeft` / `fadeIn` / `none`, etc.) no longer wrap with `SwipeBackWrapper`. Route-level and per-push flags are OR’d; guard suspend/resume preserves the flag via `PendingNavigation`.
- **Deferred route UX**: `DeferredRoutePage` supports optional `wrapper` for custom `FutureBuilder`/animations; `DeferredRouteUIOptions` and `FluroConfig.deferredWrapperFor(path)` for global/per-path wiring; `registerDeferredLoader` / `preloadDeferredRoute` / `preloadAllDeferredRoutes` for preloading large deferred modules.

**中文**

- **禁用侧滑返回包装**：新增 `disableSwipeBack`（默认 `false`），可在 `FluroRouter.define`、`navigateTo`、`FluroConfig.push`、`matchRoute` 使用。为 `true` 时，`inFromLeft` / `fadeIn` / `none` 等预设转场不再包 `SwipeBackWrapper`。路由定义与单次跳转任一为 `true` 即禁用；守卫挂起/恢复通过 `PendingNavigation` 保留该参数。
- **Deferred 路由体验**：`DeferredRoutePage` 支持可选 `wrapper` 自定义 FutureBuilder/动画；`DeferredRouteUIOptions` 与 `FluroConfig.deferredWrapperFor(path)` 做全局/按路径配置；`registerDeferredLoader`、`preloadDeferredRoute`、`preloadAllDeferredRoutes` 用于大模块预加载。

---

## 1.3.1

**English**

- **Deferred Components**: Support `RouteLoadMode.deferred` in `@RouterAnnotation`. Generator emits `import ... deferred as ...`, `loadLibrary()`, and `DeferredRoutePage`. Optional `deferredGroup` and `deferredComponent` for grouping and Android deferred-components mapping.
- **Deferred UI config**: Global and per-path loading/error UI for deferred routes via `FluroConfig.deferredRouteUIOptions` and `FluroConfig.setDeferredBuildersForPath(path, loading: ..., error: ...)`. Generated code calls `FluroConfig.deferredLoadingBuilderFor(path)` and `FluroConfig.deferredErrorBuilderFor(path)` so custom builders apply when set.
- **Build config**: Optional `default_load_mode: eager|deferred` in builder `options` for global default.
- **Docs**: README/README_zh and example updated with full Deferred Components flow (Dart + Android `pubspec.yaml`), and FluroConfig deferred UI usage.

**中文**

- **Deferred Components**：`@RouterAnnotation` 支持 `RouteLoadMode.deferred`。生成器产出 `import ... deferred as ...`、`loadLibrary()` 与 `DeferredRoutePage`。可选 `deferredGroup`、`deferredComponent` 用于分组及 Android 动态组件映射。
- **Deferred 加载/失败 UI 配置**：通过 `FluroConfig.deferredRouteUIOptions` 设置全局默认，通过 `FluroConfig.setDeferredBuildersForPath(path, loading: ..., error: ...)` 按路径覆盖。生成代码会使用 `FluroConfig.deferredLoadingBuilderFor(path)` 与 `FluroConfig.deferredErrorBuilderFor(path)`，配置后即生效。
- **构建配置**：builder 的 `options` 支持 `default_load_mode: eager|deferred` 作为全局默认。
- **文档**：README/README_zh 与 example 补充完整 Deferred Components 流程（Dart + Android `pubspec.yaml`）及 FluroConfig deferred UI 用法。

---

## 1.2.0

**English**

- **Breaking**: Generated file suffix changed from `.g.dart` to `.router.g.dart` to avoid output collision with `source_gen:combining_builder` (e.g. when using json_serializable, freezed in the same project). Update your route entry to `export 'router_config.router.g.dart';` and run `dart run build_runner build --delete-conflicting-outputs`.

**中文**

- **破坏性变更**：生成文件后缀由 `.g.dart` 改为 `.router.g.dart`，避免与 `source_gen:combining_builder` 输出冲突（如项目内同时使用 json_serializable、freezed）。请将路由入口改为 `export 'router_config.router.g.dart';` 并执行 `dart run build_runner build --delete-conflicting-outputs`。

---

## 1.1.3

**English**

- **Route guard suspend**: Hang navigation with [Completer]; call [FluroConfig.resumePendingRoute] to continue (with correct return value) or [FluroConfig.clearPendingRoute] to end. Supports multiple guards and multiple suspend/resume rounds.
- **Fix**: `Future<dynamic>` is no longer cast to `Future<T?>`; use `.then<T?>((v) => v as T?)` so `push<T>` returns the correct type and avoids runtime cast errors.
- **Docs**: Removed business-specific wording from `lib/src` comments; kept only API/mechanism descriptions.

**中文**

- **路由守卫挂起**：使用 [Completer] 挂起本次跳转的 Future；通过 [FluroConfig.resumePendingRoute] 恢复（可正确带回返回值）或 [FluroConfig.clearPendingRoute] 结束。支持多守卫、多轮挂起/恢复。
- **修复**：不再将 `Future<dynamic>` 强转为 `Future<T?>`，改为 `.then<T?>((v) => v as T?)`，避免 `push<T>` 运行时类型转换错误。
- **文档**：去除 `lib/src` 中业务相关注释，仅保留 API/机制说明。

---

## 1.1.2

**English**

- **Pub & conventions**: CHANGELOG entries for 1.1.1 and 1.1.2; package ready for clean publish.
- **Static analysis**: Removed redundant package import in `lib/src/fluro_router.dart` (use relative import for `route_guard.dart`).
- **Dependencies**: Relaxed `analyzer` constraint to `>=8.0.0 <11.0.0` so the package supports current stable (e.g. 9.x, 10.x) and improves pub score.

**中文**

- **Pub 与规范**：补全 1.1.1、1.1.2 的 CHANGELOG，便于在干净 git 状态下发布。
- **静态分析**：移除 `lib/src/fluro_router.dart` 中多余包导入，改为相对导入 `route_guard.dart`。
- **依赖**：将 `analyzer` 约束放宽为 `>=8.0.0 <11.0.0`，支持当前稳定版（如 9.x、10.x），提升 pub 评分。

---

## 1.1.1

**English**

- Maintenance release; dependency and tooling updates.

**中文**

- 维护版本；依赖与工具链更新。

---

## 1.1.0

**English**

- **Route guards**: Run logic **before** `Navigator.push` to allow, redirect, or cancel navigation (unlike `NavigatorObserver`, which only runs after push/pop).
- **Guard API**: `FluroConfig.addGuard(guard)`, `insertGuard(index, guard)`, `removeGuard(guard)`, `clearGuards()`.
- **Guard result**: `GuardResult.allow`, `GuardResult.redirect(newPath)`, `GuardResult.cancel`; redirect is capped at 5 hops to avoid loops.
- **Context**: `RouteGuardContext` provides `path`, `context`, `replace`, `clearStack`, `routeMatch`, etc. for guard decisions.

**中文**

- **路由守卫**：在每次跳转**执行 [Navigator.push] 之前**执行守卫，可放行、重定向或取消（与仅能事后回调的 [NavigatorObserver] 互补）。
- **守卫 API**：`FluroConfig.addGuard(guard)`、`insertGuard(index, guard)`、`removeGuard(guard)`、`clearGuards()`。
- **守卫结果**：`GuardResult.allow`、`GuardResult.redirect(newPath)`、`GuardResult.cancel`；重定向最多 5 次以防死循环。
- **上下文**：`RouteGuardContext` 提供 `path`、`context`、`replace`、`clearStack`、`routeMatch` 等供守卫判断。

---

## 1.0.0

**English**

- Initial release.
- Fluro-based routing with annotations and code generation.
- Path params, query params, and `RouteSettings.arguments` support.
- Animated transitions and custom navigation.

**中文**

- 初始版本发布。
- 基于 Fluro 的注解 + 代码生成路由。
- 支持路径参数、查询参数、RouteSettings.arguments 传参。
- 支持动画转场与自定义导航。
