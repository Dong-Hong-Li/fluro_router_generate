# Changelog / 更新日志

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
