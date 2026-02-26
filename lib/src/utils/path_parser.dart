/// 从 path 解析路径参数名：/home/:id → [id]，/user/:userId/post/:postId → [userId, postId]
List<String> pathParamNames(String path) {
  final basePath = path.contains('?') ? path.split('?').first : path;
  final segments = basePath.split('/');
  final names = <String>[];
  for (final s in segments) {
    if (s.startsWith(':')) names.add(s.substring(1));
  }
  return names;
}

/// 从 path 解析查询参数名：/home?id=1&name=2 → [id, name]
List<String> queryParamNames(String path) {
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
