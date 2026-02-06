import 'package:build/build.dart';
import 'package:fluro_router_generate/src/generate/fluro_router_gen.dart';

/// build_runner 入口：返回实现 [Builder] 的路由表生成器。
/// 可通过 [BuilderOptions.config] 的 `split_modules` 动态增加可分文件的模块名。
Builder buildRouter(BuilderOptions options) {
  return RouterTableBuilder(options);
}

/// 从 [BuilderOptions] 解析「允许拆分为独立文件」的模块名，与 [defaultSplitModules] 合并。
/// build.yaml 示例：builders: fluro_router_generate|router_library: options: { split_modules: [payment, admin] }
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

/// 仅对带 [EntranceAnnotation] 的入口文件运行，绝不对全量 .dart 跑。
/// 若当前输入未标注入口注解，直接报错并提示配置 build.yaml。
/// 支持分文件：主文件 + 各模块文件；允许拆分的模块 = [defaultSplitModules] + build.yaml 的 split_modules。
class RouterTableBuilder implements Builder {
  RouterTableBuilder(this._options);

  final BuilderOptions _options;
  late final Set<String> _splitModules = _resolveSplitModules(_options);

  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.g.dart', for (final m in _splitModules) '_$m.g.dart'],
  };

  static const String _configHint = '''
请在项目根目录 build.yaml 中仅对路由入口文件触发生成，例如：

targets:
  \$default:
    builders:
      fluro_router_generate|router_library:
        generate_for:
          include:
            - lib/router/router_config.dart''';

  @override
  Future<void> build(BuildStep buildStep) async {
    final outputs = await generateRouterTableContent(
      buildStep,
      allowedSplitModules: _splitModules,
    );
    if (outputs.isEmpty) {
      throw BuildException(
        'fluro_router_generate|router_library 仅允许对带 @EntranceAnnotation 的入口文件运行。'
        '当前输入 ${buildStep.inputId.path} 未标注入口注解。$_configHint',
      );
    }

    final package = buildStep.inputId.package;
    final basePath = buildStep.inputId.path.replaceFirst(
      RegExp(r'\.dart$'),
      '',
    );

    for (final entry in outputs.entries) {
      final key = entry.key;
      final content = entry.value;
      final path = key.isEmpty ? '$basePath.g.dart' : '${basePath}_$key.g.dart';
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
