import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:fluro_router_generate/src/generate/annotation/router_annotation.dart';
import 'package:fluro_router_generate/src/utils/path_parser.dart';
import 'package:source_gen/source_gen.dart';

const List<String> _constructorParamsNames = [
  'none',
  'pathParams',
  'queryParams',
  'routeSettingsArguments',
];

const List<String> _loadModeNames = ['eager', 'deferred'];

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

/// 将注解中的 loadMode 转为字符串：eager / deferred
String _readLoadMode(ConstantReader annotation, {String fallback = 'eager'}) {
  try {
    final cr = annotation.peek('loadMode');
    if (cr == null || cr.isNull) return fallback;
    final indexObj = cr.objectValue.getField('index');
    if (indexObj != null) {
      final i = indexObj.toIntValue();
      if (i != null && i >= 0 && i < _loadModeNames.length) {
        return _loadModeNames[i];
      }
    }
    final accessor = cr.revive().accessor;
    if (accessor.isNotEmpty && accessor.contains('.')) {
      final name = accessor.split('.').last;
      if (_loadModeNames.contains(name)) return name;
    }
  } catch (_) {}
  return fallback;
}

/// 从 defaultParams 值推断类型：int/double/bool -> 生成解析代码，否则当 string
String _inferParamType(ConstantReader valueReader) {
  if (valueReader.isInt) return 'int';
  if (valueReader.isDouble) return 'double';
  if (valueReader.isBool) return 'bool';
  return 'string';
}

/// 从页面类的构造函数读取参数的真实类型（用于 routeSettingsArguments）。
/// 返回与 paramKeys 一一对应的 (类型显示名, 类型所在库的 import URI)。
(List<String> paramTypeNames, List<String?> paramTypeImportUris)
_getConstructorParamTypes(ClassElement classElement, List<String> paramKeys) {
  final typeNames = <String>[];
  final importUris = <String?>[];
  if (paramKeys.isEmpty) return (typeNames, importUris);

  ConstructorElement? ctor;
  for (final c in classElement.constructors) {
    if (c.isFactory) continue;
    final paramNames = c.formalParameters
        .where((p) => !p.isSuperFormal && p.name != null)
        .map((p) => p.name!)
        .toSet();
    if (paramKeys.every((k) => paramNames.contains(k))) {
      ctor = c;
      break;
    }
  }
  if (ctor == null) {
    for (final _ in paramKeys) {
      typeNames.add('');
      importUris.add(null);
    }
    return (typeNames, importUris);
  }

  final paramByName = {for (final p in ctor.formalParameters) p.name!: p};
  for (final k in paramKeys) {
    final p = paramByName[k];
    if (p == null) {
      typeNames.add('');
      importUris.add(null);
      continue;
    }
    final dartType = p.type;
    typeNames.add(dartType.getDisplayString());

    String? uri;
    if (dartType is InterfaceType) {
      final lib = dartType.element.library;
      final u = lib.uri.toString();
      if (u.startsWith('package:')) uri = u;
    }
    importUris.add(uri);
  }
  return (typeNames, importUris);
}

/// 从页面类的构造函数读取「路由参数」名列表（用于 routeSettingsArguments 未写 defaultParams 时）。
/// 排除 super 形参和 Flutter 约定的 key，返回顺序与构造函数一致。
List<String> _getRouteSettingsParamKeys(ClassElement classElement) {
  for (final c in classElement.constructors) {
    if (c.isFactory) continue;
    final names = <String>[];
    for (final p in c.formalParameters) {
      if (p.isSuperFormal || p.name == null) continue;
      if (p.name == 'key') continue; // Flutter Widget 常见 key，不作为路由参数
      names.add(p.name!);
    }
    if (names.isNotEmpty) return names;
  }
  return [];
}

/// 判断是否为“基础类型”（int/double/bool/String），仅用 defaultParams 字面量时按 string 处理
bool _isPrimitiveOrStringType(String typeDisplayName) {
  final t = typeDisplayName.replaceAll('?', '').trim();
  return t == 'int' || t == 'double' || t == 'bool' || t == 'String';
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
      if (vr.isNull) {
        defaults.add('');
        types.add('string');
      } else {
        types.add(_inferParamType(vr));
        // int/double/bool 用类型安全方式取字符串，避免 stringValue 导致异常或长度不一致
        if (vr.isInt) {
          defaults.add(vr.intValue.toString());
        } else if (vr.isDouble) {
          defaults.add(vr.doubleValue.toString());
        } else if (vr.isBool) {
          defaults.add(vr.boolValue == true ? 'true' : 'false');
        } else {
          defaults.add(vr.stringValue);
        }
      }
    }
  } catch (_) {}
  return (keys, defaults, types);
}

