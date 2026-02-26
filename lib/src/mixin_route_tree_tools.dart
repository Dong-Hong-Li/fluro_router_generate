import 'package:flutter/widgets.dart';
import 'package:fluro_router_generate/src/enum.dart';
import 'package:fluro_router_generate/src/extension.dart';
import 'package:fluro_router_generate/src/fluro_route_data.dart';
import 'package:fluro_router_generate/src/fluro_route_match.dart';

/// 将次要功能提取到单独的类中,拆分代码逻辑
mixin RouteTreeTools {
  /// 标准化路径：如果路径以 / 开头，移除它,将路径拆分成多个组件（按 / 分割）。
  /// 检查路径是否为 Navigator.defaultRouteName。如果是默认路径，直接返回 ["/"]
  ///
  /// - `path`：需要标准化的路径
  List<String> normalizePath(String path) {
    if (path == Navigator.defaultRouteName) return ['/'];
    if (path.startsWith('/')) path = path.substring(1);
    return path.split('/');
  }

  ///遍历同级节点,直到找到符合条件的节点路径,返回下一轮需要检查的节点集合
  ///
  ///- `nodesToCheck`：当前需要检查的节点列表
  ///- `pathPart`：当前路径片段
  ///- `nodeMatches`：存储匹配的节点和匹配结果
  ///- `queryMap`：保存当前路径片段中解析出来的查询参数
  ///- `currentMatches`：保存当前路径组件匹配的路由节点和其匹配状态
  ///
  List<RouteTreeNode> matchNodes(
    List<RouteTreeNode> nodesToCheck,
    String pathPart,
    Map<RouteTreeNode, RouteTreeNodeMatch> nodeMatches,
    Map<String, List<String>>? queryMap,
    Map<RouteTreeNode, RouteTreeNodeMatch> currentMatches,
  ) {
    final nextNodes = <RouteTreeNode>[];
    for (final node in nodesToCheck) {
      if ((node.part == pathPart || node.isParameter)) {
        // 用匹配到的节点访问父节点的匹配结果并构建新的匹配结果
        final match = RouteTreeNodeMatch.fromMatch(
          nodeMatches[node.parent]?.parameters ?? {},
          node,
        );
        // 处理参数节点和路径片段包含查询参数
        if (node.isParameter) {
          match.parameters[node.part.substring(1)] = [pathPart];
        }
        if (queryMap != null) match.parameters.addAll(queryMap);

        currentMatches[node] = match;
        nextNodes.addAll(node.nodes);
      }
    }
    return nextNodes;
  }

  /// 解析路径片段中的查询参数
  ///
  /// - `query`：路径片段中的查询参数
  Map<String, List<String>> parseQueryString(String query) {
    final search = RegExp('([^&=]+)=?([^&]*)');
    final params = <String, List<String>>{};

    if (query.startsWith('?')) query = query.substring(1);

    decode(String s) => Uri.decodeComponent(s.replaceAll('+', ' '));

    for (Match match in search.allMatches(query)) {
      final key = decode(match.group(1)!);
      final value = decode(match.group(2)!);

      if (params.containsKey(key)) {
        params[key]!.add(value);
      } else {
        params[key] = [value];
      }
    }

    return params;
  }

  ///在路由树中查找与当前路径组件匹配的节点,如果没有找到，则返回 null。
  ///
  ///- `component`：当前路径组件，例如 home、user、:id 等。
  ///- `parent`：父节点,如果为 null，表示这是根节点。
  ///- `rootNodes`：根节点列表
  RouteTreeNode? nodeForComponent(
    String component,
    RouteTreeNode? parent,
    List<RouteTreeNode> nodes,
  ) {
    // 在父节点的子节点列表 parent.nodes 中查找匹配的节点。
    if (parent != null) nodes = parent.nodes;

    return nodes.firstWhereOrNull((node) => node.part == component);
  }

  /// 根据路径组件的类型返回节点类型
  ///
  /// - `component`：当前路径组件，例如 home、user、`:id` 等。
  RouteTreeNodeType typeForComponent(String component) =>
      component.startsWith(':')
      ? RouteTreeNodeType.parameter
      : RouteTreeNodeType.component;

  /// 打印路由树
  ///
  /// - `rootNodes`：根节点列表
  /// - `parent`：父节点
  /// - `level`：当前节点的层级
  void printSubTree(
    List<RouteTreeNode> rootNodes, {
    RouteTreeNode? parent,
    int level = 0,
  }) {
    final nodes = parent != null ? parent.nodes : rootNodes;

    for (final node in nodes) {
      var indent = '';

      for (var i = 0; i < level; i++) {
        indent += '    ';
      }

      // ignore: avoid_print
      print('$indent${node.part}: total routes=${node.routes.length}');

      if (node.nodes.isNotEmpty) {
        printSubTree(rootNodes, parent: node, level: level + 1);
      }
    }
  }
}
