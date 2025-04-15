import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mpay_app/utils/performance_optimizer.dart';
import 'package:mpay_app/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;

class LazyLoadingListView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final Widget? separator;
  final Widget? emptyWidget;
  final Future<void> Function()? onRefresh;
  final Function()? onEndReached;
  final double endReachedThreshold;
  final bool reverse;
  final String? noItemsMessage;
  final IconData? noItemsIcon;
  final bool showScrollbar;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final int? semanticChildCount;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  const LazyLoadingListView({
    Key? key,
    required this.itemCount,
    required this.itemBuilder,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    this.controller,
    this.separator,
    this.emptyWidget,
    this.onRefresh,
    this.onEndReached,
    this.endReachedThreshold = 200.0,
    this.reverse = false,
    this.noItemsMessage,
    this.noItemsIcon,
    this.showScrollbar = true,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.semanticChildCount,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
  }) : super(key: key);

  @override
  State<LazyLoadingListView> createState() => _LazyLoadingListViewState();
}

class _LazyLoadingListViewState extends State<LazyLoadingListView> with SingleTickerProviderStateMixin {
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  late AnimationController _loadingAnimationController;
  bool _hasShownEmptyState = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_scrollListener);
    
    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // Add haptic feedback when reaching the end
    if (widget.onEndReached != null) {
      _scrollController.addListener(() {
        if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
          HapticFeedback.lightImpact();
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_scrollListener);
    }
    _loadingAnimationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_optimizer.enableLazyLoading || widget.onEndReached == null) return;

    if (_scrollController.position.extentAfter < widget.endReachedThreshold && !_isLoadingMore) {
      _isLoadingMore = true;
      widget.onEndReached!();
      // Reset the flag after a short delay to prevent multiple calls
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  Widget _buildEmptyState() {
    if (widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }
    
    if (!_hasShownEmptyState) {
      // Delay showing the empty state to avoid flashing it during initial load
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _hasShownEmptyState = true;
          });
        }
      });
      return const SizedBox.shrink();
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.noItemsIcon ?? Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.noItemsMessage ?? 'لا توجد عناصر للعرض',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.onRefresh != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _loadingAnimationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _loadingAnimationController.value * 2 * math.pi,
                  child: const CircularProgressIndicator(),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'جاري التحميل...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0) {
      return _buildEmptyState();
    }

    Widget listView;
    
    if (widget.separator != null) {
      listView = ListView.separated(
        controller: _scrollController,
        itemCount: widget.itemCount + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => widget.separator!,
        itemBuilder: (context, index) {
          if (index == widget.itemCount && _isLoadingMore) {
            return _buildLoadingIndicator();
          }
          return widget.itemBuilder(context, index);
        },
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        padding: widget.padding,
        reverse: widget.reverse,
        addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
        addRepaintBoundaries: widget.addRepaintBoundaries,
        addSemanticIndexes: widget.addSemanticIndexes,
        semanticChildCount: widget.semanticChildCount,
        keyboardDismissBehavior: widget.keyboardDismissBehavior,
      );
    } else {
      listView = ListView.builder(
        controller: _scrollController,
        itemCount: widget.itemCount + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.itemCount && _isLoadingMore) {
            return _buildLoadingIndicator();
          }
          return widget.itemBuilder(context, index);
        },
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        padding: widget.padding,
        reverse: widget.reverse,
        addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
        addRepaintBoundaries: widget.addRepaintBoundaries,
        addSemanticIndexes: widget.addSemanticIndexes,
        semanticChildCount: widget.semanticChildCount,
        keyboardDismissBehavior: widget.keyboardDismissBehavior,
      );
    }

    if (widget.showScrollbar) {
      listView = Scrollbar(
        controller: _scrollController,
        thickness: 6.0,
        radius: const Radius.circular(10.0),
        child: listView,
      );
    }

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          return widget.onRefresh!();
        },
        displacement: 20.0,
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surface,
        strokeWidth: 3.0,
        triggerMode: RefreshIndicatorTriggerMode.onEdge,
        child: listView,
      );
    }

    return listView;
  }
}

class OptimizedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Color? color;
  final BlendMode? colorBlendMode;
  final bool useCaching;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final bool showLoadingShimmer;
  final Duration fadeInDuration;
  final Curve fadeInCurve;
  final bool enableHeroAnimation;
  final String? heroTag;
  final VoidCallback? onTap;
  final bool enableZoom;

  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loadingBuilder,
    this.errorBuilder,
    this.color,
    this.colorBlendMode,
    this.useCaching = true,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.showLoadingShimmer = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeInCurve = Curves.easeIn,
    this.enableHeroAnimation = false,
    this.heroTag,
    this.onTap,
    this.enableZoom = false,
  }) : super(key: key);

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> with SingleTickerProviderStateMixin {
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  bool _isLoading = true;
  bool _hasError = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.fadeInDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: widget.fadeInCurve,
    );
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  
  Widget _buildErrorWidget() {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, Exception('Failed to load image'), null);
    }
    
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: widget.borderRadius,
        border: widget.border,
        boxShadow: widget.boxShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'فشل تحميل الصورة',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.onTap != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: widget.onTap,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('إعادة المحاولة'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: const Size(100, 30),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildLoadingWidget() {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context, Container(), null);
    }
    
    if (widget.showLoadingShimmer) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: widget.borderRadius,
          ),
        ),
      );
    }
    
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius,
        border: widget.border,
        boxShadow: widget.boxShadow,
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  Widget _buildImageWidget() {
    Widget imageWidget;
    
    if (widget.useCaching && _optimizer.enableImageCaching) {
      imageWidget = CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        color: widget.color,
        colorBlendMode: widget.colorBlendMode,
        fadeInDuration: widget.fadeInDuration,
        fadeInCurve: widget.fadeInCurve,
        progressIndicatorBuilder: (_, __, ___) => _buildLoadingWidget(),
        errorWidget: (_, __, ___) => _buildErrorWidget(),
      );
    } else {
      if (widget.imageUrl.startsWith('http') || widget.imageUrl.startsWith('https')) {
        imageWidget = Image.network(
          widget.imageUrl,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          color: widget.color,
          colorBlendMode: widget.colorBlendMode,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              _isLoading = false;
              _fadeController.forward();
              return FadeTransition(
                opacity: _fadeAnimation,
                child: child,
              );
            }
            return _buildLoadingWidget();
          },
          errorBuilder: (context, error, stackTrace) {
            _hasError = true;
            return _buildErrorWidget();
          },
        );
      } else {
        imageWidget = Image.asset(
          widget.imageUrl,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          color: widget.color,
          colorBlendMode: widget.colorBlendMode,
          errorBuilder: (context, error, stackTrace) {
            _hasError = true;
            return _buildErrorWidget();
          },
        );
      }
    }
    
    if (widget.borderRadius != null || widget.border != null || widget.boxShadow != null) {
      imageWidget = Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: widget.border,
          boxShadow: widget.boxShadow,
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: imageWidget,
        ),
      );
    }
    
    if (widget.enableZoom) {
      imageWidget = InteractiveViewer(
        minScale: 0.5,
        maxScale: 3.0,
        child: imageWidget,
      );
    }
    
    if (widget.onTap != null) {
      imageWidget = GestureDetector(
        onTap: widget.onTap,
        child: imageWidget,
      );
    }
    
    if (widget.enableHeroAnimation) {
      final heroTag = widget.heroTag ?? widget.imageUrl;
      imageWidget = Hero(
        tag: heroTag,
        child: imageWidget,
      );
    }
    
    return imageWidget;
  }

  @override
  Widget build(BuildContext context) {
    return _buildImageWidget();
  }
}

