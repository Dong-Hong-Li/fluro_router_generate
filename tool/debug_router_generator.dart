// 用于调试路由生成器的脚本。
// 走完整链路：RouterTableBuilder.build(buildStep) → generateRouterTableContent → writeAsString，
// 断点可下在 builds.dart 的 build() 或 fluro_router_gen.dart 的 generateRouterTableContent 内。
//
// 运行: dart run tool/debug_router_generator.dart
// 或用 VS Code/Cursor 选择 "Debug router_generator" 启动配置进行调试

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:fluro_router_generate/src/generate/builder/builds.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:package_config/package_config_types.dart';
import 'package:path/path.dart' as p;

void main() async {
  final projectRoot = Directory.current.path;
  final examplePath = p.normalize(p.join(projectRoot, 'example'));
  final entryPath = p.normalize(
    p.absolute(p.join(examplePath, 'lib', 'router', 'router_config.dart')),
  );

  if (!File(entryPath).existsSync()) {
    print('找不到 $entryPath，请确保在 fluro_router_generate 项目根目录运行');
    exit(1);
  }

  final collection = AnalysisContextCollection(includedPaths: [examplePath]);
  final resolver = _FakeResolver(collection, examplePath, 'example');
  final buildStep = _FakeBuildStep(
    inputId: AssetId('example', 'lib/router/router_config.dart'),
    examplePath: examplePath,
    resolver: resolver,
  );

  final builder = RouterTableBuilder();
  await builder.build(buildStep);
  final content = (buildStep).writtenContent;
  if (content == null || content.isEmpty) {
    print('未写入内容（可能入口无 @EntranceAnnotation 或未发现 @RouterAnnotation 页面）');
    return;
  }
  print('--- 生成代码（由 RouterTableBuilder.build 写入）---');
  print(content);
  print('---');
}

/// 仅用于调试的 Resolver：用 analyzer 根据 AssetId 解析出 LibraryElement
class _FakeResolver implements Resolver {
  _FakeResolver(this._collection, this._examplePath, this._package);

  final AnalysisContextCollection _collection;
  final String _examplePath;
  final String _package;

  @override
  Future<LibraryElement> libraryFor(
    AssetId id, {
    bool allowSyntaxErrors = false,
  }) async {
    if (id.package != _package) throw UnimplementedError();
    final fullPath = p.normalize(p.join(_examplePath, id.path));
    final context = _collection.contextFor(fullPath);
    final result = await context.currentSession.getResolvedLibrary(fullPath);
    if (result is! ResolvedLibraryResult) {
      throw StateError('无法解析库: $fullPath -> $result');
    }
    return result.element;
  }

  @override
  Future<bool> isLibrary(AssetId assetId) async =>
      assetId.package == _package && assetId.path.endsWith('.dart');

  @override
  Stream<LibraryElement> get libraries => const Stream.empty();

  @override
  Future<AstNode?> astNodeFor(dynamic fragment, {bool resolve = false}) =>
      throw UnimplementedError();

  @override
  Future<CompilationUnit> compilationUnitFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) => throw UnimplementedError();

  @override
  Future<LibraryElement?> findLibraryByName(String libraryName) =>
      throw UnimplementedError();

  @override
  Future<AssetId> assetIdForElement(Element element) =>
      throw UnimplementedError();
}

/// 仅用于调试的 BuildStep：提供 inputId、resolver、findAssets，其余占位
class _FakeBuildStep implements BuildStep {
  _FakeBuildStep({
    required this.inputId,
    required this.examplePath,
    required Resolver resolver,
  }) : _resolver = resolver;

  @override
  final AssetId inputId;
  final String examplePath;
  final Resolver _resolver;

  /// 调试用：Builder.build() 通过 writeAsString 写入的内容会存到这里
  String? writtenContent;

  @override
  Iterable<AssetId> get allowedOutputs => [];

  @override
  Resolver get resolver => _resolver;

  @override
  T trackStage<T>(
    String label,
    T Function() action, {
    bool isExternal = false,
  }) => action();

  @override
  Stream<AssetId> findAssets(Glob glob) async* {
    final pattern = glob.pattern;
    if (pattern != 'lib/**/*.dart') throw UnimplementedError();
    for (final entity in glob.listSync(root: examplePath)) {
      if (entity is! File) continue;
      final path = entity.path;
      if (!path.endsWith('.dart')) continue;
      if (path.endsWith('.g.dart')) continue;
      final relative = p.relative(path, from: examplePath);
      yield AssetId('example', relative.replaceAll(r'\', '/'));
    }
  }

  @override
  Future<LibraryElement> get inputLibrary => resolver.libraryFor(inputId);

  @override
  Future<PackageConfig> get packageConfig => throw UnimplementedError();

  @override
  Future<List<int>> readAsBytes(AssetId id) => throw UnimplementedError();

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) =>
      throw UnimplementedError();

  @override
  Future<bool> canRead(AssetId id) => throw UnimplementedError();

  @override
  Future<Digest> digest(AssetId id) => throw UnimplementedError();

  @override
  Future<void> writeAsBytes(AssetId id, FutureOr<List<int>> bytes) =>
      throw UnimplementedError();

  @override
  Future<void> writeAsString(
    AssetId id,
    FutureOr<String> contents, {
    Encoding encoding = utf8,
  }) async {
    writtenContent = await Future.value(contents);
  }

  @override
  Future<T> fetchResource<T>(Resource<T> resource) =>
      throw UnimplementedError();

  @override
  void reportUnusedAssets(Iterable<AssetId> ids) {}
}