/// 分文件生成时的多输出：key 为空串为主文件，否则为模块名（如 'main'、'demo'）。
typedef GeneratedOutputs = Map<String, String>;

/// 默认允许拆分为独立文件的模块名；用户可在 build.yaml 的 options 中通过 split_modules 追加。
///
/// 为何不“根据 RouterAnnotation 的 module 完全动态”？
/// build_runner 要求 Builder 在**构建开始前**通过 [buildExtensions] 声明所有可能输出的文件后缀，
/// 不能等扫描完注解再决定写哪些文件，否则会报 [UnexpectedOutputException]。
/// 因此采用：默认列表 + build.yaml 的 `split_modules`，实现“按配置动态”分文件。
const Set<String> defaultSplitModules = {};

/// 供 Builder 复用：根据 [buildStep] 扫描全包并生成路由表内容。
///
/// [allowedSplitModules] 允许拆成独立文件的模块名；为 null 时使用 [defaultSplitModules]。
/// Builder 应从 build.yaml 的 options.split_modules 与 [defaultSplitModules] 合并后传入，以实现“按配置动态分文件”。
///
/// 仅当当前输入文件包含带 [EntranceAnnotation] 的类时才生成；否则返回空 map。
/// 返回 [GeneratedOutputs]：'' 为主文件，其余 key 为允许分文件的模块名。
Future<GeneratedOutputs> generateRouterTableContent(
  BuildStep buildStep, {
  Set<String>? allowedSplitModules,
  String defaultLoadMode = 'eager',
}) async {
  final splitModules = allowedSplitModules ?? defaultSplitModules;

  final configClass = await _getEntranceConfigClass(buildStep);
  if (configClass == null) return {};

  final List<_RouteEntry> entries = await _collectAnnotatedRoutes(
    buildStep,
    defaultLoadMode: defaultLoadMode,
  );
  if (entries.isEmpty) return {};

  final grouped = <String, List<_RouteEntry>>{};
  for (final e in entries) {
    final key = (e.module != null && e.module!.isNotEmpty)
        ? e.module!
        : 'default';
    grouped.putIfAbsent(key, () => []).add(e);
  }
  final sortedModuleNames = grouped.keys.toList()..sort();

  final result = <String, String>{};
  final basePath = buildStep.inputId.path.replaceFirst(RegExp(r'\.dart$'), '');
  final package = buildStep.inputId.package;

  // 仅对允许的模块生成独立文件（允许列表来自配置，即“根据 RouterAnnotation 的 module + 配置”动态分文件）
  final splitModuleNames = sortedModuleNames
      .where((m) => splitModules.contains(m))
      .toList();
  for (final moduleName in splitModuleNames) {
    final list = grouped[moduleName]!;
    final buf = StringBuffer();
    _writeGeneratedHeader(buf, configClass, modulePart: moduleName);
    _writeModuleImports(buf, list);
    _writeModuleHandlers(buf, moduleName, list);
    result[moduleName] = buf.toString();
  }

  // 主文件：import 分文件模块 + 内联未在允许列表中的模块
  final inlineModules = sortedModuleNames
      .where((m) => !splitModules.contains(m))
      .toList();
  final mainBuffer = StringBuffer();
  _writeGeneratedHeader(mainBuffer, configClass);
  final configImportUri = _inputIdToImportUri(buildStep.inputId);
  mainBuffer.writeln("import '$configImportUri';");
  mainBuffer.writeln(
    "import 'package:fluro_router_generate/fluro_router.dart';",
  );
  for (final moduleName in splitModuleNames) {
    final prefix = _moduleToLibraryPrefix(moduleName);
    // final suffix = _moduleToGetterSuffix(moduleName);
    final partUri = _moduleFileImportUri(package, basePath, moduleName);
    mainBuffer.writeln("import '$partUri' as $prefix;");
  }
  if (inlineModules.isNotEmpty) {
    final inlineEntries = <_RouteEntry>[];
    for (final moduleName in inlineModules) {
      inlineEntries.addAll(grouped[moduleName]!);
    }
    _writeEntriesImports(mainBuffer, inlineEntries);
  }
  mainBuffer.writeln();
  _writeExtensionMergeOnly(
    mainBuffer,
    configClass,
    splitModuleNames,
    grouped,
    inlineModules,
  );
  result[''] = mainBuffer.toString();

  return result;
}

