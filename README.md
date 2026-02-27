[中文](https://github.com/Dong-Hong-Li/fluro_router_generate/blob/main/README_zh.md) | **English**

---

[![pub package](https://img.shields.io/pub/v/fluro_router_generate.svg)](https://pub.dev/packages/fluro_router_generate)
[![License](https://img.shields.io/badge/license-Artistic%202.0-blue.svg)](LICENSE)

# fluro_router_generate

Fluro-based routing for Flutter with **annotations and code generation**.  
Register routes automatically via `@RouterAnnotation`, with path params, query params, and `RouteSettings.arguments`. Supports animated transitions and custom navigation.

**Repositories (same project, two remotes):**  
- **GitHub:** [github.com/Dong-Hong-Li/fluro_router_generate](https://github.com/Dong-Hong-Li/fluro_router_generate) — `git clone https://github.com/Dong-Hong-Li/fluro_router_generate.git`  
- **Gitee:** [gitee.com/lidonghonglalala/fluro_router_generate](https://gitee.com/lidonghonglalala/fluro_router_generate) — `git clone https://gitee.com/lidonghonglalala/fluro_router_generate.git`

---

## 1. Dependencies

```yaml
dependencies:
  fluro_router_generate: ^1.1.2  # or path: ../ for local

dev_dependencies:
  build_runner: ^2.10.5
```

---

## 2. Create route entry

In `lib/xxxx.dart`:

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

## 3. Annotate your pages

```dart
import 'package:flutter/material.dart';
import 'package:fluro_router_generate/fluro_router_generate.dart';

@RouterAnnotation(path: '/home/:id', description: 'Home', defaultParams: {'id': '-'})
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

## 4. Configure build.yaml (required)

Your **app project** must have a root `build.yaml`, and **only** the file with `@EntranceAnnotation` may trigger the builder:

```yaml
# Only the route entry file triggers generation, e.g. lib/router/router_config.g.dart
targets:
  $default:
    builders:
      fluro_router_generate|router_library:
        generate_for:
          include:
            # Path must match your route entry file
            # - lib/router/router_config.dart
```

- **If you don’t set this or omit the entry from `include`**: build_runner will run the builder on **all** `.dart` files. For any file **without** `@EntranceAnnotation`, the builder returns empty output and **fails** with a message to configure build.yaml. The whole build will fail.
- So you **must** list **only** the route entry file (the one with `@EntranceAnnotation`) in `include`.
- If the entry file has no `@EntranceAnnotation` or build.yaml is wrong, `build_runner` will also fail.

---

## 5. Generate route table

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `router_config.g.dart` with `generatedHandlers` and `initAllHandlers()`.

---

## 6. Initialize in main and use

```dart
import 'package:fluro_router_generate/fluro_router_generate.dart';
import 'package:example/router/router_config.dart';

void main() {
  RouteConfig.instance.initAllHandlers();
  runApp(const MyApp());
}

// MaterialApp
onGenerateRoute: FluroConfig.router.generator,

// Navigate
FluroConfig.router.navigateTo(context, '/home/1');
```

---

## 7. Route guards (optional)

Guards run **before** each `Navigator.push`, so you can allow, redirect, or cancel navigation. This is different from `NavigatorObserver`, which only runs after push/pop.

```dart
import 'package:fluro_router_generate/fluro_router.dart';

// e.g. redirect to login when visiting /admin without auth
FluroConfig.addGuard((ctx) async {
  if (ctx.path.startsWith('/admin') && !isLoggedIn()) {
    return GuardResult.redirect('/login');
  }
  return GuardResult.allow;
});

// Remove or clear when needed
FluroConfig.removeGuard(myGuard);
FluroConfig.clearGuards();
```

| API | Description |
|-----|-------------|
| `addGuard(guard)` | Append a guard (runs in order). |
| `insertGuard(index, guard)` | Insert at index. |
| `removeGuard(guard)` | Remove first matching guard by reference. |
| `clearGuards()` | Remove all guards. |

Guard returns: `GuardResult.allow`, `GuardResult.redirect(newPath)`, `GuardResult.cancel`. Redirect is limited to 5 hops to avoid loops.

---

## Annotation reference

| Field | Description |
|-------|-------------|
| `path` | Route path, e.g. `/home/:id`, `/search?keyword=` |
| `description` | Optional, comment in generated list |
| `defaultParams` | Optional, default values, e.g. `{'id': '-', 'page': 1}` |
| `constructorParams` | Optional: `pathParams` / `queryParams` / `routeSettingsArguments` / `none` — how params are passed to the constructor |
| `module` | Optional, module name for grouping/splitting; with build.yaml `split_modules` can emit a separate `.g.dart` |

See `example/` for more.

---

## Examples

### 1. Parameter types

| Scenario | path example | constructorParams | Notes |
|----------|---------------|-------------------|-------|
| No params | `/home` | `none` | No arguments |
| Single path param | `/detail/:id` | `pathParams` | Matches `/detail/99`, param `id` |
| Multiple path params | `/user/:userId/post/:postId` | `pathParams` | Matches `/user/1/post/2`, params `userId`, `postId` |
| Query params | `/search?keyword=&page=1` | `queryParams` | Params from query string |
| routeSettings with defaultParams | `/pass-args` | `routeSettingsArguments` + `defaultParams: {'title': 'Default', 'count': 0}` | Via `RouteSettings.arguments`, fallback to defaults |
| routeSettings without defaultParams | `/pass-args-no-defaults` | `routeSettingsArguments` (no defaultParams) | Param names from constructor, for ad-hoc args |

**No params:**

```dart
@RouterAnnotation(path: '/home', constructorParams: HandlerConstructorParams.none)
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  // ...
}
```

**Single path param:**

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

**Multiple path params:**

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

**Query params:**

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

**routeSettings.arguments (with defaultParams):**

```dart
@RouterAnnotation(
  path: '/pass-args',
  defaultParams: {'title': 'Default title', 'count': 0},
  constructorParams: HandlerConstructorParams.routeSettingsArguments,
)
class PassArgsPage extends StatelessWidget {
  const PassArgsPage({super.key, required this.title, required this.count});
  final String title;
  final int count;
  // ...
}
```

### 2. Navigation and passing arguments

```dart
// No params
FluroConfig.push('/home', context: context);

// Path params
FluroConfig.push('/detail/99', context: context);
FluroConfig.push('/user/1/post/2', context: context);

// Query params
FluroConfig.push('/search?keyword=test&page=1', context: context);

// routeSettings.arguments
FluroConfig.push(
  '/pass-args',
  context: context,
  routeSettings: RouteSettings(
    name: '/pass-args',
    arguments: {'title': 'My title', 'count': 42},
  ),
);
```

### 3. Modules and split_modules

Add `module` to annotations; same module name is grouped (or written to a separate file):

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

To emit a separate file e.g. `router_config_payment.g.dart` for the `payment` module, add `split_modules` in your **project root** `build.yaml`:

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

Modules not in `split_modules` are inlined into the main generated file. See `example/` for a full sample.

---

## FAQ

### defaultParams vs constructor: which decides parameter names?

- **Parameter set and defaults**: **defaultParams** wins. Only when `defaultParams` is omitted (or `{}`) are names inferred from the **constructor**.
- **Types**: After the set is fixed, types always come from the **constructor**.
- So **defaultParams** has priority for which params and defaults; the constructor is used when defaultParams is missing and always for types.

### Constructor type is A, defaultParams value looks like type B. Which type is used?

- **Type follows the constructor type A**. The literal in defaultParams (B) only affects the default value, not how the value is parsed.
- If A is an object type, generated code uses `argsMap?['key'] as A`, not B for int/double etc.
- **Conclusion**: Constructor type **A** wins; defaultParams’ type B does not override A.

---

## Troubleshooting

| Issue | What to check |
|-------|----------------|
| **build_runner fails** with a message about build.yaml | Ensure the **only** file in `generate_for.include` is your route entry file (the one with `@EntranceAnnotation`). Do not include every `.dart` file. |
| **Route not found** at runtime | Call `RouteConfig.instance.initAllHandlers()` before `runApp()`, and use `onGenerateRoute: FluroConfig.router.generator` in `MaterialApp`. |
| **Wrong or missing params** on the page | Match `constructorParams` to how you pass data: `pathParams` for `/path/:id`, `queryParams` for `?key=`, `routeSettingsArguments` for `RouteSettings.arguments`. Use `defaultParams` when you need defaults. |
| **Generated file is empty or outdated** | Run `dart run build_runner build --delete-conflicting-outputs` again; ensure the entry file is the one listed in build.yaml and has `@EntranceAnnotation()`. |
