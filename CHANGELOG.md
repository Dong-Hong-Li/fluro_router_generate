# Changelog / 更新日志

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