/// 写入生成文件头部注释。[modulePart] 非空时表示当前为某模块分文件。
void _writeGeneratedHeader(
  StringBuffer buffer,
  String configClassName, {
  String? modulePart,
}) {
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
  if (modulePart != null) {
    buffer.writeln(
      '// 由 @EntranceAnnotation 在 $configClassName 上生成 · 模块 [$modulePart]',
    );
  } else {
    buffer.writeln('// 由 @EntranceAnnotation 在 $configClassName 上生成');
  }
  buffer.writeln();
}

/// 返回模块分文件的 import URI（如 package:example/router/router_config_main.router.g.dart）。
String _moduleFileImportUri(
  String package,
  String basePath,
  String moduleName,
) {
  final path = basePath.startsWith('lib/') ? basePath.substring(4) : basePath;
  return 'package:$package/${path}_$moduleName.router.g.dart';
}

String _sanitizeIdentifier(String input) {
  final clean = input.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  if (clean.isEmpty) return 'lib';
  if (RegExp(r'^[0-9]').hasMatch(clean)) return 'lib_$clean';
  return clean;
}

String _deferredPrefixFor(_RouteEntry e) {
  final uriHash = e.importUri.hashCode.abs();
  final group = e.deferredGroup?.trim();
  if (group != null && group.isNotEmpty) {
    return 'deferred_${_sanitizeIdentifier(group).toLowerCase()}_$uriHash';
  }
  final base = '${e.className}_$uriHash';
  return 'deferred_${_sanitizeIdentifier(base).toLowerCase()}';
}

class _DeferredImportRecord {
  const _DeferredImportRecord({required this.uri, required this.prefix});

  final String uri;
  final String prefix;
}

List<_DeferredImportRecord> _collectDeferredImports(List<_RouteEntry> entries) {
  final seenByPrefix = <String, String>{};
  final records = <_DeferredImportRecord>[];
  for (final e in entries) {
    if (!e.isDeferred) continue;
    final prefix = e.deferredPrefix;
    final uri = e.importUri;
    final existing = seenByPrefix[prefix];
    if (existing == uri) continue;
    if (existing != null && existing != uri) continue;
    seenByPrefix[prefix] = uri;
    records.add(_DeferredImportRecord(uri: uri, prefix: prefix));
  }
  records.sort((a, b) {
    final byUri = a.uri.compareTo(b.uri);
    if (byUri != 0) return byUri;
    return a.prefix.compareTo(b.prefix);
  });
  return records;
}

void _writeEntriesImports(StringBuffer buffer, List<_RouteEntry> entries) {
  final eagerUris = <String>{};
  for (final e in entries) {
    if (!e.isDeferred && e.importUri.isNotEmpty) eagerUris.add(e.importUri);
    for (final typeUri in e.paramTypeImportUris) {
      if (typeUri != null && typeUri.isNotEmpty) eagerUris.add(typeUri);
    }
  }
  final sortedEagerUris = eagerUris.toList()..sort();
  for (final uri in sortedEagerUris) {
    buffer.writeln("import '$uri';");
  }

  final deferredRecords = _collectDeferredImports(entries);
  for (final item in deferredRecords) {
    buffer.writeln("import '${item.uri}' deferred as ${item.prefix};");
  }
}

/// 写入单模块文件的 import（仅该模块用到的页面 + fluro_router）。
void _writeModuleImports(StringBuffer buffer, List<_RouteEntry> entries) {
  buffer.writeln("import 'package:fluro_router_generate/fluro_router.dart';");
  _writeEntriesImports(buffer, entries);
  buffer.writeln();
}

/// 写入单模块文件中的路由列表 getter（routeHandlersX => [...]）。
void _writeModuleHandlers(
  StringBuffer buffer,
  String moduleName,
  List<_RouteEntry> list,
) {
  final suffix = _moduleToGetterSuffix(moduleName);
  buffer.writeln('/// [$moduleName] 模块');
  buffer.writeln('List<RouterHandler> get routeHandlers$suffix => [');
  for (var i = 0; i < list.length; i++) {
    final e = list[i];
    final comment = e.description != null && e.description!.isNotEmpty
        ? e.description!
        : e.className;
    buffer.writeln('  /// $comment');
    if (e.isDeferred) {
      buffer.writeln('  /// loadMode: deferred');
      if (e.deferredComponent != null && e.deferredComponent!.isNotEmpty) {
        buffer.writeln('  /// deferredComponent: ${e.deferredComponent}');
      }
    }
    final handlerCall = _buildHandlerCall(e);
    buffer.writeln("  RouterHandler('${_escapePath(e.path)}', $handlerCall),");
    if (i < list.length - 1) buffer.writeln();
  }
  buffer.writeln('];');
}

