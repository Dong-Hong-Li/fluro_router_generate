import 'package:flutter/material.dart';

/// 页面退出动画方向
/// 注意：手势操作始终是从左边缘向右滑动，此枚举控制的是页面退出的动画方向
enum SwipeDirection {
  /// 页面向右退出（默认，标准iOS风格）
  leftToRight,

  /// 页面向左退出
  rightToLeft,

  /// 页面向下退出
  topToBottom,

  /// 页面向上退出
  bottomToTop,
}

/// 可侧滑返回包装器,始终从左边缘向右滑动触发返回
///
/// 注意：要实现真正的「露出下层页面」效果，需要路由配置 opaque: false
/// 可在 FluroRouter 中配置 RouteSettings 或使用 CupertinoPageRoute
class SwipeBackWrapper extends StatefulWidget {
  final Widget child;
  final double edgeWidth; // 左侧触发区域宽度
  final double dragThreshold; // 拖动超过该比例触发 pop
  final Duration animationDuration;
  final SwipeDirection direction; // 页面退出动画方向

  const SwipeBackWrapper({
    super.key,
    required this.child,
    this.edgeWidth = 60, // iOS 风格的触发区域约 40px
    this.dragThreshold = 0.35,
    this.animationDuration = const Duration(milliseconds: 300),
    this.direction = SwipeDirection.leftToRight,
  });

  @override
  State<SwipeBackWrapper> createState() => _SwipeBackWrapperState();

  /// 静态方法包装（兼容旧签名）
  static Widget wrap(
    BuildContext context,
    Widget child, {
    SwipeDirection direction = SwipeDirection.leftToRight,
  }) => SwipeBackWrapper(direction: direction, child: child);
}

class _SwipeBackWrapperState extends State<SwipeBackWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragStartX = 0.0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
  }

  /// 开始拖拽
  void _onDragStart(DragStartDetails details) {
    // 检查是否为根路由，根路由不允许侧滑
    if (!Navigator.of(context).canPop()) return;

    // 只有从左边缘开始拖拽才生效
    if (details.globalPosition.dx <= widget.edgeWidth) {
      _dragStartX = details.globalPosition.dx;
      _dragging = true;
      _controller.stop();
    }
  }

  /// 拖拽更新
  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    final width = MediaQuery.of(context).size.width;
    final delta = details.globalPosition.dx - _dragStartX;
    final progress = delta / width;
    setState(() {
      _controller.value = progress.clamp(0.0, 1.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;

    final velocity = details.primaryVelocity ?? 0;

    if (_controller.value > widget.dragThreshold || velocity > 500) {
      // 拖拽超过阈值或速度够快，完成返回
      _controller.animateTo(1.0).then((_) {
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      });
    } else {
      // 回弹到原位
      _controller.animateTo(0.0);
    }
  }

  Offset _getTranslateOffset(Size screenSize) {
    final progress = _controller.value;
    switch (widget.direction) {
      case SwipeDirection.leftToRight:
        return Offset(progress * screenSize.width, 0);
      case SwipeDirection.rightToLeft:
        return Offset(-progress * screenSize.width, 0);
      case SwipeDirection.topToBottom:
        return Offset(0, progress * screenSize.height);
      case SwipeDirection.bottomToTop:
        return Offset(0, -progress * screenSize.height);
    }
  }

  Offset _getShadowOffset() {
    switch (widget.direction) {
      case SwipeDirection.leftToRight:
        return const Offset(-10, 0);
      case SwipeDirection.rightToLeft:
        return const Offset(10, 0);
      case SwipeDirection.topToBottom:
        return const Offset(0, -10);
      case SwipeDirection.bottomToTop:
        return const Offset(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final offset = _getTranslateOffset(screenSize);
          return Transform.translate(
            offset: offset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: _controller.value > 0
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: _getShadowOffset(),
                        ),
                      ]
                    : null,
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
