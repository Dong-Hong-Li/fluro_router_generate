# fluro_router_generate

基于 Fluro 的路由库，通过注解 + 代码生成自动注册路由并支持路径参数、查询参数、RouteSettings.arguments 传参。

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

## 注解说明

| 字段 | 说明 |
|------|------|
| `path` | 路由路径，支持 `/home/:id`、`/search?keyword=` 等 |
| `description` | 可选，生成列表中的注释 |
| `defaultParams` | 可选，参数默认值，如 `{'id': '-', 'page': 1}` |
| `constructorParams` | 可选，`pathParams` / `queryParams` / `routeSettingsArguments` / `none`，决定参数如何传入构造函数 |

更多用法见 `example/`。
