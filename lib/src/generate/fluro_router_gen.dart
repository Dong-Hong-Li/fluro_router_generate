import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:fluro_router_generate/src/generate/annotation/router_annotation.dart';
import 'package:source_gen/source_gen.dart';

/// 从 path 解析路径参数名：/home/:id → [id]，/user/:userId/post/:postId → [userId, postId]
List<String> _pathParamNames(String path) {
  final basePath = path.contains('?') ? path.split('?').first : path;
  final segments = basePath.split('/');
  final names = <String>[];
  for (final s in segments) {
    if (s.startsWith(':')) names.add(s.substring(1));
  }
  return names;
}

/// 从 path 解析查询参数名：/home?id=1&name=2 → [id, name]
List<String> _queryParamNames(String path) {
  if (!path.contains('?')) return [];
  final query = path.split('?').last.split('#').first;
  if (query.isEmpty) return [];
  final names = <String>[];
  for (final part in query.split('&')) {
    final eq = part.indexOf('=');
    if (eq > 0) names.add(part.substring(0, eq));
  }
  return names;
}

const List<String> _constructorParamsNames = [
  'none',
  'pathParams',
  'queryParams',
  'routeSettingsArguments',
];

/// 将注解中的 constructorParams 转为字符串：pathParams / queryParams / routeSettingsArguments / none
String _readConstructorParams(ConstantReader annotation) {
  try {
    // 获取注解中的 constructorParams
    final cr = annotation.peek('constructorParams');
    if (cr == null || cr.isNull) return 'none';
    // 枚举按 index 读取：HandlerConstructorParams.none=0, pathParams=1, queryParams=2, routeSettingsArguments=3
    final indexObj = cr.objectValue.getField('index');
    if (indexObj != null) {
      final i = indexObj.toIntValue();
      if (i != null && i >= 0 && i < _constructorParamsNames.length) {
        return _constructorParamsNames[i];
      }
    }

    // 获取注解中的 accessor
    final accessor = cr.revive().accessor;
    if (accessor.isNotEmpty && accessor.contains('.')) {
      return accessor.split('.').last;
    }
  } catch (_) {}
  return 'none';
}

/// 从 defaultParams 值推断类型：int/double/bool -> 生成解析代码，否则当 string
String _inferParamType(ConstantReader valueReader) {
  if (valueReader.isInt) return 'int';
  if (valueReader.isDouble) return 'double';
  if (valueReader.isBool) return 'bool';
  return 'string';
}

/// 将注解中的 defaultParams Map 转为 (keys, defaults, types)
/// types 与 keys 一一对应：'int'|'double'|'bool'|'string'，用于生成非 String 传参
(List<String> keys, List<String> defaults, List<String> types)
_readDefaultParamsMap(ConstantReader annotation) {
  final keys = <String>[];
  final defaults = <String>[];
  final types = <String>[];
  try {
    final pr = annotation.peek('defaultParams');
    if (pr == null || pr.isNull || !pr.isMap) return (keys, defaults, types);
    final map = pr.mapValue;
    for (final e in map.entries) {
      if (e.key == null) continue;
      final k = ConstantReader(e.key).stringValue;
      if (k.isEmpty) continue;
      keys.add(k);
      final vr = ConstantReader(e.value);
      if (e.value == null) {
        defaults.add('');
        types.add('string');
      } else {
        types.add(_inferParamType(vr));
        defaults.add(vr.stringValue);
      }
    }
  } catch (_) {}
  return (keys, defaults, types);
}