class OptimizedFutureBuilder<T> extends StatefulWidget {
  final Future<T> Function() futureBuilder;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, Object? error)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final String cacheKey;
  final bool useCaching;
  final Duration refreshInterval;
  final bool showLoadingIndicator;
  final bool retryOnError;
  final int maxRetryAttempts;
  final Duration retryDelay;
  final bool showErrorDetails;
  final VoidCallback? onRetry;
  final VoidCallback? onSuccess;
  final Function(Object?)? onError;

  const OptimizedFutureBuilder({
    Key? key,
    required this.futureBuilder,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    required this.cacheKey,
    this.useCaching = true,
    this.refreshInterval = const Duration(minutes: 5),
    this.showLoadingIndicator = true,
    this.retryOnError = true,
    this.maxRetryAttempts = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.showErrorDetails = false,
    this.onRetry,
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  State<OptimizedFutureBuilder<T>> createState() => _OptimizedFutureBuilderState<T>();
}

class _OptimizedFutureBuilderState<T> extends State<OptimizedFutureBuilder<T>> with SingleTickerProviderStateMixin {
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  late Future<T> _future;
  T? _cachedData;
  DateTime? _lastRefreshTime;
  bool _isRefreshing = false;
  int _retryAttempts = 0;
  Object? _lastError;
  late AnimationController _loadingAnimationController;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _initializeFuture();
  }

  @override
  void dispose() {
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OptimizedFutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey) {
      _initializeFuture();
    } else if (_shouldRefresh()) {
      _refreshData();
    }
  }

  void _initializeFuture() {
    if (widget.useCaching && _optimizer.enableDataCaching) {
      _cachedData = _optimizer.getCachedData(widget.cacheKey) as T?;
    }

    if (_cachedData != null) {
      // Use cached data and refresh in background if needed
      _future = Future.value(_cachedData);
      _isFirstLoad = false;
      if (_shouldRefresh()) {
        _refreshData();
      }
    } else {
      // No cached data, load fresh data
      _future = _loadData();
    }
  }

  Future<T> _loadData() async {
    try {
      final data = await widget.futureBuilder();
      
      if (widget.useCaching && _optimizer.enableDataCaching) {
        _optimizer.cacheData(widget.cacheKey, data);
      }
      
      _lastRefreshTime = DateTime.now();
      _retryAttempts = 0;
      _lastError = null;
      _isFirstLoad = false;
      
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
      
      return data;
    } catch (e) {
      _lastError = e;
      
      if (widget.onError != null) {
        widget.onError!(e);
      }
      
      if (widget.retryOnError && _retryAttempts < widget.maxRetryAttempts) {
        _retryAttempts++;
        await Future.delayed(widget.retryDelay * _retryAttempts);
        return _loadData();
      }
      
      rethrow;
    }
  }

  bool _shouldRefresh() {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!) > widget.refreshInterval;
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    try {
      final freshData = await widget.futureBuilder();
      if (widget.useCaching && _optimizer.enableDataCaching) {
        _optimizer.cacheData(widget.cacheKey, freshData);
      }
      
      if (mounted) {
        setState(() {
          _cachedData = freshData;
          _lastRefreshTime = DateTime.now();
          _future = Future.value(freshData);
          _isRefreshing = false;
        });
      }
      
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
    } catch (e) {
      _isRefreshing = false;
      _lastError = e;
      
      if (widget.onError != null) {
        widget.onError!(e);
      }
      // Error during background refresh, but we still have cached data
      // so we don't need to update the UI
    }
  }

  Widget _buildLoadingWidget() {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context);
    }
    
    if (!widget.showLoadingIndicator) {
      return const SizedBox.shrink();
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingAnimationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loadingAnimationController.value * 2 * math.pi,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'جاري التحميل...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object? error) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error);
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ أثناء تحميل البيانات',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.showErrorDetails && error != null) ...[
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                if (widget.onRetry != null) {
                  widget.onRetry!();
                }
                setState(() {
                  _retryAttempts = 0;
                  _future = _loadData();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _cachedData == null) {
          return _buildLoadingWidget();
        } else if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error);
        } else if (snapshot.hasData) {
          return widget.builder(context, snapshot.data as T);
        } else {
          return _buildLoadingWidget();
        }
      },
    );
  }
}

class AnimatedFeedbackButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool enableHapticFeedback;
  final bool enableScaleAnimation;
  final Duration animationDuration;
  final bool isLoading;
  final String? loadingText;
  final bool isDisabled;
  final String? disabledTooltip;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final double elevation;

  const AnimatedFeedbackButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.width,
    this.height,
    this.borderRadius,
    this.enableHapticFeedback = true,
    this.enableScaleAnimation = true,
    this.animationDuration = const Duration(milliseconds: 150),
    this.isLoading = false,
    this.loadingText,
    this.isDisabled = false,
    this.disabledTooltip,
    this.border,
    this.boxShadow,
    this.elevation = 2.0,
  }) : super(key: key);

  @override
  State<AnimatedFeedbackButton> createState() => _AnimatedFeedbackButtonState();
}

