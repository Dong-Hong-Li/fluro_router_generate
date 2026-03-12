[English](https://github.com/Dong-Hong-Li/fluro_router_generate/blob/main/README.md) | **中文**

---

[![pub package](https://img.shields.io/pub/v/fluro_router_generate.svg)](https://pub.dev/packages/fluro_router_generate)
[![Dart CI](https://github.com/Dong-Hong-Li/fluro_router_generate/actions/workflows/dart.yml/badge.svg)](https://github.com/Dong-Hong-Li/fluro_router_generate/actions/workflows/release.yml)
[![License](https://img.shields.io/badge/license-Artistic%202.0-blue.svg)](https://github.com/Dong-Hong-Li/fluro_router_generate/blob/main/LICENSE)

# fluro_router_generate

**面向 Fluro 用户的代码生成路由层：类型安全参数、注解驱动、少写模板代码。**

继续用 [Fluro](https://github.com/lukepighetti/fluro)——同样的 `FluroRouter`、同样的转场——用 `@RouterAnnotation` 声明路由，自动生成 handler、路径/查询/arguments 的解析与注入，以及路由守卫、可选的延迟加载。不必再为每个页面手写 `define` + `FluroHandler`。

**仓库：** [GitHub](https://github.com/Dong-Hong-Li/fluro_router_generate)

---

## 和其他对比

| | **fluro** | **fluro_router_generate** | **go_router** | **auto_route** |
|---|:---:|:---:|:---:|:---:|
| 基础 | — | Fluro | Navigator 2.0 | Navigator 2.0 |
| 路由定义 | 手写 define + handler | **注解 + 代码生成** | 声明式配置 | 注解 + 代码生成 |
| 路径/查询/参数类型 | 手写 | **生成** | 有 | 有 |
| 模板代码量 | 多 | **少** | 少 | 少 |
| 从现有 Fluro 迁移 | — | **可渐进接入** | 需重写 | 需重写 |
| 延迟加载 | 手写 | **可生成** | 手写 | 支持 |

*当你已经在用（或打算用）Fluro，又希望少写重复代码、要类型安全时，用本库即可。*

---

## 快速接入（约 3 分钟）

**1. 加依赖**

```yaml
dependencies:
  fluro_router_generate: ^1.3.1  # 或 path: ../ 本地开发
dev_dependencies:
  build_runner: ^2.10.5
```

**2. 创建路由入口并配置 build.yaml**

在 `lib/router/router_config.dart`（或任意一个入口文件）里写：

```dart
import 'package:fluro_router_generate/fluro_router_generate.dart';
export 'router_config.router.g.dart';

@EntranceAnnotation()
class RouteConfig extends FluroConfig {
  RouteConfig._();
  static final RouteConfig instance = RouteConfig._();
}
```

项目**根目录**的 `build.yaml` 里**只**把该入口文件交给生成器（路径与上面一致）：

```yaml
targets:
  $default:
    builders:
      fluro_router_generate|router_library:
        generate_for:
          include:
            - lib/router/router_config.dart
```

**3. 给页面加注解**

```dart
@RouterAnnotation(path: '/detail/:id', defaultParams: {'id': '0'}, constructorParams: HandlerConstructorParams.pathParams)
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.id});
  final String id;
  // ... build
}
```

**4. 生成**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**5. 初始化一次，然后跳转**

```dart
// main.dart
RouteConfig.instance.initAllHandlers();
// MaterialApp
onGenerateRoute: FluroConfig.router.generator,

// 跳转
FluroConfig.push('/detail/99', context: context);
```

---

## 生成前 vs 生成后（为什么要用代码生成）

**生成前（纯 Fluro）：** 每个路由都要重复写 path、define、以及参数解析。

```dart
// 每个页面都要写：路径字符串、define 调用、手写参数解析
FluroConfig.router.define(
  '/detail/:id',
  handler: FluroHandler(
    handlerFunc: (context, parameters) {
      final id = parameters['id']?.first ?? '0';  // 手写字符串解析
      return DetailPage(id: id);
    },
  ),
);
// /user/:userId/post/:postId、/search?keyword=&page=1 等都要重复类似写法
```

**生成后（fluro_router_generate）：** 页面上一行注解，handler 和参数注入由生成器完成。

```dart
@RouterAnnotation(
  path: '/detail/:id',
  defaultParams: {'id': '0'},
  constructorParams: HandlerConstructorParams.pathParams,
)
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.id});
  final String id;
  // ...
}
// 生成：RouterHandler('/detail/:id', FluroHandler(handlerFunc: (c, p) => DetailPage(id: p['id']?.first ?? '0')))
```

*在此处加一张「生成前/生成后」截图或 GIF，会更容易让人一眼看懂价值。*

---

## 为什么要从 Fluro 迁过来？

**已经在用 Fluro，为什么还要接这个库？**

- **少写模板代码。** 不再需要为每条路由手写 `router.define(path, handler: FluroHandler(handlerFunc: ...))` 和 `parameters['x']?.first ?? default`。在页面上加一个 `@RouterAnnotation`，handler 和参数传递自动生成。十条路由就能少写几十行重复代码。
- **类型安全、单一数据源。** 路径/查询参数写在 widget 构造函数上，生成器读取后生成对应的 `HandlerFunc`。改构造函数后跑一遍 build_runner 即可，不用在 handler 里找字符串 key。
- **原版 Fluro 的痛点，我们补上了：**
  - **参数解析：** path/query/`RouteSettings.arguments` 都由生成代码处理，不用自己写 `parameters['id']?.first` 或从 `arguments` 强转。
  - **注册方式：** 不需要维护一份「路由列表」与页面同步；新增页面加注解再生成即可。
  - **守卫：** 内置 push 前守卫（放行/重定向/取消/挂起），做登录、付费墙不必只依赖 `NavigatorObserver`。
  - **延迟加载：** 可选的 `RouteLoadMode.deferred`，生成 `loadLibrary()` 与 `DeferredRoutePage`，懒加载模块不用手写异步 handler。

你还是用 Fluro 的 API 和语义，只是多了一层代码生成，维护和扩展都更轻松。

---

## 1. 给页面加注解

```dart
import 'package:flutter/material.dart';
import 'package:fluro_router_generate/fluro_router_generate.dart';

@RouterAnnotation(path: '/home/:id', description: '首页', defaultParams: {'id': '-'})
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('$id')), body: const SizedBox());
  }
}
```

---

## 2. 配置 build.yaml（必须）

**使用方项目**根目录必须有 `build.yaml`，且**仅**对带 `@EntranceAnnotation` 的入口文件触发生成：

```yaml
# 仅对路由入口触发生成，生成 lib/router/router_config.router.g.dart
targets:
  $default:
    builders:
      fluro_router_generate|router_library:
        generate_for:
          include:
            # 路径要和创建的路由入口一致
            # - lib/router/router_config.dart
```

- **未配置或未在 `include` 中指定入口文件时**：build_runner 默认会对**所有** `.dart` 触发生成器。对每个**非入口**文件（没有 `@EntranceAnnotation` 的），生成器会返回空内容，Builder 会**直接抛错**并提示配置 build.yaml，不会为该文件生成 `.router.g.dart`，整次 build 会失败。
- 因此必须在 `include` 里**只**写上路由入口文件（带 `@EntranceAnnotation` 的那个），否则会报错。
- 既没有在入口文件上加 `@EntranceAnnotation`，又未正确配置 build.yaml 时，运行 `build_runner` 也会报错。

---

## 3. 生成路由表

```bash
dart run build_runner build --delete-conflicting-outputs
```

会生成 `router_config.router.g.dart`，内含 `generatedHandlers` 和 `initAllHandlers()`。（`.router.g.dart` 后缀用于与 `source_gen:combining_builder` 的 `.g.dart` 区分，避免 output 冲突。）

---

## 4. 在 main 里初始化并使用

```dart
import 'package:fluro_router_generate/fluro_router_generate.dart';
import 'package:example/router/router_config.dart';

void main() {
  RouteConfig.instance.initAllHandlers();
  runApp(const MyApp());
}

// MaterialApp
onGenerateRoute: FluroConfig.router.generator,

// 跳转
FluroConfig.router.navigateTo(context, '/home/1');
```

---

## 5. 路由守卫（可选）

守卫在每次**执行 [Navigator.push] 之前**运行，可放行、重定向、取消或**挂起**本次跳转，与仅能事后回调的 [NavigatorObserver] 互补。

**守卫返回值**

| 返回值 | 说明 |
|--------|------|
| `GuardResult.allow` | 继续本次跳转。 |
| `GuardResult.redirect(newPath)` | 改为跳转到 `newPath`（会再次经过守卫）。最多 5 次以防死循环。 |
| `GuardResult.cancel` | 取消本次跳转；调用方 `await push` 得到 `null`。 |
| `GuardResult.suspend` | **挂起**本次跳转（`push` 的 Future 暂不结束）。先执行自定义流程（如打开其他页），满足条件后调用 `resumePendingRoute(context)` 继续到原目标，或调用 `clearPendingRoute()` 结束挂起（调用方得到 `null`）。恢复后的跳转仍会经过守卫；目标页的返回值会传回最初的 `await push<T>`。 |

**API**

| API | 说明 |
|-----|------|
| `addGuard(guard)` | 追加守卫，按注册顺序执行。 |
| `hasPendingRoute` | 当前是否存在被挂起的跳转。 |
| `resumePendingRoute<T>(context)` | 继续执行被挂起的跳转；无挂起则 no-op。执行后自动清除挂起状态。 |
| `clearPendingRoute()` | 结束挂起（调用方 Future 以 `null` 完成）。 |

**示例：allow / redirect / suspend**

```dart
import 'package:fluro_router_generate/fluro_router.dart';

FluroConfig.addGuard((ctx) async {
  if (ctx.path.startsWith('/admin') && !hasAccess()) {
    return GuardResult.redirect('/welcome');  // 替换路径
  }
  return GuardResult.allow;
});

// 挂起：先不跳转，执行自定义流程后再恢复或清除
FluroConfig.addGuard((ctx) async {
  if (ctx.path == '/premium' && !isUnlocked()) {
    // 例如先打开付费页，成功后：FluroConfig.resumePendingRoute(context);
    // 取消时：FluroConfig.clearPendingRoute();
    return GuardResult.suspend;
  }
  return GuardResult.allow;
});
```

---

## 注解说明

| 字段 | 说明 |
|------|------|
| `path` | 路由路径，支持 `/home/:id`、`/search?keyword=` 等 |
| `description` | 可选，生成列表中的注释 |
| `defaultParams` | 可选，参数默认值，如 `{'id': '-', 'page': 1}` |
| `constructorParams` | 可选，`pathParams` / `queryParams` / `routeSettingsArguments` / `none`，决定参数如何传入构造函数 |
| `module` | 可选，模块名，用于分文件生成与分组；配合 build.yaml 的 `split_modules` 可拆成独立 `.router.g.dart` |
| `loadMode` | 可选：`RouteLoadMode.eager`（默认）/ `RouteLoadMode.deferred` |
| `deferredGroup` | 可选，deferred import 的稳定分组前缀 |
| `deferredComponent` | 可选，用于 Android deferred components 的组件名映射提示 |

更多用法见 `example/`。

---

## 案例

### 1. 传参类型案例

| 场景 | path 示例 | constructorParams | 说明 |
|------|-----------|-------------------|------|
| 无参数 | `/home` | `none` | 不传参 |
| 单路径参数 | `/detail/:id` | `pathParams` | 匹配 `/detail/99`，参数 `id` |
| 多路径参数 | `/user/:userId/post/:postId` | `pathParams` | 匹配 `/user/1/post/2`，参数 `userId`、`postId` |
| 查询参数 | `/search?keyword=&page=1` | `queryParams` | 匹配 `/search?keyword=test&page=2`，参数从 query 解析 |
| routeSettings 有 defaultParams | `/pass-args` | `routeSettingsArguments` + `defaultParams: {'title': '默认', 'count': 0}` | 通过 `RouteSettings.arguments` 传参，未传时用默认值 |
| routeSettings 无 defaultParams | `/pass-args-no-defaults` | `routeSettingsArguments`（不写 defaultParams） | 参数名从构造函数推断，适合临时传参 |

**无参数：**

```dart
@RouterAnnotation(path: '/home', constructorParams: HandlerConstructorParams.none)
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  // ...
}
```

**单路径参数：**

```dart
@RouterAnnotation(
  path: '/detail/:id',
  defaultParams: {'id': '0'},
  constructorParams: HandlerConstructorParams.pathParams,
)
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.id});
  final String id;
  // ...
}
```

**多路径参数：**

```dart
@RouterAnnotation(
  path: '/user/:userId/post/:postId',
  defaultParams: {'userId': '0', 'postId': '0'},
  constructorParams: HandlerConstructorParams.pathParams,
)
class PostPage extends StatelessWidget {
  const PostPage({super.key, required this.userId, required this.postId});
  final String userId;
  final String postId;
  // ...
}
```

**查询参数：**

```dart
@RouterAnnotation(
  path: '/search?keyword=&page=1',
  defaultParams: {'keyword': '', 'page': '1'},
  constructorParams: HandlerConstructorParams.queryParams,
)
class SearchPage extends StatelessWidget {
  const SearchPage({super.key, required this.keyword, required this.page});
  final String keyword;
  final String page;
  // ...
}
```

**routeSettings.arguments 传参（有 defaultParams）：**

```dart
@RouterAnnotation(
  path: '/pass-args',
  defaultParams: {'title': '默认标题', 'count': 0},
  constructorParams: HandlerConstructorParams.routeSettingsArguments,
)
class PassArgsPage extends StatelessWidget {
  const PassArgsPage({super.key, required this.title, required this.count});
  final String title;
  final int count;
  // ...
}
```

### 2. 跳转与传参案例

```dart
// 无参数
FluroConfig.push('/home', context: context);

// 路径参数
FluroConfig.push('/detail/99', context: context);
FluroConfig.push('/user/1/post/2', context: context);

// 查询参数
FluroConfig.push('/search?keyword=test&page=1', context: context);

// routeSettings.arguments
FluroConfig.push(
  '/pass-args',
  context: context,
  routeSettings: RouteSettings(
    name: '/pass-args',
    arguments: {'title': '传入标题', 'count': 42},
  ),
);
```

### 3. 分文件与 module、split_modules 案例

页面注解里加 `module`，同名模块会生成到同一块（或同一文件）：

```dart
@RouterAnnotation(
  path: '/home',
  module: 'main',
  constructorParams: HandlerConstructorParams.none,
)
class HomePage extends StatelessWidget { ... }

@RouterAnnotation(
  path: '/payment/:orderId',
  module: 'payment',
  defaultParams: {'orderId': ''},
  constructorParams: HandlerConstructorParams.pathParams,
)
class PaymentPage extends StatelessWidget { ... }
```

若希望 `payment` 模块拆成独立文件 `router_config_payment.router.g.dart`，在**项目根目录** `build.yaml` 里为该 builder 增加 `split_modules`：

```yaml
targets:
  $default:
    builders:
      fluro_router_generate|router_library:
        generate_for:
          include:
            - lib/router/router_config.dart
        options:
          split_modules:
            - payment
            - admin
```

未在 `split_modules`（及默认列表）中的 `module` 会合并到主文件内联，不会单独成文件。完整示例见 `example/`。

---

### 4. Deferred 路由加载

在页面注解上使用 `RouteLoadMode.deferred`，生成器会产出 `deferred import` 和运行时 `loadLibrary()`：

```dart
@RouterAnnotation(
  path: '/search?keyword=&page=1',
  module: 'feature',
  constructorParams: HandlerConstructorParams.queryParams,
  loadMode: RouteLoadMode.deferred,
  deferredGroup: 'search_feature',
  deferredComponent: 'search_component',
)
class SearchPage extends StatelessWidget { ... }
```

生成代码会使用 `DeferredRoutePage` 包装异步加载流程，从而保持 `FluroHandler` 仍是同步签名。

也可以在 `build.yaml` 里配置全局默认值：

```yaml
targets:
  $default:
    builders:
      fluro_router_generate|router_library:
        options:
          default_load_mode: eager # eager|deferred
```

**自定义 Deferred 加载/失败 UI（可选）**  
生成代码会使用 `FluroConfig.deferredLoadingBuilderFor(path)` 与 `FluroConfig.deferredErrorBuilderFor(path)`。在调用 `initAllHandlers()` 前设置即可生效：

- **全局默认**：`FluroConfig.deferredRouteUIOptions = DeferredRouteUIOptions(loadingBuilder: ..., errorBuilder: ...);`
- **单路径覆盖**：`FluroConfig.setDeferredBuildersForPath('/search?keyword=&page=1', loading: ..., error: ...);`

未设置时使用 `DeferredRoutePage` 内置的 loading/错误页。

> 注意：上面只是 **Dart 层 deferred import**。如果你要做 Android App Bundle 的 **Deferred Components（动态下发模块）**，还要配应用工程。

#### 完整案例：Dart deferred + Android Deferred Components

**步骤 1：页面注解（代码层）**

```dart
@RouterAnnotation(
  path: '/search?keyword=&page=1',
  module: 'feature',
  constructorParams: HandlerConstructorParams.queryParams,
  loadMode: RouteLoadMode.deferred,
  deferredGroup: 'search_feature',
  deferredComponent: 'search_component', // 对应 Android 动态模块名
)
class SearchPage extends StatelessWidget {
  const SearchPage({super.key, required this.keyword, required this.page});
  final String keyword;
  final String page;
  // ...
}
```

**步骤 2：生成路由代码**

```bash
dart run build_runner build --delete-conflicting-outputs
```

生成后会看到类似代码（示意）：

```dart
import 'package:example/pages/search_page.dart' deferred as deferred_search_feature_xxx;

RouterHandler(
  '/search?keyword=&page=1',
  FluroHandler(
    handlerFunc: (context, parameters) => DeferredRoutePage(
      loader: () => deferred_search_feature_xxx.loadLibrary(),
      builder: (context) => deferred_search_feature_xxx.SearchPage(...),
      debugLabel: '/search?keyword=&page=1',
      loadingBuilder: FluroConfig.deferredLoadingBuilderFor('/search?keyword=&page=1'),
      errorBuilder: FluroConfig.deferredErrorBuilderFor('/search?keyword=&page=1'),
    ),
  ),
),
```

**步骤 3：应用侧 `pubspec.yaml`（平台层）**

在使用方 App 的 `pubspec.yaml` 中声明 deferred component（示例）：

```yaml
flutter:
  deferred-components:
    - name: search_component
      libraries:
        - package:example/pages/search_page.dart
      # 可选：该组件专属资源
      # assets:
      #   - assets/search/**
```

`name` 要和注解里的 `deferredComponent` 一致（例如都叫 `search_component`）。

**步骤 4：打包与验证**

- 本地 debug / profile：通常只验证 Dart deferred 路径（`loadLibrary()` + `DeferredRoutePage`）。
- 真实 Deferred Components：用 Android App Bundle 流程验证（Play 动态下发场景）。

**步骤 5：建议的回归点**

- 首次进入 deferred 路由，出现 loading，再进入目标页。
- 二次进入同一路由，不再重复下载/初始化模块（由平台和运行时缓存决定）。
- 与守卫、`split_modules`、`routeSettingsArguments` 同时使用时行为正常。

#### 常见误区

- `loadMode: deferred` **不等于** 自动完成 Android 动态模块配置。
- `deferredComponent` 目前是“映射声明字段”，用于标注组件归属；是否真正动态下发，取决于 App 工程配置和打包方式。

#### 加载时机与大模块（直播、音视频剪辑等）

- **何时执行 loadLibrary？** 同进程内**第一次进入该路由时**执行；之后同进程再进该路由不会重复加载。**新打开 APP（新进程）后，第一次进入该路由时**会再执行一次。若用户从不点进该页，则不会加载。
- **模块很大怎么办？**
  1. **预加载**：在首页就绪或进入相关入口（如「发现」）时调用 `FluroConfig.registerDeferredLoader(path, () => your_deferred.loadLibrary())` 注册，再在合适时机调用 `FluroConfig.preloadDeferredRoute(path)`，用户真正点进该路由时通常已加载完。
  2. **用 wrapper** 做明显 loading、进度或「首次约 xx MB」提示，必要时支持取消。
  3. **业务再拆库**：直播、剪辑拆成不同 deferred 库，按需分别加载。
  4. **真正动态下发**：若“大”指下载体积，需用 Android Deferred Components + Play 按需下载，安装后再 loadLibrary。

**预加载用法示例：**

```dart
// 1）在合适处 import 同一 deferred 库并注册（path 与注解一致）
import 'package:your_app/pages/live_page.dart' deferred as live_lib;

FluroConfig.registerDeferredLoader('/live', () => live_lib.loadLibrary());

// 2）在首页渲染完成或用户进入发现页时预加载
FluroConfig.preloadDeferredRoute('/live');
// 或预加载所有已注册的：FluroConfig.preloadAllDeferredRoutes();
```

---

## 常见问题

### build_runner 报错：Builders source_gen:combining_builder 和 fluro_router_generate:router_library outputs collide

- **原因**：两个 builder 都声明对同一输入输出 `.g.dart`，当路由入口文件同时被两者处理时会争写同一文件。
- **解决**：本包已改为输出 `.router.g.dart`，与 source_gen 的 `.g.dart` 区分。请升级到最新版本，将入口文件中的 `export 'router_config.g.dart';` 改为 `export 'router_config.router.g.dart';`，然后执行 `dart run build_runner build --delete-conflicting-outputs`。

### defaultParams 和构造函数，对参数名称哪个优先级高？

- **参数名单与默认值**：由 **defaultParams** 决定。只有未写 `defaultParams`（或写空 `{}`）时，才用**构造函数**推断参数名。
- **参数类型**：名单确定后，类型始终从**构造函数**读取。
- 因此：**defaultParams 优先级更高**（决定传哪几个参数、默认值）；构造函数用于在未写 defaultParams 时补全名单，并始终提供类型。

### 构造函数类型是 A，但 defaultParams 里写的是类型 B，以谁为准？

- **类型以构造函数类型 A 为准**；defaultParams 的字面类型 B 只影响默认值，不改变「按什么类型解析」。
- 若 A 是对象类型，生成代码一定是 `argsMap?['key'] as A`，不会用 B 做 int/double 等解析。
- 结论：**构造函数类型 A 优先级更高**；defaultParams 的类型 B 不会覆盖 A,但这本质是错误的写法,默认值的类型应该参考**构造函数**参数。