/// 供 Builder 或 Generator 复用：根据 [buildStep] 扫描全包并生成路由表库内容。
/// 仅当当前输入文件包含带 [EntranceAnnotation] 的类时才生成；返回空字符串表示不生成。
Future<String> generateRouterTableContent(BuildStep buildStep) async {
  // 获取带 [EntranceAnnotation] 的类
  final configClass = await _getEntranceConfigClass(buildStep);
  if (configClass == null) return '';

  // 收集带 [RouterAnnotation] 的类 如果为空，则返回空字符串
  final List<_RouteEntry> entries = await _collectAnnotatedRoutes(buildStep);
  if (entries.isEmpty) return '';

  // 写入生成文件头部注释
  final buffer = StringBuffer();
  _writeGeneratedHeader(buffer, configClass);

  //将 build 的 inputId 转为可 import 的 package URI（如 package:example/router/router_config.dart）
  final configImportUri = _inputIdToImportUri(buildStep.inputId);

  // 写入生成文件的 import 如:
  // import 'package:example/router/router_config.dart';
  // import 'package:fluro_router_generate/fluro_router.dart';
  // import 'package:example/pages/detail_page.dart';
  // ........
  _writeImports(buffer, configImportUri, entries);

  // 写入生成文件的 extension 如:
  // extension RouteConfigX on RouteConfig {
  //   List<RouterHandler> get generatedHandlers => [
  //     RouterHandler('/detail/:id', FluroHandler(handlerFunc: (context, parameters) => DetailPage(id: parameters['id']?.first ?? '0'))),
  //     RouterHandler('/home/:id', FluroHandler(handlerFunc: (context, parameters) => HomePage(id: parameters['id']?.first ?? '-'))),
  //   ];
  // }
  _writeExtension(buffer, configClass, entries);
  return buffer.toString();
}

/// 写入生成文件头部注释。
void _writeGeneratedHeader(StringBuffer buffer, String configClassName) {
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('//');
  buffer.writeln(
    '// **************************************************************************',
  );
  buffer.writeln('// FluroRouterGenerator');
  buffer.writeln(
    '// **************************************************************************',
  );
  buffer.writeln('//');
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// 由 @EntranceAnnotation 在 $configClassName 上生成');
  buffer.writeln();
}

/// 扫描全包（findAssets + libraryFor）收集带 [RouterAnnotation] 的类，
/// 生成独立库：imports + List<RouterHandler> get generatedHandlers。
/// 无需任何入口文件或 lib/routers/，由 lib/main.dart 触发生成即可。
class FluroRouterLibraryGenerator extends Generator {
  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    return generateRouterTableContent(buildStep);
  }
}

final TypeChecker _annotationChecker = TypeChecker.typeNamed(
  RouterAnnotation,
  inPackage: 'fluro_router_generate',
);

final TypeChecker _entranceChecker = TypeChecker.typeNamed(
  EntranceAnnotation,
  inPackage: 'fluro_router_generate',
);

/// 若当前输入文件中有带 [EntranceAnnotation] 的类，返回该类名，否则返回 null。
Future<String?> _getEntranceConfigClass(BuildStep buildStep) async {
  try {
    //  把源码 → AST → Element 模型”
    final lib = await buildStep.resolver.libraryFor(buildStep.inputId);

    // 遍历库中的所有类
    for (final element in lib.classes) {
      // 检查类是否带有 [EntranceAnnotation] 注解
      final hasEntrance = _entranceChecker.hasAnnotationOf(element);
      if (hasEntrance) return element.name;
    }
  } catch (_) {}
  return null;
}

/// 将 build 的 inputId 转为可 import 的 package URI（如 package:example/router/router_config.dart）
String _inputIdToImportUri(AssetId id) {
  final path = id.path.startsWith('lib/') ? id.path.substring(4) : id.path;
  return 'package:${id.package}/$path';
}