class _AnimatedFeedbackButtonState extends State<AnimatedFeedbackButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isDisabled || widget.isLoading) return;
    
    if (widget.enableScaleAnimation) {
      _animationController.forward();
    }
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isDisabled || widget.isLoading) return;
    
    if (widget.enableScaleAnimation) {
      _animationController.reverse();
    }
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTapCancel() {
    if (widget.isDisabled || widget.isLoading) return;
    
    if (widget.enableScaleAnimation) {
      _animationController.reverse();
    }
    setState(() {
      _isPressed = false;
    });
  }

  void _handleTap() {
    if (widget.isDisabled || widget.isLoading) return;
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final foregroundColor = widget.foregroundColor ?? theme.colorScheme.onPrimary;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(AppTheme.borderRadiusMedium);
    
    Widget buttonContent;
    
    if (widget.isLoading) {
      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          if (widget.loadingText != null) ...[
            const SizedBox(width: 8),
            Text(
              widget.loadingText!,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      );
    } else {
      buttonContent = widget.child;
    }
    
    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.isDisabled
                  ? backgroundColor.withOpacity(0.5)
                  : _isPressed
                      ? backgroundColor.withOpacity(0.8)
                      : backgroundColor,
              borderRadius: borderRadius,
              border: widget.border,
              boxShadow: _isPressed
                  ? null
                  : widget.boxShadow ??
                      [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: widget.elevation,
                          offset: const Offset(0, 2),
                        ),
                      ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.isDisabled || widget.isLoading ? null : _handleTap,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                borderRadius: borderRadius,
                splashColor: foregroundColor.withOpacity(0.1),
                highlightColor: foregroundColor.withOpacity(0.05),
                child: Padding(
                  padding: widget.padding,
                  child: Center(
                    child: buttonContent,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    
    if (widget.isDisabled && widget.disabledTooltip != null) {
      button = Tooltip(
        message: widget.disabledTooltip!,
        child: button,
      );
    }
    
    return button;
  }
}

class ShimmerLoadingPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration period;

  const ShimmerLoadingPlaceholder({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.margin,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColorValue = baseColor ?? 
        (theme.brightness == Brightness.light ? Colors.grey[300]! : Colors.grey[700]!);
    final highlightColorValue = highlightColor ?? 
        (theme.brightness == Brightness.light ? Colors.grey[100]! : Colors.grey[600]!);

    return Shimmer.fromColors(
      baseColor: baseColorValue,
      highlightColor: highlightColorValue,
      period: period,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: shape == BoxShape.circle ? null : (borderRadius ?? BorderRadius.circular(AppTheme.borderRadiusSmall)),
          shape: shape,
        ),
      ),
    );
  }
}

class AnimatedProgressButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Future<bool> Function() action;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? successColor;
  final Color? errorColor;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Duration animationDuration;
  final String? loadingText;
  final String? successText;
  final String? errorText;
  final IconData? successIcon;
  final IconData? errorIcon;
  final Duration resultDisplayDuration;

  const AnimatedProgressButton({
    Key? key,
    required this.onPressed,
    required this.child,
    required this.action,
    this.backgroundColor,
    this.foregroundColor,
    this.successColor,
    this.errorColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.width,
    this.height,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 300),
    this.loadingText,
    this.successText,
    this.errorText,
    this.successIcon,
    this.errorIcon,
    this.resultDisplayDuration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<AnimatedProgressButton> createState() => _AnimatedProgressButtonState();
}

