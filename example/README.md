# Example / 示例

**English** | [中文](#中文)

---

## English

Demo app for **fluro_router_generate**. It shows:

- Route entry with `@EntranceAnnotation` and `FluroConfig`
- Pages with `@RouterAnnotation`: no params, path params, query params, `RouteSettings.arguments`, and **deferred** (`loadMode: RouteLoadMode.deferred`) on the search page
- Optional `FluroConfig.deferredRouteUIOptions` / `setDeferredBuildersForPath` for custom loading/error UI (see commented block in `main.dart`)
- `build.yaml` with `generate_for.include` for the route entry only and optional `split_modules`
- Running `dart run build_runner build` and using `initAllHandlers()` in `main.dart`

Run the app and use the list to navigate between sample routes.

---

## 中文

**fluro_router_generate** 的示例工程，演示：

- 使用 `@EntranceAnnotation` 和 `FluroConfig` 的路由入口
- 使用 `@RouterAnnotation` 的页面：无参数、路径参数、查询参数、`RouteSettings.arguments`，以及搜索页的 **deferred**（`loadMode: RouteLoadMode.deferred`）
- 可选：`FluroConfig.deferredRouteUIOptions` / `setDeferredBuildersForPath` 自定义 Deferred 加载/失败 UI（见 `main.dart` 中注释块）
- 仅对路由入口配置 `generate_for.include` 的 `build.yaml`，以及可选的 `split_modules`
- 执行 `dart run build_runner build` 并在 `main.dart` 中调用 `initAllHandlers()`

运行应用后可通过列表跳转各示例路由。
