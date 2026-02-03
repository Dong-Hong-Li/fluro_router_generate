import 'package:flutter/widgets.dart';
import 'package:fluro_router_generate/src/enum.dart';
import 'package:fluro_router_generate/src/fluro_route_data.dart';
import 'package:fluro_router_generate/src/fluro_route_match.dart';
import 'package:fluro_router_generate/src/mixin_route_tree_tools.dart';

///用来存储和管理路由节点树
class FluroRouteStorager with RouteTreeTools {
  ///`_nodes` 列表中保存的是路径的根节点树,例: `home/user/:id/search`保存的是home节点 -> user节点 -> :id节点 -> search节点
  final _nodes = <RouteTreeNode>[];

  /// 标记是否已经定义了默认路由
  bool _hasDefaultRoute = false;

  ///添加路由
  void addRoute(FluroRouteData routeData) {
    String path = routeData.route;

    // 处理根路径
    if (path == Navigator.defaultRouteName) {
      if (_hasDefaultRoute) throw ("Default route was already defined");
      final node = RouteTreeNode(path, RouteTreeNodeType.component)
        ..routes = [routeData];
      _nodes.add(node);
      _hasDefaultRoute = true;
      return;
    }

    if (path.startsWith("/")) path = path.substring(1);
    final pathComponents = path.split('/');

    // 逐层构建路由树
    RouteTreeNode? parent;
    for (int i = 0; i < pathComponents.length; i++) {
      String itemFragment = pathComponents[i];
      RouteTreeNode? node = nodeForComponent(itemFragment, parent, _nodes);
      if (node == null) {
        node = RouteTreeNode(itemFragment, typeForComponent(itemFragment))
          ..parent = parent;

        // 如果没有父节点，添加到根节点列表
        // 如果当前节点有父节点，添加到父节点的子节点列表
        parent == null ? _nodes.add(node) : parent.nodes.add(node);
      }

      // 如果是路径的最后一个组件，将路由添加到节点的 `routes` 列表中
      if (i == pathComponents.length - 1) node.routes.add(routeData);
      parent = node;
    }
  }

  ///在路由树中查找与路径匹配的路由，并解析路径参数和查询参数。
  AppRouteMatchResult? matchRoute(String path) {
    // 存储匹配的节点和匹配结果
    var nodeMatches = <RouteTreeNode, RouteTreeNodeMatch>{};

    // 保存当前需要检查的节点列表
    var rootNodes = _nodes;

    List<String> pathComponents = normalizePath(path);

    for (var pathFragment in pathComponents) {
      /// 保存当前路径片段中解析出来的查询参数
      Map<String, List<String>>? queryMap;
      if (pathFragment.contains("?")) {
        final splitParam = pathFragment.split("?");
        pathFragment = splitParam[0];
        queryMap = parseQueryString(splitParam[1]);
      }

      final currentMatches = <RouteTreeNode, RouteTreeNodeMatch>{};

      /// 返回下一轮需要检查的节点集合。
      rootNodes = matchNodes(
        rootNodes,
        pathFragment,
        nodeMatches,
        queryMap,
        currentMatches,
      );
      nodeMatches = currentMatches;

      if (currentMatches.values.isEmpty) return null;
    }

    final matches = nodeMatches.values.toList();

    // 匹配到多个结果，则返回第一个匹配结果
    if (matches.isNotEmpty) {
      RouteTreeNodeMatch match = matches.first;
      List<FluroRouteData> routeDatas = match.node.routes;
      if (routeDatas.isNotEmpty) {
        return AppRouteMatchResult(routeDatas.first)
          ..parameters = match.parameters;
      }
    }

    return null;
  }

  void printTree() => printSubTree(_nodes);
}
