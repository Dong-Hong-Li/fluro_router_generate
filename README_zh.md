[English](README.md) | **中文**

---

# fluro_router_generate

基于 Fluro 的路由库，通过**注解 + 代码生成**自动注册路由，支持路径参数、查询参数、RouteSettings.arguments 传参，支持动画转场与自定义导航。

---

## 1. 依赖

```yaml
dependencies:
  fluro_router_generate:
    path: ../  # 或 pub.dev 版本

dev_dependencies:
  build_runner: ^2.10.5
```

---

## 2. 创建路由入口

在 `lib/xxxx.dart` 中：

```dart
import 'package:fluro_router_generate/fluro_router_generate.dart';
export 'router_config.g.dart';

@EntranceAnnotation()
class RouteConfig extends FluroConfig {
  RouteConfig._();
  static final RouteConfig instance = RouteConfig._();
}
```

---

## 3. 给页面加注解

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

## 4. 配置 build.yaml（必须）

**使用方项目**根目录必须有 `build.yaml`，且**仅**对带 `@EntranceAnnotation` 的入口文件触发生成：

```yaml
# 仅对路由入口触发生成，生成 lib/router/router_config.g.dart
targets:
  $default:
    builders:
      fluro_router_generate|router_library:
        generate_for:
          include:
            # 路径要和创建的路由入口一致
            # - lib/router/router_config.dart
```

- **未配置或未在 `include` 中指定入口文件时**：build_runner 默认会对**所有** `.dart` 触发生成器。对每个**非入口**文件（没有 `@EntranceAnnotation` 的），生成器会返回空内容，Builder 会**直接抛错**并提示配置 build.yaml，不会为该文件生成 `.g.dart`，整次 build 会失败。
- 因此必须在 `include` 里**只**写上路由入口文件（带 `@EntranceAnnotation` 的那个），否则会报错。
- 既没有在入口文件上加 `@EntranceAnnotation`，又未正确配置 build.yaml 时，运行 `build_runner` 也会报错。

---

## 5. 生成路由表

```bash
dart run build_runner build --delete-conflicting-outputs
```

会生成 `router_config.g.dart`，内含 `generatedHandlers` 和 `initAllHandlers()`。

---

## 6. 在 main 里初始化并使用

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

## 7. 路由守卫（可选）

守卫在每次**执行 [Navigator.push] 之前**运行，可放行、重定向或取消本次跳转，与仅能事后回调的 [NavigatorObserver] 互补。

```dart
import 'package:fluro_router_generate/fluro_router.dart';

// 例如：未登录访问 /admin 时重定向到登录页
FluroConfig.addGuard((ctx) async {
  if (ctx.path.startsWith('/admin') && !isLoggedIn()) {
    return GuardResult.redirect('/login');
  }
  return GuardResult.allow;
});

// 需要时移除或清空
FluroConfig.removeGuard(myGuard);
FluroConfig.clearGuards();
```

| API | 说明 |
|-----|------|
| `addGuard(guard)` | 追加守卫，按注册顺序执行。 |
| `insertGuard(index, guard)` | 在指定索引插入守卫。 |
| `removeGuard(guard)` | 按引用移除第一个匹配的守卫。 |
| `clearGuards()` | 清空所有守卫。 |

守卫返回值：`GuardResult.allow`、`GuardResult.redirect(newPath)`、`GuardResult.cancel`。重定向最多 5 次以防死循环。

---

## 注解说明

| 字段 | 说明 |
|------|------|
| `path` | 路由路径，支持 `/home/:id`、`/search?keyword=` 等 |
| `description` | 可选，生成列表中的注释 |
| `defaultParams` | 可选，参数默认值，如 `{'id': '-', 'page': 1}` |
| `constructorParams` | 可选，`pathParams` / `queryParams` / `routeSettingsArguments` / `none`，决定参数如何传入构造函数 |
| `module` | 可选，模块名，用于分文件生成与分组；配合 build.yaml 的 `split_modules` 可拆成独立 `.g.dart` |

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

若希望 `payment` 模块拆成独立文件 `router_config_payment.g.dart`，在**项目根目录** `build.yaml` 里为该 builder 增加 `split_modules`：

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

## 常见问题

### defaultParams 和构造函数，对参数名称哪个优先级高？

- **参数名单与默认值**：由 **defaultParams** 决定。只有未写 `defaultParams`（或写空 `{}`）时，才用**构造函数**推断参数名。
- **参数类型**：名单确定后，类型始终从**构造函数**读取。
- 因此：**defaultParams 优先级更高**（决定传哪几个参数、默认值）；构造函数用于在未写 defaultParams 时补全名单，并始终提供类型。

### 构造函数类型是 A，但 defaultParams 里写的是类型 B，以谁为准？

- **类型以构造函数类型 A 为准**；defaultParams 的字面类型 B 只影响默认值，不改变「按什么类型解析」。
- 若 A 是对象类型，生成代码一定是 `argsMap?['key'] as A`，不会用 B 做 int/double 等解析。
- 结论：**构造函数类型 A 优先级更高**；defaultParams 的类型 B 不会覆盖 A,但这本质是错误的写法,默认值的类型应该参考**构造函数**参数。
