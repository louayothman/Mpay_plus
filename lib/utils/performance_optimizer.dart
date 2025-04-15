import 'package:flutter/material.dart';
import 'package:mpay_clean/widgets/enhanced_components.dart';

class PerformanceOptimizer {
  // تحسين أداء القوائم الطويلة
  static Widget optimizedListView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    Axis scrollDirection = Axis.vertical,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? cacheExtent,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      scrollDirection: scrollDirection,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      cacheExtent: cacheExtent ?? 200.0, // تحسين التخزين المؤقت
    );
  }

  // تحسين أداء الصور
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return OptimizedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      placeholder: placeholder ?? const CircularProgressIndicator(),
      errorWidget: errorWidget ?? const Icon(Icons.error),
    );
  }

  // تحسين أداء الرسوم المتحركة
  static Widget optimizedAnimation({
    required Widget child,
    required AnimationType animationType,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      child: child,
    );
  }

  // تحسين أداء التمرير
  static Widget optimizedScrollView({
    required List<Widget> children,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    Axis scrollDirection = Axis.vertical,
  }) {
    return SingleChildScrollView(
      physics: physics ?? const BouncingScrollPhysics(),
      padding: padding,
      scrollDirection: scrollDirection,
      child: shrinkWrap
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: children,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
    );
  }

  // تحسين أداء العرض المتوازي
  static Widget optimizedGridView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required int crossAxisCount,
    double mainAxisSpacing = 10.0,
    double crossAxisSpacing = 10.0,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    double childAspectRatio = 1.0,
  }) {
    return GridView.builder(
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: itemBuilder,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
    );
  }

  // تحسين أداء التحميل المتأخر
  static Widget lazyLoadingBuilder({
    required bool isLoading,
    required Widget child,
    Widget? loadingWidget,
  }) {
    return isLoading
        ? loadingWidget ?? const CircularProgressIndicator()
        : child;
  }
}