class _AnimatedProgressButtonState extends State<AnimatedProgressButton> with SingleTickerProviderStateMixin {
  ButtonState _state = ButtonState.idle;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _performAction() async {
    if (_state != ButtonState.idle) return;
    
    setState(() {
      _state = ButtonState.loading;
    });
    
    try {
      final result = await widget.action();
      
      if (!mounted) return;
      
      setState(() {
        _state = result ? ButtonState.success : ButtonState.error;
      });
      
      await Future.delayed(widget.resultDisplayDuration);
      
      if (!mounted) return;
      
      setState(() {
        _state = ButtonState.idle;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _state = ButtonState.error;
      });
      
      await Future.delayed(widget.resultDisplayDuration);
      
      if (!mounted) return;
      
      setState(() {
        _state = ButtonState.idle;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final foregroundColor = widget.foregroundColor ?? theme.colorScheme.onPrimary;
    final successColor = widget.successColor ?? theme.colorScheme.primary;
    final errorColor = widget.errorColor ?? theme.colorScheme.error;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(AppTheme.borderRadiusMedium);
    
    Color currentBackgroundColor;
    Color currentForegroundColor;
    Widget buttonContent;
    
    switch (_state) {
      case ButtonState.idle:
        currentBackgroundColor = backgroundColor;
        currentForegroundColor = foregroundColor;
        buttonContent = widget.child;
        break;
      case ButtonState.loading:
        currentBackgroundColor = backgroundColor;
        currentForegroundColor = foregroundColor;
        buttonContent = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(currentForegroundColor),
              ),
            ),
            if (widget.loadingText != null) ...[
              const SizedBox(width: 8),
              Text(
                widget.loadingText!,
                style: TextStyle(
                  color: currentForegroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        );
        break;
      case ButtonState.success:
        currentBackgroundColor = successColor;
        currentForegroundColor = theme.colorScheme.onPrimary;
        buttonContent = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.successIcon ?? Icons.check_circle,
              color: currentForegroundColor,
            ),
            if (widget.successText != null) ...[
              const SizedBox(width: 8),
              Text(
                widget.successText!,
                style: TextStyle(
                  color: currentForegroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        );
        break;
      case ButtonState.error:
        currentBackgroundColor = errorColor;
        currentForegroundColor = theme.colorScheme.onError;
        buttonContent = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.errorIcon ?? Icons.error,
              color: currentForegroundColor,
            ),
            if (widget.errorText != null) ...[
              const SizedBox(width: 8),
              Text(
                widget.errorText!,
                style: TextStyle(
                  color: currentForegroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        );
        break;
    }
    
    return AnimatedContainer(
      duration: widget.animationDuration,
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: currentBackgroundColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: currentBackgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: _state == ButtonState.idle ? () {
            widget.onPressed();
            _performAction();
            HapticFeedback.lightImpact();
          } : null,
          borderRadius: borderRadius,
          splashColor: currentForegroundColor.withOpacity(0.1),
          highlightColor: currentForegroundColor.withOpacity(0.05),
          child: Padding(
            padding: widget.padding,
            child: Center(
              child: AnimatedSwitcher(
                duration: widget.animationDuration,
                child: buttonContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ButtonState {
  idle,
  loading,
  success,
  error,
}

class CustomTabBar extends StatefulWidget {
  final List<String> tabs;
  final int initialIndex;
  final Function(int) onTabChanged;
  final Color? backgroundColor;
  final Color? selectedTabColor;
  final Color? unselectedTabColor;
  final Color? indicatorColor;
  final TextStyle? selectedTextStyle;
  final TextStyle? unselectedTextStyle;
  final double height;
  final double indicatorHeight;
  final bool showIndicator;
  final bool enableHapticFeedback;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final List<Widget>? tabIcons;

  const CustomTabBar({
    Key? key,
    required this.tabs,
    this.initialIndex = 0,
    required this.onTabChanged,
    this.backgroundColor,
    this.selectedTabColor,
    this.unselectedTabColor,
    this.indicatorColor,
    this.selectedTextStyle,
    this.unselectedTextStyle,
    this.height = 48.0,
    this.indicatorHeight = 3.0,
    this.showIndicator = true,
    this.enableHapticFeedback = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.borderRadius,
    this.tabIcons,
  })  : assert(tabIcons == null || tabIcons.length == tabs.length),
        super(key: key);

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _indicatorAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTabSelection(int index) {
    if (index == _selectedIndex) return;
    
    setState(() {
      _selectedIndex = index;
    });
    
    _animationController.reset();
    _animationController.forward();
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    
    widget.onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.surface;
    final selectedTabColor = widget.selectedTabColor ?? theme.colorScheme.primary;
    final unselectedTabColor = widget.unselectedTabColor ?? theme.colorScheme.onSurface.withOpacity(0.7);
    final indicatorColor = widget.indicatorColor ?? theme.colorScheme.primary;
    
    final selectedTextStyle = widget.selectedTextStyle ?? 
        theme.textTheme.titleSmall?.copyWith(
          color: selectedTabColor,
          fontWeight: FontWeight.bold,
        );
    
    final unselectedTextStyle = widget.unselectedTextStyle ?? 
        theme.textTheme.titleSmall?.copyWith(
          color: unselectedTabColor,
          fontWeight: FontWeight.normal,
        );
    
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: widget.borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: widget.padding,
        child: Row(
          children: List.generate(widget.tabs.length, (index) {
            final isSelected = index == _selectedIndex;
            
            return Expanded(
              child: GestureDetector(
                onTap: () => _handleTabSelection(index),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: widget.tabIcons != null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  widget.tabIcons![index],
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.tabs[index],
                                    style: isSelected ? selectedTextStyle : unselectedTextStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              )
                            : Text(
                                widget.tabs[index],
                                style: isSelected ? selectedTextStyle : unselectedTextStyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ),
                    if (widget.showIndicator)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: widget.indicatorHeight,
                        width: isSelected ? 24 : 0,
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          borderRadius: BorderRadius.circular(widget.indicatorHeight / 2),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final String? customText;
  final IconData? icon;
  final double? size;
  final bool isDarkMode;
  final VoidCallback? onTap;
  final bool showAnimation;

  const StatusBadge({
    Key? key,
    required this.status,
    this.customText,
    this.icon,
    this.size,
    this.isDarkMode = false,
    this.onTap,
    this.showAnimation = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(status, isDarkMode: isDarkMode);
    final backgroundColor = statusColor.withOpacity(0.15);
    final textColor = statusColor;
    
    IconData statusIcon;
    String statusText = customText ?? status;
    
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'approved':
        statusIcon = icon ?? Icons.check_circle;
        break;
      case 'pending':
      case 'processing':
      case 'waiting':
        statusIcon = icon ?? Icons.hourglass_empty;
        break;
      case 'failed':
      case 'rejected':
      case 'cancelled':
        statusIcon = icon ?? Icons.cancel;
        break;
      case 'info':
      case 'notice':
        statusIcon = icon ?? Icons.info;
        break;
      default:
        statusIcon = icon ?? Icons.circle;
    }
    
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: size ?? 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontSize: size != null ? size * 0.9 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
    
    if (showAnimation) {
      if (status.toLowerCase() == 'pending' || 
          status.toLowerCase() == 'processing' || 
          status.toLowerCase() == 'waiting') {
        badge = TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: child,
            );
          },
          child: badge,
        );
      }
    }
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }
    
    return badge;
  }
}

class CurrencyBadge extends StatelessWidget {
  final String currencyCode;
  final String? amount;
  final IconData? customIcon;
  final double? size;
  final VoidCallback? onTap;
  final bool showFullName;

  const CurrencyBadge({
    Key? key,
    required this.currencyCode,
    this.amount,
    this.customIcon,
    this.size,
    this.onTap,
    this.showFullName = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyColor = AppTheme.getCurrencyColor(currencyCode);
    final backgroundColor = currencyColor.withOpacity(0.15);
    
    IconData currencyIcon;
    String displayCode = currencyCode.toUpperCase();
    String? fullName;
    
    switch (displayCode) {
      case 'USDT':
        currencyIcon = customIcon ?? Icons.monetization_on;
        fullName = 'Tether';
        break;
      case 'BTC':
        currencyIcon = customIcon ?? Icons.currency_bitcoin;
        fullName = 'Bitcoin';
        break;
      case 'ETH':
        currencyIcon = customIcon ?? Icons.diamond;
        fullName = 'Ethereum';
        break;
      case 'SHAM':
        currencyIcon = customIcon ?? Icons.account_balance_wallet;
        fullName = 'Sham Cash';
        break;
      default:
        currencyIcon = customIcon ?? Icons.attach_money;
        fullName = displayCode;
    }
    
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: currencyColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            currencyIcon,
            size: size ?? 14,
            color: currencyColor,
          ),
          const SizedBox(width: 4),
          if (amount != null) ...[
            Text(
              amount!,
              style: TextStyle(
                color: currencyColor,
                fontSize: size != null ? size * 0.9 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            showFullName ? '$displayCode ($fullName)' : displayCode,
            style: TextStyle(
              color: currencyColor,
              fontSize: size != null ? size * 0.9 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }
    
    return badge;
  }
}

class CustomSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? iconColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? height;
  final bool autofocus;
  final FocusNode? focusNode;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;

  const CustomSearchBar({
    Key? key,
    this.controller,
    this.hintText = 'بحث...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.backgroundColor,
    this.textColor,
    this.hintColor,
    this.iconColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.height,
    this.autofocus = false,
    this.focusNode,
    this.border,
    this.boxShadow,
    this.prefix,
    this.suffix,
    this.textInputAction = TextInputAction.search,
    this.keyboardType = TextInputType.text,
  }) : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  void _clearSearch() {
    _controller.clear();
    if (widget.onChanged != null) {
      widget.onChanged!('');
    }
    if (widget.onClear != null) {
      widget.onClear!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.surface;
    final textColor = widget.textColor ?? theme.colorScheme.onSurface;
    final hintColor = widget.hintColor ?? theme.colorScheme.onSurface.withOpacity(0.5);
    final iconColor = widget.iconColor ?? theme.colorScheme.primary;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(AppTheme.borderRadiusMedium);
    
    return Container(
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: widget.border ?? Border.all(
          color: _hasFocus 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withOpacity(0.3),
          width: _hasFocus ? 2.0 : 1.0,
        ),
        boxShadow: widget.boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            widget.prefix ?? Icon(
              Icons.search,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: hintColor,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                textInputAction: widget.textInputAction,
                keyboardType: widget.keyboardType,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
              ),
            ),
            if (_controller.text.isNotEmpty)
              GestureDetector(
                onTap: _clearSearch,
                child: Icon(
                  Icons.close,
                  color: iconColor,
                  size: 20,
                ),
              )
            else if (widget.suffix != null)
              widget.suffix!,
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? subMessage;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? messageStyle;
  final TextStyle? subMessageStyle;
  final EdgeInsetsGeometry padding;
  final Widget? customAction;
  final Widget? illustration;

  const EmptyStateWidget({
    Key? key,
    required this.message,
    this.subMessage,
    this.icon = Icons.inbox_outlined,
    this.onActionPressed,
    this.actionLabel,
    this.iconSize,
    this.iconColor,
    this.messageStyle,
    this.subMessageStyle,
    this.padding = const EdgeInsets.all(24.0),
    this.customAction,
    this.illustration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (illustration != null)
              illustration!
            else
              Icon(
                icon,
                size: iconSize ?? 80,
                color: iconColor ?? theme.colorScheme.primary.withOpacity(0.5),
              ),
            const SizedBox(height: 24),
            Text(
              message,
              style: messageStyle ?? theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onBackground,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subMessage!,
                style: subMessageStyle ?? theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onActionPressed!();
                },
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ] else if (customAction != null) ...[
              const SizedBox(height: 24),
              customAction!,
            ],
          ],
        ),
      ),
    );
  }
}

class AnimatedExpandableContainer extends StatefulWidget {
  final Widget child;
  final bool isExpanded;
  final Duration duration;
  final Curve curve;
  final double? collapsedHeight;
  final double? expandedHeight;
  final VoidCallback? onExpansionComplete;
  final VoidCallback? onCollapseComplete;
  final bool clipBehavior;
  final Alignment alignment;

  const AnimatedExpandableContainer({
    Key? key,
    required this.child,
    required this.isExpanded,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.collapsedHeight = 0.0,
    this.expandedHeight,
    this.onExpansionComplete,
    this.onCollapseComplete,
    this.clipBehavior = true,
    this.alignment = Alignment.center,
  }) : super(key: key);

  @override
  State<AnimatedExpandableContainer> createState() => _AnimatedExpandableContainerState();
}

class _AnimatedExpandableContainerState extends State<AnimatedExpandableContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  final _childKey = GlobalKey();
  double? _childHeight;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _heightFactor = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    
    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
    
    _controller.addStatusListener(_handleAnimationStatusChange);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureChildHeight();
    });
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatusChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedExpandableContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
    
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    
    if (widget.curve != oldWidget.curve) {
      _heightFactor = CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      );
    }
    
    if (widget.child != oldWidget.child) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureChildHeight();
      });
    }
  }

  void _handleAnimationStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed && widget.onExpansionComplete != null) {
      widget.onExpansionComplete!();
    } else if (status == AnimationStatus.dismissed && widget.onCollapseComplete != null) {
      widget.onCollapseComplete!();
    }
  }

  void _measureChildHeight() {
    final RenderBox? renderBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _childHeight = renderBox.size.height;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expandedHeight = widget.expandedHeight ?? _childHeight;
    final collapsedHeight = widget.collapsedHeight;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double height;
        if (expandedHeight != null && collapsedHeight != null) {
          height = collapsedHeight + (expandedHeight - collapsedHeight) * _heightFactor.value;
        } else {
          height = double.infinity;
        }
        
        return Container(
          height: height == double.infinity ? null : height,
          alignment: widget.alignment,
          child: widget.clipBehavior
              ? ClipRect(
                  child: Align(
                    alignment: widget.alignment,
                    heightFactor: expandedHeight == null ? _heightFactor.value : null,
                    child: child,
                  ),
                )
              : child,
        );
      },
      child: Container(
        key: _childKey,
        child: widget.child,
      ),
    );
  }
}

