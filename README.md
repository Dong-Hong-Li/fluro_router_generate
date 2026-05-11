[中文](https://github.com/Dong-Hong-Li/fluro_router_generate/blob/main/README_zh.md) | **English**

---

[![pub package](https://img.shields.io/pub/v/fluro_router_generate.svg)](https://pub.dev/packages/fluro_router_generate)
[![License](https://img.shields.io/badge/license-Artistic%202.0-blue.svg)](https://github.com/Dong-Hong-Li/fluro_router_generate/blob/main/LICENSE)

# fluro_router_generate

**A code-generation router layer for Fluro users who want typed params, annotations, and less boilerplate.**

You stay on [Fluro](https://github.com/lukepighetti/fluro)—same `FluroRouter`, same transitions—but define routes with `@RouterAnnotation` and get generated handlers, typed path/query/arguments, route guards, and optional deferred loading. No need to hand-write `define` + `FluroHandler` for every screen.

**Repositories:** [GitHub](https://github.com/Dong-Hong-Li/fluro_router_generate) ·
---

## In comparison with others

| | **fluro** | **fluro_router_generate** | **go_router** | **auto_route** |
|---|:---:|:---:|:---:|:---:|
| Built on | — | Fluro | Navigator 2.0 | Navigator 2.0 |
| Route definition | Manual `define` + handler | **Annotations + code gen** | Declarative config | Annotations + code gen |
| Typed path/query/args | Hand-written | **Generated** | Yes | Yes |
| Boilerplate | High | **Low** | Low | Low |
| Migrate from existing Fluro | — | **Drop-in layer** | Rewrite | Rewrite |
| Deferred loading | Manual | **Generated** | Manual | Supported |

*Use this library when you already use (or want) Fluro and need less manual wiring and better type safety.*

---

## Quick start (~3 minutes)

**1. Add dependency**

```yaml
dependencies:
  fluro_router_generate: ^1.4.1  # or path: ../ for local
dev_dependencies:
  build_runner: ^2.10.5
```

**2. Create route entry and configure build.yaml**

In `lib/router/router_config.dart` (or your chosen entry file):

```dart
import 'package:fluro_router_generate/fluro_router_generate.dart';
export 'router_config.router.g.dart';

@EntranceAnnotation()
class RouteConfig extends FluroConfig {
  RouteConfig._();
  static final RouteConfig instance = RouteConfig._();
}
```

In the project **root** `build.yaml`, have the builder **only** process that entry file (path must match):

```yaml
targets:
  $default:
    builders:
      fluro_router_generate|router_library:
        generate_for:
          include:
            - lib/router/router_config.dart
```

**3. Annotate a page**

```dart
@RouterAnnotation(path: '/detail/:id', defaultParams: {'id': '0'}, constructorParams: HandlerConstructorParams.pathParams)
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.id});
  final String id;
  // ... build
}
```

**4. Generate**

```bash
dart run build_runner build --delete-conflicting-outputs
```

**5. Wire once and navigate**

```dart
// main.dart
RouteConfig.instance.initAllHandlers();
// MaterialApp
onGenerateRoute: FluroConfig.router.generator,

// Navigate
FluroConfig.push('/detail/99', context: context);
```

---

## Before vs after (why use code gen)

**Before (plain Fluro):** you repeat path, handler, and parameter parsing for every route.

```dart
// Repeated for every screen: path string, define call, and manual param parsing
FluroConfig.router.define(
  '/detail/:id',
  handler: FluroHandler(
    handlerFunc: (context, parameters) {
      final id = parameters['id']?.first ?? '0';  // string parsing by hand
      return DetailPage(id: id);
    },
  ),
);
// Same pattern for /user/:userId/post/:postId, /search?keyword=&page=1, ...
```

**After (fluro_router_generate):** one annotation on the page; handler and param wiring are generated.

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
// Generated: RouterHandler('/detail/:id', FluroHandler(handlerFunc: (c, p) => DetailPage(id: p['id']?.first ?? '0')))
```

*Adding a “before/after” screenshot or GIF at this spot will make the value even clearer.*

---

## Why migrate from Fluro?

**If you're already using Fluro, why add this?**

- **Less boilerplate.** Every route no longer needs a manual `router.define(path, handler: FluroHandler(handlerFunc: ...))` and hand-written `parameters['x']?.first ?? default`. One `@RouterAnnotation` on the page generates the handler and param passing. For 10 routes you delete dozens of lines of repetitive code.
- **Typed params and single source of truth.** Path and query params live on the widget constructor; the generator reads them and generates the correct `HandlerFunc`. Change the constructor and re-run build_runner—no hunting for string keys in handler lambdas.
- **Pain points of raw Fluro we address:**
  - **Param parsing:** path/query/`RouteSettings.arguments` are generated; you don’t write `parameters['id']?.first` or cast from `arguments` yourself.
  - **Registration:** no central “route list” to keep in sync with your pages; add a page + annotation and regenerate.
  - **Guards:** pre-push guards (allow/redirect/cancel/suspend) are built in, so you can do auth or paywall without only relying on `NavigatorObserver`.
  - **Deferred loading:** optional `RouteLoadMode.deferred` with generated `loadLibrary()` and `DeferredRoutePage`, so you can lazy-load features without hand-rolling async handlers.

You keep Fluro’s API and behavior; you add a code-gen layer that makes it easier to maintain and extend.

---

## 1. Annotate your pages

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

## 2. Configure build.yaml (required)

Your **app project** must have a root `build.yaml`, and **only** the file with `@EntranceAnnotation` may trigger the builder:

```yaml
# Only the route entry file triggers generation, e.g. lib/router/router_config.router.g.dart
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

## 3. Generate route table

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `router_config.router.g.dart` with `generatedHandlers` and `initAllHandlers()`. (The `.router.g.dart` suffix avoids output collision with `source_gen:combining_builder`.)

---

## 4. Initialize in main and use

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

## 5. Route guards (optional)

Guards run **before** each `Navigator.push`, so you can allow, redirect, cancel, or **suspend** navigation. This is different from `NavigatorObserver`, which only runs after push/pop.

**Guard results**

| Result | Description |
|--------|-------------|
| `GuardResult.allow` | Continue with the current navigation. |
| `GuardResult.redirect(newPath)` | Navigate to `newPath` instead (re-runs guards). Limited to 5 hops. |
| `GuardResult.cancel` | Abort this navigation; caller's `await push` resolves to `null`. |
| `GuardResult.suspend` | Pause this navigation (the `push` Future is held). Run your own flow (e.g. another screen), then call `resumePendingRoute(context)` to continue to the original target, or `clearPendingRoute()` to end the pause (caller gets `null`). The resumed navigation still goes through guards; return value from the target page is passed back to the original `await push<T>`. |

**APIs**

| API | Description |
|-----|-------------|
| `addGuard(guard)` | Append a guard (runs in order). |
| `hasPendingRoute` | Whether a navigation is currently suspended. |
| `resumePendingRoute<T>(context)` | Continue the suspended navigation; no-op if none. Clears the pending state after use. |
| `clearPendingRoute()` | End the suspended navigation (caller's Future completes with `null`). |

**Example: allow vs redirect vs suspend**

```dart
import 'package:fluro_router_generate/fluro_router.dart';

FluroConfig.addGuard((ctx) async {
  if (ctx.path.startsWith('/admin') && !hasAccess()) {
    return GuardResult.redirect('/welcome');  // replace path
  }
  return GuardResult.allow;
});

// Suspend: hold the navigation, run your flow, then resume or clear
FluroConfig.addGuard((ctx) async {
  if (ctx.path == '/premium' && !isUnlocked()) {
    // e.g. push a paywall, then on success:
    //   FluroConfig.resumePendingRoute(context);
    // on cancel:
    //   FluroConfig.clearPendingRoute();
    return GuardResult.suspend;
  }
  return GuardResult.allow;
});
```

---

## Annotation reference

| Field | Description |
|-------|-------------|
| `path` | Route path, e.g. `/home/:id`, `/search?keyword=` |
| `description` | Optional, comment in generated list |
| `defaultParams` | Optional, default values, e.g. `{'id': '-', 'page': 1}` |
| `constructorParams` | Optional: `pathParams` / `queryParams` / `routeSettingsArguments` / `none` — how params are passed to the constructor |
| `module` | Optional, module name for grouping/splitting; with build.yaml `split_modules` can emit a separate `.router.g.dart` |
| `loadMode` | Optional: `RouteLoadMode.eager` (default) / `RouteLoadMode.deferred` |
| `deferredGroup` | Optional, stable deferred import prefix grouping |
| `deferredComponent` | Optional, component hint for Android deferred components mapping |

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

To emit a separate file e.g. `router_config_payment.router.g.dart` for the `payment` module, add `split_modules` in your **project root** `build.yaml`:

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

### 4. Deferred route loading

Use `RouteLoadMode.deferred` on a page annotation to generate `deferred import` and runtime `loadLibrary()` loading:

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

Generated code uses `DeferredRoutePage` internally to keep `FluroHandler` synchronous while loading deferred libraries asynchronously.

You can also set a global default in `build.yaml`:

```yaml
targets:
  $default:
    builders:
      fluro_router_generate|router_library:
        options:
          default_load_mode: eager # eager|deferred
```

**Custom loading/error UI (optional)**  
Generated code uses `FluroConfig.deferredLoadingBuilderFor(path)` and `FluroConfig.deferredErrorBuilderFor(path)`. Set before `initAllHandlers()`:

- **Global default**: `FluroConfig.deferredRouteUIOptions = DeferredRouteUIOptions(loadingBuilder: ..., errorBuilder: ...);`
- **Per-path override**: `FluroConfig.setDeferredBuildersForPath('/search?keyword=&page=1', loading: ..., error: ...);`

If unset, `DeferredRoutePage` uses its built-in loading and error UI.

> Note: this is the **Dart deferred import** part. For Android App Bundle **Deferred Components** (dynamic delivery), you must also configure the app project.

#### Full example: Dart deferred + Android Deferred Components

**Step 1: Page annotation (code level)**

```dart
@RouterAnnotation(
  path: '/search?keyword=&page=1',
  module: 'feature',
  constructorParams: HandlerConstructorParams.queryParams,
  loadMode: RouteLoadMode.deferred,
  deferredGroup: 'search_feature',
  deferredComponent: 'search_component', // Android dynamic module name
)
class SearchPage extends StatelessWidget {
  const SearchPage({super.key, required this.keyword, required this.page});
  final String keyword;
  final String page;
  // ...
}
```

**Step 2: Generate route code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

You will get generated code similar to:

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

**Step 3: App-side `pubspec.yaml` (platform level)**

In your app `pubspec.yaml`, declare the deferred component (example):

```yaml
flutter:
  deferred-components:
    - name: search_component
      libraries:
        - package:example/pages/search_page.dart
      # optional assets for this component
      # assets:
      #   - assets/search/**
```

`name` should match the annotation field `deferredComponent` (for example, both are `search_component`).

**Step 4: Build and verify**

- Local debug/profile usually verifies only the Dart deferred path (`loadLibrary()` + `DeferredRoutePage`).
- Real Deferred Components behavior should be verified via Android App Bundle dynamic delivery flow.

**Step 5: Regression checklist**

- First entry to deferred route shows loading then target page.
- Second entry should avoid re-downloading/re-initializing the same module (depends on platform/runtime cache).
- Works with guards, `split_modules`, and `routeSettingsArguments`.

#### Common pitfall

- `loadMode: deferred` does **not** automatically finish Android dynamic module setup.
- `deferredComponent` is currently a mapping declaration field; actual dynamic delivery depends on app-side configuration and packaging.

#### When loadLibrary runs & large modules (live, video editing)

- **When does loadLibrary run?** The **first time** you navigate to that route **in the current process**; later navigations in the same process do not load again. After a **new app launch (new process)**, the first navigation to that route runs it again. If the user never opens that route, it is never loaded.
- **Very large modules?**
  1. **Preload**: Call `FluroConfig.registerDeferredLoader(path, () => your_deferred.loadLibrary())` and then `FluroConfig.preloadDeferredRoute(path)` when appropriate (e.g. after home is ready or when entering a discovery tab), so the module is ready before the user opens that route.
  2. Use a **wrapper** for clear loading/progress or “first load ~xx MB” and optional cancel.
  3. **Split by feature**: e.g. separate deferred libs for live vs. editing, so only what’s needed is loaded.
  4. **True on-demand download**: Use Android Deferred Components + Play for download size; loadLibrary after the component is installed.

**Preload example:**

```dart
// 1) Import the same deferred lib and register (path must match the annotation)
import 'package:your_app/pages/live_page.dart' deferred as live_lib;

FluroConfig.registerDeferredLoader('/live', () => live_lib.loadLibrary());

// 2) Preload when home is ready or user enters discovery
FluroConfig.preloadDeferredRoute('/live');
// Or preload all registered: FluroConfig.preloadAllDeferredRoutes();
```

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
| **Builders outputs collide** (`source_gen:combining_builder` and `fluro_router_generate:router_library`) | This package now emits `.router.g.dart` (not `.g.dart`) to avoid the conflict. Upgrade to the latest version and change your export to `export 'router_config.router.g.dart';`, then run `dart run build_runner build --delete-conflicting-outputs`. |
| **build_runner fails** with a message about build.yaml | Ensure the **only** file in `generate_for.include` is your route entry file (the one with `@EntranceAnnotation`). Do not include every `.dart` file. |
| **Route not found** at runtime | Call `RouteConfig.instance.initAllHandlers()` before `runApp()`, and use `onGenerateRoute: FluroConfig.router.generator` in `MaterialApp`. |
| **Wrong or missing params** on the page | Match `constructorParams` to how you pass data: `pathParams` for `/path/:id`, `queryParams` for `?key=`, `routeSettingsArguments` for `RouteSettings.arguments`. Use `defaultParams` when you need defaults. |
| **Generated file is empty or outdated** | Run `dart run build_runner build --delete-conflicting-outputs` again; ensure the entry file is the one listed in build.yaml and has `@EntranceAnnotation()`. |