/// 写入生成库的 import：配置类所在库 + fluro_router_generate + 各页面库
void _writeImports(
  StringBuffer buffer,
  String configImportUri,
  List<_RouteEntry> entries,
) {
  // 写入配置类所在库
  buffer.writeln("import '$configImportUri';");
  buffer.writeln("import 'package:fluro_router_generate/fluro_router.dart';");

  // 写入各页面库
  final uris =
      entries
          .map((e) => e.importUri)
          .where((u) => u.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  for (final uri in uris) {
    buffer.writeln("import '$uri';");
  }
  buffer.writeln();
}

/// 转义 path 中单引号，用于生成字符串字面量
String _escapePath(String path) => path.replaceAll("'", "\\'");

/// 根据 constructorParams 生成 handlerFunc 的调用表达式（单行或多行）
String _buildHandlerCall(_RouteEntry e) {
  final cp = e.constructorParams;
  final className = e.className;

  if (cp == 'pathParams') {
    final names = _pathParamNames(e.path);
    if (names.isEmpty)
      return 'FluroHandler(handlerFunc: (context, parameters) => $className())';
    final defaults = names.map((n) {
      final i = e.paramKeys.indexOf(n);
      return i >= 0 && i < e.paramDefaults.length ? e.paramDefaults[i] : '';
    }).toList();
    final args = List.generate(names.length, (i) {
      final n = names[i];
      final d = defaults[i].replaceAll("'", "\\'");
      return "$n: parameters['$n']?.first ?? '$d'";
    }).join(', ');
    return "FluroHandler(handlerFunc: (context, parameters) => $className($args))";
  }

  if (cp == 'queryParams') {
    final pathNames = _queryParamNames(e.path);
    final names = pathNames.isNotEmpty ? pathNames : e.paramKeys;
    if (names.isEmpty)
      return 'FluroHandler(handlerFunc: (context, parameters) => $className())';
    final defaults = names.map((n) {
      final i = e.paramKeys.indexOf(n);
      return i >= 0 && i < e.paramDefaults.length ? e.paramDefaults[i] : '';
    }).toList();
    final args = List.generate(names.length, (i) {
      final n = names[i];
      final d = defaults[i].replaceAll("'", "\\'");
      return "$n: parameters['$n']?.first ?? '$d'";
    }).join(', ');
    return "FluroHandler(handlerFunc: (context, parameters) => $className($args))";
  }

  if (cp == 'routeSettingsArguments') {
    if (e.paramKeys.isEmpty)
      return 'FluroHandler(handlerFunc: (context, parameters) => $className())';
    const indent = '      ';
    final sb = StringBuffer();
    sb.writeln('FluroHandler(handlerFunc: (context, parameters) {');
    sb.writeln('$indent final arguments = context?.arguments;');
    sb.writeln(
      '$indent final argsMap = arguments is Map<dynamic, dynamic> ? arguments : null;',
    );
    for (var i = 0; i < e.paramKeys.length; i++) {
      final k = e.paramKeys[i];
      final d = (i < e.paramDefaults.length ? e.paramDefaults[i] : '')
          .replaceAll("'", "\\'");
      sb.writeln("$indent final $k = argsMap?['$k']?.toString() ?? '$d';");
    }
    final ctorArgs = e.paramKeys.map((k) => '$k: $k').join(', ');
    sb.writeln('$indent return $className($ctorArgs);');
    sb.write('    })');
    return sb.toString();
  }

  // none
  if (e.hasPathOrQueryParams) {
    return 'FluroHandler(handlerFunc: (context, parameters) => $className(parameters: parameters))';
  }
  return 'FluroHandler(handlerFunc: (context, parameters) => $className())';
}

/// 写入 extension X on ConfigClass { generatedHandlers; initAllHandlers override }
void _writeExtension(
  StringBuffer buffer,
  String configClassName,
  List<_RouteEntry> entries,
) {
  final extensionName = '${configClassName}X';
  buffer.writeln('extension $extensionName on $configClassName {');
  buffer.writeln('  /// 由 fluro_router_generate 生成的 RouterHandler 列表。');
  // 写入 RouterHandler 列表
  buffer.writeln('  List<RouterHandler> get generatedHandlers => [');
  for (var i = 0; i < entries.length; i++) {
    // 获取当前路由
    final e = entries[i];

    // 获取注释(描述) 如果描述不为空，则使用描述，否则使用类名
    final comment = e.description != null && e.description!.isNotEmpty
        ? e.description!
        : e.className;
    buffer.writeln('    /// $comment');

    // 生成 RouterHandler 的调用表达式
    final handlerCall = _buildHandlerCall(e);
    buffer.writeln(
      "    RouterHandler('${_escapePath(e.path)}', $handlerCall),",
    );
    if (i < entries.length - 1) buffer.writeln();
  }
  buffer.writeln('  ];');
  buffer.writeln();
  buffer.writeln('  /// 注册生成的路由到 [FluroConfig.router]，');
  buffer.writeln('  void initAllHandlers() {');
  buffer.writeln('    for (final h in generatedHandlers) {');
  buffer.writeln(
    '      FluroConfig.router.define(h.path, handler: h.handler);',
  );
  buffer.writeln('    }');
  buffer.writeln('  }');
  buffer.writeln('}');
}

/// 用 findAssets 扫描当前包 lib/**/*.dart，再对每个 asset libraryFor 收集带注解的类。
Future<List<_RouteEntry>> _collectAnnotatedRoutes(BuildStep buildStep) async {
  // 携带 [RouterAnnotation] 的类列表
  final package = buildStep.inputId.package;
  final List<_RouteEntry> entries = <_RouteEntry>[];

  /// 遍历当前包 lib/**/*.dart 中的所有类
  await for (final assetId in buildStep.findAssets(Glob('lib/**/*.dart'))) {
    // 排除其他包的类
    if (assetId.package != package) continue;

    // 排除生成的路由表文件
    if (assetId.path.endsWith('.g.dart')) continue;

    // 获取当前类的库
    final lib = await buildStep.resolver.libraryFor(assetId);
    final importUri = lib.uri.toString();

    // 排除 fluro_router_generate 包的类和非 package 开头的类
    if (importUri.contains('fluro_router_generate') ||
        !importUri.startsWith('package:')) {
      continue;
    }

    /// 遍历当前类库中的所有类
    for (final element in lib.classes) {
      // 检查类是否带有 [RouterAnnotation] 注解，如果类不带有 [RouterAnnotation] 注解，则跳过
      final annotation = _annotationChecker.firstAnnotationOf(element);
      if (annotation == null) continue;

      // 获取注解中的路径如果路径为空，则跳过
      final reader = ConstantReader(annotation);
      final path = reader.read('path').stringValue;
      if (path.isEmpty) continue;

      // 获取类名如果类名为空，则跳过
      final className = element.name;
      if (className == null || className.isEmpty) continue;

      // 获取传入参数的类型
      final constructorParams = _readConstructorParams(reader);

      // 获取传入参数的 (键、默认值、类型)
      final (paramKeys, paramDefaults, paramTypes) = _readDefaultParamsMap(
        reader,
      );

      // 获取描述
      final description = reader.peek('description')?.stringValue;

      entries.add(
        _RouteEntry(
          path: path,
          className: className,
          importUri: importUri,
          constructorParams: constructorParams,
          paramKeys: paramKeys,
          paramDefaults: paramDefaults,
          paramTypes: paramTypes,
          description: description,
        ),
      );
    }
  }

  return entries;
}

class _RouteEntry {
  /// 路由路径
  final String path;

  /// 类名
  final String className;

  /// 导入路径
  final String importUri;

  /// 构造函数参数
  final String constructorParams;

  /// 参数键
  final List<String> paramKeys;

  /// 参数默认值
  final List<String> paramDefaults;

  /// 参数类型
  final List<String> paramTypes;

  /// 描述
  final String? description;

  _RouteEntry({
    required this.path,
    required this.className,
    required this.importUri,
    this.constructorParams = 'none',
    List<String>? paramKeys,
    List<String>? paramDefaults,
    List<String>? paramTypes,
    this.description,
  }) : paramKeys = paramKeys ?? [],
       paramDefaults = paramDefaults ?? [],
       paramTypes = paramTypes ?? [];

  /// FluroRouter 路径参数（如 /home/:id）或查询参数（如 /home?id=1）时需将 parameters 传给页面
  bool get hasPathOrQueryParams => path.contains(':') || path.contains('?');
}