class PullToRefreshContainer extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? indicatorColor;
  final String? refreshText;
  final bool enableHapticFeedback;
  final double triggerDistance;
  final Duration refreshDuration;

  const PullToRefreshContainer({
    Key? key,
    required this.child,
    required this.onRefresh,
    this.indicatorColor,
    this.refreshText,
    this.enableHapticFeedback = true,
    this.triggerDistance = 100.0,
    this.refreshDuration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<PullToRefreshContainer> createState() => _PullToRefreshContainerState();
}

class _PullToRefreshContainerState extends State<PullToRefreshContainer> with SingleTickerProviderStateMixin {
  late AnimationController _loadingAnimationController;
  bool _isRefreshing = false;
  double _dragDistance = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _loadingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _dragDistance = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = widget.indicatorColor ?? theme.colorScheme.primary;
    
    return GestureDetector(
      onVerticalDragStart: (details) {
        setState(() {
          _isDragging = true;
          _dragDistance = 0.0;
        });
      },
      onVerticalDragUpdate: (details) {
        if (_isRefreshing) return;
        
        setState(() {
          _dragDistance += details.delta.dy * 0.5; // Apply resistance
          if (_dragDistance < 0) _dragDistance = 0;
        });
      },
      onVerticalDragEnd: (details) {
        setState(() {
          _isDragging = false;
        });
        
        if (_dragDistance >= widget.triggerDistance && !_isRefreshing) {
          _handleRefresh();
        } else {
          setState(() {
            _dragDistance = 0.0;
          });
        }
      },
      child: Stack(
        children: [
          if (_dragDistance > 0 || _isRefreshing)
            Positioned(
              top: _isRefreshing ? 20 : _dragDistance - 50,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _loadingAnimationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _loadingAnimationController.value * 2 * math.pi,
                          child: Icon(
                            _isRefreshing ? Icons.refresh : Icons.arrow_downward,
                            color: indicatorColor,
                            size: 24 + (_dragDistance / 20).clamp(0.0, 8.0),
                          ),
                        );
                      },
                    ),
                    if (widget.refreshText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _isRefreshing ? 'جاري التحديث...' : widget.refreshText!,
                        style: TextStyle(
                          color: indicatorColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(0, _isDragging || _isRefreshing ? _dragDistance : 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
