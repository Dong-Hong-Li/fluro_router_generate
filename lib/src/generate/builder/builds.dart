import 'package:build/build.dart';
import 'package:fluro_router_generate/src/generate/fluro_router_gen.dart';

/// build_runner 入口：返回实现 [Builder] 的路由表生成器。
Builder buildRouter(BuilderOptions options) {
  return RouterTableBuilder();
}

/// 仅对带 [EntranceAnnotation] 的入口文件运行，绝不对全量 .dart 跑。
/// 若当前输入未标注入口注解，直接报错并提示配置 build.yaml。
class RouterTableBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
    '.dart': ['.g.dart'],
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
    final content = await generateRouterTableContent(buildStep);
    if (content.isEmpty) {
      throw BuildException(
        'fluro_router_generate|router_library 仅允许对带 @EntranceAnnotation 的入口文件运行。'
        '当前输入 ${buildStep.inputId.path} 未标注入口注解。$_configHint',
      );
    }

    // 生成文件的输出路径
    final outputPath = buildStep.inputId.path.replaceFirst(
      RegExp(r'\.dart$'),
      '.g.dart',
    );

    // 生成文件的输出 ID
    final outputId = AssetId(buildStep.inputId.package, outputPath);

    // 写入生成文件的内容
    await buildStep.writeAsString(outputId, content);
  }
}

/// 构建校验失败：未标注入口或未正确配置 build.yaml 时抛出。
class BuildException implements Exception {
  final String message;
  BuildException(this.message);
  @override
  String toString() => 'BuildException: $message';
}
