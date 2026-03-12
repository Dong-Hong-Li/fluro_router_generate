import 'package:build/build.dart';
import 'package:fluro_router_generate/src/generate/fluro_router_gen.dart';

/// build_runner 入口：返回实现 [Builder] 的路由表生成器。
/// 可通过 [BuilderOptions.config] 的 `split_modules` 动态增加可分文件的模块名。
Builder buildRouter(BuilderOptions options) {
  return RouterTableBuilder(options);
}

/// 从 [BuilderOptions] 解析「允许拆分为独立文件」的模块名，与 [defaultSplitModules] 合并。
/// build.yaml 示例：builders: fluro_router_generate|router_library: options: { split_modules: [featureA, featureB] }
Set<String> _resolveSplitModules(BuilderOptions options) {
  final fromConfig = options.config['split_modules'];
  if (fromConfig == null) return defaultSplitModules;
  final list = fromConfig is List ? fromConfig : const [];
  final extra = list
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .map((s) => s.trim())
      .toSet();
  return {...defaultSplitModules, ...extra};
}

/// 从 [BuilderOptions] 解析默认加载模式（eager/deferred）。
String _resolveDefaultLoadMode(BuilderOptions options) {
  final raw = options.config['default_load_mode'];
  if (raw is! String) return 'eager';
  final value = raw.trim().toLowerCase();
  return value == 'deferred' ? 'deferred' : 'eager';
}

/// 仅对带 [EntranceAnnotation] 的入口文件运行，绝不对全量 .dart 跑。
/// 若当前输入未标注入口注解，直接报错并提示配置 build.yaml。
/// 支持分文件：主文件 + 各模块文件；允许拆分的模块 = [defaultSplitModules] + build.yaml 的 split_modules。
class RouterTableBuilder implements Builder {
  RouterTableBuilder(this._options);

  final BuilderOptions _options;
  late final Set<String> _splitModules = _resolveSplitModules(_options);
  late final String _defaultLoadMode = _resolveDefaultLoadMode(_options);

  /// 同一次 build 中若曾对非入口文件报错，则不再写入任何输出。
  static bool _sawNonEntryFileInThisRun = false;

  /// 使用 .router.g.dart 后缀，避免与 source_gen:combining_builder 的 .g.dart 输出冲突
  static const String _outputSuffix = '.router.g.dart';

  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': [
      _outputSuffix,
      for (final m in _splitModules) '_$m$_outputSuffix',
    ],
  };

  static const String _configHint = '''
请在项目根目录 build.yaml 中仅对路由入口文件触发生成，例如：

targets:
  \$default:
    builders:
      fluro_router_generate|router_library:
        generate_for:
          include:
            - lib/**/**.dart

  请修正 build.yaml 后再重新运行。''';

  static String _configError(String inputPath) =>
      '【生成已终止】未在 build.yaml 的 generate_for.include 中指定路由入口文件，'
      '或当前输入 $inputPath 不是带 @EntranceAnnotation 的入口文件。'
      '必须配置 include 仅包含入口文件，否则报错并立即终止，且不写入任何 .router.g.dart。$_configHint';

  /// 未配置或未在 include 中指定入口文件时：报错并立即终止，不写入任何文件。
  @override
  Future<void> build(BuildStep buildStep) async {
    final outputs = await generateRouterTableContent(
      buildStep,
      allowedSplitModules: _splitModules,
      defaultLoadMode: _defaultLoadMode,
    );
    if (outputs.isEmpty) {
      _sawNonEntryFileInThisRun = true;
      throw BuildException(_configError(buildStep.inputId.path));
    }
    if (_sawNonEntryFileInThisRun) {
      throw BuildException(_configError(buildStep.inputId.path));
    }

    final package = buildStep.inputId.package;
    final basePath = buildStep.inputId.path.replaceFirst(
      RegExp(r'\.dart$'),
      '',
    );

    for (final entry in outputs.entries) {
      final key = entry.key;
      final content = entry.value;
      final path = key.isEmpty
          ? '$basePath$_outputSuffix'
          : '${basePath}_$key$_outputSuffix';
      await buildStep.writeAsString(AssetId(package, path), content);
    }
  }
}

/// 构建校验失败：未标注入口或未正确配置 build.yaml 时抛出。
class BuildException implements Exception {
  final String message;
  BuildException(this.message);
  @override
  String toString() => 'BuildException: $message';
}