/// 仅写入 extension：合并分文件模块 + 内联模块的 getter，以及 initAllHandlers。
void _writeExtensionMergeOnly(
  StringBuffer buffer,
  String configClassName,
  List<String> splitModuleNames,
  Map<String, List<_RouteEntry>> grouped,
  List<String> inlineModuleNames,
) {
  final extensionName = '${configClassName}X';
  buffer.writeln('extension $extensionName on $configClassName {');

  // 内联模块的 getter（未在允许分文件列表中的模块）
  for (final moduleName in inlineModuleNames) {
    final list = grouped[moduleName]!;
    final suffix = _moduleToGetterSuffix(moduleName);
    buffer.writeln('  /// [$moduleName] 模块（内联）');
    buffer.writeln('  List<RouterHandler> get _handlers$suffix => [');
    for (var i = 0; i < list.length; i++) {
      final e = list[i];
      final comment = e.description != null && e.description!.isNotEmpty
          ? e.description!
          : e.className;
      buffer.writeln('    /// $comment');
      if (e.isDeferred) {
        buffer.writeln('    /// loadMode: deferred');
        if (e.deferredComponent != null && e.deferredComponent!.isNotEmpty) {
          buffer.writeln('    /// deferredComponent: ${e.deferredComponent}');
        }
      }
      final handlerCall = _buildHandlerCall(e);
      buffer.writeln(
        "    RouterHandler('${_escapePath(e.path)}', $handlerCall),",
      );
      if (i < list.length - 1) buffer.writeln();
    }
    buffer.writeln('  ];');
    buffer.writeln();
  }

  buffer.writeln('  /// 由 fluro_router_generate 生成的 RouterHandler 列表（各模块合并）。');
  buffer.writeln('  List<RouterHandler> get generatedHandlers => [');
  for (final moduleName in splitModuleNames) {
    final prefix = _moduleToLibraryPrefix(moduleName);
    final suffix = _moduleToGetterSuffix(moduleName);
    buffer.writeln('    ...$prefix.routeHandlers$suffix,');
  }
  for (final moduleName in inlineModuleNames) {
    final suffix = _moduleToGetterSuffix(moduleName);
    buffer.writeln('    ..._handlers$suffix,');
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

/// 扫描全包（findAssets + libraryFor）收集带 [RouterAnnotation] 的类，
/// 生成独立库：imports + `List<RouterHandler>` get generatedHandlers。
/// 无需任何入口文件或 lib/routers/，由 lib/main.dart 触发生成即可。
/// 仅当通过 [RouterTableBuilder] 多文件输出时使用；单文件 Generator 已不推荐。
class FluroRouterLibraryGenerator extends Generator {
  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final out = await generateRouterTableContent(
      buildStep,
      defaultLoadMode: 'eager',
    );
    return out[''] ?? '';
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
// void _writeImports(
//   StringBuffer buffer,
//   String configImportUri,
//   List<_RouteEntry> entries,
// ) {
//   // 写入配置类所在库
//   buffer.writeln("import '$configImportUri';");
//   buffer.writeln("import 'package:fluro_router_generate/fluro_router.dart';");

//   // 写入各页面库
//   final uris = <String>{};
//   for (final e in entries) {
//     if (e.importUri.isNotEmpty) uris.add(e.importUri);
//     // 为 routeSettingsArguments 的对象类型补充类型所在库的 import
//     for (final typeUri in e.paramTypeImportUris) {
//       if (typeUri != null && typeUri.isNotEmpty) uris.add(typeUri);
//     }
//   }
//   final sortedUris = uris.toList()..sort();
//   for (final uri in sortedUris) {
//     buffer.writeln("import '$uri';");
//   }
//   buffer.writeln();
// }

/// 转义 path 中单引号，用于生成字符串字面量
String _escapePath(String path) => path.replaceAll("'", "\\'");

/// 根据 constructorParams 生成 handlerFunc 的调用表达式（单行或多行）
String _buildHandlerCall(_RouteEntry e) {
  if (e.isDeferred) return _buildDeferredHandlerCall(e);
  return _buildDirectHandlerCall(e, classRef: e.className);
}

String _buildDirectHandlerCall(_RouteEntry e, {required String classRef}) {
  final cp = e.constructorParams;

  if (cp == 'pathParams') {
    final names = pathParamNames(e.path);
    if (names.isEmpty) {
      return 'FluroHandler(handlerFunc: (context, parameters) => $classRef())';
    }
    final defaults = names.map((n) {
      final i = e.paramKeys.indexOf(n);
      return i >= 0 && i < e.paramDefaults.length ? e.paramDefaults[i] : '';
    }).toList();
    final args = List.generate(names.length, (i) {
      final n = names[i];
      final d = defaults[i].replaceAll("'", "\\'");
      return '$n: parameters[\'$n\']?.first ?? \'$d\'';
    }).join(', ');
    return 'FluroHandler(handlerFunc: (context, parameters) => $classRef($args))';
  }

  if (cp == 'queryParams') {
    final pathNames = queryParamNames(e.path);
    final names = pathNames.isNotEmpty ? pathNames : e.paramKeys;
    if (names.isEmpty) {
      return 'FluroHandler(handlerFunc: (context, parameters) => $classRef())';
    }
    final defaults = names.map((n) {
      final i = e.paramKeys.indexOf(n);
      return i >= 0 && i < e.paramDefaults.length ? e.paramDefaults[i] : '';
    }).toList();
    final args = List.generate(names.length, (i) {
      final n = names[i];
      final d = defaults[i].replaceAll("'", "\\'");
      return '$n: parameters[\'$n\']?.first ?? \'$d\'';
    }).join(', ');
    return 'FluroHandler(handlerFunc: (context, parameters) => $classRef($args))';
  }

  if (cp == 'routeSettingsArguments') {
    if (e.paramKeys.isEmpty) {
      return 'FluroHandler(handlerFunc: (context, parameters) => $classRef())';
    }
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
      final typeName = i < e.paramTypeNames.length ? e.paramTypeNames[i] : '';
      final fromCtor = typeName.isNotEmpty;
      final isObjectType = fromCtor && !_isPrimitiveOrStringType(typeName);

      if (isObjectType) {
        sb.writeln("$indent final $k = argsMap?['$k'] as $typeName;");
      } else {
        final prim = i < e.paramTypes.length ? e.paramTypes[i] : 'string';
        if (prim == 'int') {
          sb.writeln(
            "$indent final $k = int.tryParse(argsMap?['$k']?.toString() ?? '') ?? ${d.isEmpty ? '0' : d};",
          );
        } else if (prim == 'double') {
          sb.writeln(
            "$indent final $k = double.tryParse(argsMap?['$k']?.toString() ?? '') ?? ${d.isEmpty ? '0.0' : d};",
          );
        } else if (prim == 'bool') {
          sb.writeln(
            "$indent final $k = (argsMap?['$k']?.toString() ?? '$d').toLowerCase() == 'true';",
          );
        } else {
          sb.writeln("$indent final $k = argsMap?['$k']?.toString() ?? '$d';");
        }
      }
    }
    final ctorArgs = e.paramKeys.map((k) => '$k: $k').join(', ');
    sb.writeln('$indent return $classRef($ctorArgs);');
    sb.write('    })');
    return sb.toString();
  }

  // none
  if (e.hasPathOrQueryParams) {
    return 'FluroHandler(handlerFunc: (context, parameters) => $classRef(parameters: parameters))';
  }
  return 'FluroHandler(handlerFunc: (context, parameters) => $classRef())';
}

String _buildDeferredHandlerCall(_RouteEntry e) {
  final cp = e.constructorParams;
  final classRef = '${e.deferredPrefix}.${e.className}';
  final loader = '${e.deferredPrefix}.loadLibrary()';
  const indent = '      ';

  if (cp == 'pathParams') {
    final names = pathParamNames(e.path);
    final args = names
        .map((n) {
          final i = e.paramKeys.indexOf(n);
          final d =
              (i >= 0 && i < e.paramDefaults.length ? e.paramDefaults[i] : '')
                  .replaceAll("'", "\\'");
          return '$n: parameters[\'$n\']?.first ?? \'$d\'';
        })
        .join(', ');
    final pageExpr = names.isEmpty ? '$classRef()' : '$classRef($args)';
    final pathArg = _escapePath(e.path);
    return "FluroHandler(handlerFunc: (context, parameters) => DeferredRoutePage(loader: () => $loader, builder: (context) => $pageExpr, debugLabel: '$pathArg', loadingBuilder: FluroConfig.deferredLoadingBuilderFor('$pathArg'), errorBuilder: FluroConfig.deferredErrorBuilderFor('$pathArg'), wrapper: FluroConfig.deferredWrapperFor('$pathArg')))";
  }

  if (cp == 'queryParams') {
    final pathNames = queryParamNames(e.path);
    final names = pathNames.isNotEmpty ? pathNames : e.paramKeys;
    final args = names
        .map((n) {
          final i = e.paramKeys.indexOf(n);
          final d =
              (i >= 0 && i < e.paramDefaults.length ? e.paramDefaults[i] : '')
                  .replaceAll("'", "\\'");
          return '$n: parameters[\'$n\']?.first ?? \'$d\'';
        })
        .join(', ');
    final pageExpr = names.isEmpty ? '$classRef()' : '$classRef($args)';
    final pathArg = _escapePath(e.path);
    return "FluroHandler(handlerFunc: (context, parameters) => DeferredRoutePage(loader: () => $loader, builder: (context) => $pageExpr, debugLabel: '$pathArg', loadingBuilder: FluroConfig.deferredLoadingBuilderFor('$pathArg'), errorBuilder: FluroConfig.deferredErrorBuilderFor('$pathArg'), wrapper: FluroConfig.deferredWrapperFor('$pathArg')))";
  }

  if (cp == 'routeSettingsArguments') {
    final pathArg = _escapePath(e.path);
    if (e.paramKeys.isEmpty) {
      return "FluroHandler(handlerFunc: (context, parameters) => DeferredRoutePage(loader: () => $loader, builder: (context) => $classRef(), debugLabel: '$pathArg', loadingBuilder: FluroConfig.deferredLoadingBuilderFor('$pathArg'), errorBuilder: FluroConfig.deferredErrorBuilderFor('$pathArg'), wrapper: FluroConfig.deferredWrapperFor('$pathArg')))";
    }
    final sb = StringBuffer();
    sb.writeln(
      'FluroHandler(handlerFunc: (context, parameters) => DeferredRoutePage(',
    );
    sb.writeln('$indent loader: () => $loader,');
    sb.writeln('$indent debugLabel: \'$pathArg\',');
    sb.writeln('$indent loadingBuilder: FluroConfig.deferredLoadingBuilderFor(\'$pathArg\'),');
    sb.writeln('$indent errorBuilder: FluroConfig.deferredErrorBuilderFor(\'$pathArg\'),');
    sb.writeln('$indent wrapper: FluroConfig.deferredWrapperFor(\'$pathArg\'),');
    sb.writeln('$indent builder: (context) {');
    sb.writeln('$indent   final arguments = context.arguments;');
    sb.writeln(
      '$indent   final argsMap = arguments is Map<dynamic, dynamic> ? arguments : null;',
    );
    for (var i = 0; i < e.paramKeys.length; i++) {
      final k = e.paramKeys[i];
      final d = (i < e.paramDefaults.length ? e.paramDefaults[i] : '')
          .replaceAll("'", "\\'");
      final typeName = i < e.paramTypeNames.length ? e.paramTypeNames[i] : '';
      final fromCtor = typeName.isNotEmpty;
      final isObjectType = fromCtor && !_isPrimitiveOrStringType(typeName);
      if (isObjectType) {
        sb.writeln("$indent   final $k = argsMap?['$k'] as $typeName;");
      } else {
        final prim = i < e.paramTypes.length ? e.paramTypes[i] : 'string';
        if (prim == 'int') {
          sb.writeln(
            "$indent   final $k = int.tryParse(argsMap?['$k']?.toString() ?? '') ?? ${d.isEmpty ? '0' : d};",
          );
        } else if (prim == 'double') {
          sb.writeln(
            "$indent   final $k = double.tryParse(argsMap?['$k']?.toString() ?? '') ?? ${d.isEmpty ? '0.0' : d};",
          );
        } else if (prim == 'bool') {
          sb.writeln(
            "$indent   final $k = (argsMap?['$k']?.toString() ?? '$d').toLowerCase() == 'true';",
          );
        } else {
          sb.writeln(
            "$indent   final $k = argsMap?['$k']?.toString() ?? '$d';",
          );
        }
      }
    }
    final ctorArgs = e.paramKeys.map((k) => '$k: $k').join(', ');
    sb.writeln('$indent   return $classRef($ctorArgs);');
    sb.writeln('$indent },');
    sb.write('    )');
    return sb.toString();
  }

  final pathArg = _escapePath(e.path);
  if (e.hasPathOrQueryParams) {
    return "FluroHandler(handlerFunc: (context, parameters) => DeferredRoutePage(loader: () => $loader, builder: (context) => $classRef(parameters: parameters), debugLabel: '$pathArg', loadingBuilder: FluroConfig.deferredLoadingBuilderFor('$pathArg'), errorBuilder: FluroConfig.deferredErrorBuilderFor('$pathArg'), wrapper: FluroConfig.deferredWrapperFor('$pathArg')))";
  }
  return "FluroHandler(handlerFunc: (context, parameters) => DeferredRoutePage(loader: () => $loader, builder: (context) => $classRef(), debugLabel: '$pathArg', loadingBuilder: FluroConfig.deferredLoadingBuilderFor('$pathArg'), errorBuilder: FluroConfig.deferredErrorBuilderFor('$pathArg'), wrapper: FluroConfig.deferredWrapperFor('$pathArg')))";
}

/// 将 module 名转为合法的 getter 后缀（如 default -> Default, user-profile -> UserProfile）
String _moduleToGetterSuffix(String module) {
  final clean = module.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  if (clean.isEmpty) return 'Default';
  return clean.substring(0, 1).toUpperCase() + clean.substring(1).toLowerCase();
}

/// 将 module 名转为合法的库 import 前缀（lower_case_with_underscores，无下划线开头）
String _moduleToLibraryPrefix(String module) {
  final clean = module.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  if (clean.isEmpty) return 'part_default';
  return 'part_${clean.toLowerCase()}';
}

/// 写入 extension X on ConfigClass { 按 module 分组的路由 getter；generatedHandlers；initAllHandlers }
// void _writeExtension(
//   StringBuffer buffer,
//   String configClassName,
//   List<_RouteEntry> entries,
// ) {
//   final extensionName = '${configClassName}X';
//   buffer.writeln('extension $extensionName on $configClassName {');

//   // 按 module 分组（未设置 module 的归入 default）
//   final grouped = <String, List<_RouteEntry>>{};
//   for (final e in entries) {
//     final key = (e.module != null && e.module!.isNotEmpty)
//         ? e.module!
//         : 'default';
//     grouped.putIfAbsent(key, () => []).add(e);
//   }
//   final sortedModuleNames = grouped.keys.toList()..sort();

//   // 为每个模块生成一个 getter，便于阅读和维护
//   for (final moduleName in sortedModuleNames) {
//     final list = grouped[moduleName]!;
//     final suffix = _moduleToGetterSuffix(moduleName);
//     buffer.writeln('  /// [$moduleName] 模块');
//     buffer.writeln('  List<RouterHandler> get _handlers$suffix => [');
//     for (var i = 0; i < list.length; i++) {
//       final e = list[i];
//       final comment = e.description != null && e.description!.isNotEmpty
//           ? e.description!
//           : e.className;
//       buffer.writeln('    /// $comment');
//       final handlerCall = _buildHandlerCall(e);
//       buffer.writeln(
//         "    RouterHandler('${_escapePath(e.path)}', $handlerCall),",
//       );
//       if (i < list.length - 1) buffer.writeln();
//     }
//     buffer.writeln('  ];');
//     buffer.writeln();
//   }

//   // 汇总为 generatedHandlers
//   buffer.writeln('  /// 由 fluro_router_generate 生成的 RouterHandler 列表（各模块合并）。');
//   buffer.writeln('  List<RouterHandler> get generatedHandlers => [');
//   for (var i = 0; i < sortedModuleNames.length; i++) {
//     final suffix = _moduleToGetterSuffix(sortedModuleNames[i]);
//     buffer.writeln('    ..._handlers$suffix,');
//   }
//   buffer.writeln('  ];');
//   buffer.writeln();
//   buffer.writeln('  /// 注册生成的路由到 [FluroConfig.router]，');
//   buffer.writeln('  void initAllHandlers() {');
//   buffer.writeln('    for (final h in generatedHandlers) {');
//   buffer.writeln(
//     '      FluroConfig.router.define(h.path, handler: h.handler);',
//   );
//   buffer.writeln('    }');
//   buffer.writeln('  }');
//   buffer.writeln('}');
// }

/// 用 findAssets 扫描当前包 lib/**/*.dart，再对每个 asset libraryFor 收集带注解的类。
Future<List<_RouteEntry>> _collectAnnotatedRoutes(
  BuildStep buildStep, {
  required String defaultLoadMode,
}) async {
  // 携带 [RouterAnnotation] 的类列表
  final package = buildStep.inputId.package;
  final List<_RouteEntry> entries = <_RouteEntry>[];

  /// 遍历当前包 lib/**/*.dart 中的所有类
  await for (final assetId in buildStep.findAssets(Glob('lib/**/*.dart'))) {
    // 排除其他包的类
    if (assetId.package != package) continue;

    // 排除生成的路由表文件（.router.g.dart 及其它 .g.dart）
    if (assetId.path.endsWith('.router.g.dart') ||
        assetId.path.endsWith('.g.dart'))
      continue;

    // 获取当前类的库
    final lib = await buildStep.resolver.libraryFor(assetId);
    final importUri = lib.uri.toString();

    // 排除 fluro_router_generate 包的类和非 package 开头的类
    if (importUri.contains('fluro_router_generate') ||
        !importUri.startsWith('package:')) {
      continue;
    }

    /// 遍历当前类库中的所有类
    for (final ClassElement element in lib.classes) {
      // 收集该类上所有 [RouterAnnotation] 注解，没有则跳过
      final annotations = _annotationChecker.annotationsOf(element);
      if (annotations.isEmpty) continue;

      // 获取类名如果类名为空，则跳过
      final className = element.name;
      if (className == null || className.isEmpty) continue;

      for (final annotation in annotations) {
        // 获取注解中的路径如果路径为空，则跳过
        final reader = ConstantReader(annotation);
        final path = reader.read('path').stringValue;
        if (path.isEmpty) continue;

        // 获取传入参数的类型
        final constructorParams = _readConstructorParams(reader);
        final loadMode = _readLoadMode(reader, fallback: defaultLoadMode);

        // 获取传入参数的 (键、默认值、类型)
        var (paramKeys, paramDefaults, paramTypes) = _readDefaultParamsMap(
          reader,
        );

        // 当使用 routeSettingsArguments 时：以构造函数参数为传参列表，defaultParams 只提供默认值/类型
        // 这样写 defaultParams: {count: 0} 时仍会生成 title、count 两个参数，仅 count 有默认值
        if (constructorParams == 'routeSettingsArguments') {
          final inferredKeys = _getRouteSettingsParamKeys(element);
          if (inferredKeys.isNotEmpty) {
            final defaultByKey = <String, ({String def, String typ})>{};
            for (
              var i = 0;
              i < paramKeys.length &&
                  i < paramDefaults.length &&
                  i < paramTypes.length;
              i++
            ) {
              defaultByKey[paramKeys[i]] = (
                def: paramDefaults[i],
                typ: paramTypes[i],
              );
            }
            paramKeys = inferredKeys;
            paramDefaults = paramKeys
                .map((k) => defaultByKey[k]?.def ?? '')
                .toList();
            paramTypes = paramKeys
                .map((k) => defaultByKey[k]?.typ ?? 'string')
                .toList();
          }
        }

        // 当使用 routeSettingsArguments 时，从页面类构造函数读取参数真实类型
        List<String> paramTypeNames = [];
        List<String?> paramTypeImportUris = [];
        if (constructorParams == 'routeSettingsArguments' &&
            paramKeys.isNotEmpty) {
          final r = _getConstructorParamTypes(element, paramKeys);
          paramTypeNames = r.$1;
          paramTypeImportUris = r.$2;
        }

        // 获取描述
        final description = reader.peek('description')?.stringValue;

        // 获取可选模块名（用于分组生成）
        final module = reader.peek('module')?.stringValue;
        final deferredGroup = reader.peek('deferredGroup')?.stringValue;
        final deferredComponent = reader.peek('deferredComponent')?.stringValue;

        entries.add(
          _RouteEntry(
            path: path,
            className: className,
            importUri: importUri,
            constructorParams: constructorParams,
            paramKeys: paramKeys,
            paramDefaults: paramDefaults,
            paramTypes: paramTypes,
            paramTypeNames: paramTypeNames,
            paramTypeImportUris: paramTypeImportUris,
            description: description,
            module: module,
            loadMode: loadMode,
            deferredGroup: deferredGroup,
            deferredComponent: deferredComponent,
          ),
        );
      }
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

  /// 参数类型（来自 defaultParams 字面量推断：int/double/bool/string）
  final List<String> paramTypes;

  /// 参数真实类型显示名（来自页面类构造函数，用于 routeSettingsArguments 对象类型 as Type?）
  final List<String> paramTypeNames;

  /// 参数类型所在库的 import URI（用于为对象类型添加 import）
  final List<String?> paramTypeImportUris;

  /// 描述
  final String? description;

  /// 可选模块名，用于分组生成
  final String? module;

  /// 页面加载模式：eager / deferred
  final String loadMode;

  /// deferred 分组名（可选）
  final String? deferredGroup;

  /// 可选 deferred component 名称（用于注释和映射）
  final String? deferredComponent;

  _RouteEntry({
    required this.path,
    required this.className,
    required this.importUri,
    this.constructorParams = 'none',
    List<String>? paramKeys,
    List<String>? paramDefaults,
    List<String>? paramTypes,
    List<String>? paramTypeNames,
    List<String?>? paramTypeImportUris,
    this.description,
    this.module,
    this.loadMode = 'eager',
    this.deferredGroup,
    this.deferredComponent,
  }) : paramKeys = paramKeys ?? [],
       paramDefaults = paramDefaults ?? [],
       paramTypes = paramTypes ?? [],
       paramTypeNames = paramTypeNames ?? [],
       paramTypeImportUris = paramTypeImportUris ?? [];

  /// FluroRouter 路径参数（如 /home/:id）或查询参数（如 /home?id=1）时需将 parameters 传给页面
  bool get hasPathOrQueryParams => path.contains(':') || path.contains('?');

  bool get isDeferred => loadMode == 'deferred';

  String get deferredPrefix => _deferredPrefixFor(this);
}
