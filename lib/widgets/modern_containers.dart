import 'package:flutter/material.dart';
import 'dart:ui';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color borderColor;
  final double borderWidth;
  final Gradient? gradient;

  const GlassmorphicContainer({
    Key? key,
    required this.child,
    required this.width,
    required this.height,
    this.borderRadius = 20.0,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.borderColor = Colors.white,
    this.borderWidth = 1.5,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor.withOpacity(0.5),
            width: borderWidth,
          ),
        ),
        child: Stack(
          children: [
            // Blurred background
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blur,
                sigmaY: blur,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: gradient,
                ),
              ),
            ),
            // Content
            child,
          ],
        ),
      ),
    );
  }
}

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final Color color;
  final bool isPressed;
  final double depth;
  final double intensity;
  final NeumorphicStyle style;

  const NeumorphicContainer({
    Key? key,
    required this.child,
    required this.width,
    required this.height,
    this.borderRadius = 15.0,
    required this.color,
    this.isPressed = false,
    this.depth = 5.0,
    this.intensity = 0.5,
    this.style = NeumorphicStyle.convex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate light and shadow colors based on the base color
    final Color lightColor = _calculateLightColor(color, intensity);
    final Color shadowColor = _calculateShadowColor(color, intensity);

    // Determine the box shadow configuration based on style and pressed state
    List<BoxShadow> boxShadows = [];
    
    switch (style) {
      case NeumorphicStyle.flat:
        boxShadows = isPressed ? [] : [
          BoxShadow(
            color: shadowColor,
            offset: Offset(depth, depth),
            blurRadius: depth,
          ),
          BoxShadow(
            color: lightColor,
            offset: Offset(-depth, -depth),
            blurRadius: depth,
          ),
        ];
        break;
      
      case NeumorphicStyle.convex:
        boxShadows = isPressed ? [
          BoxShadow(
            color: shadowColor,
            offset: Offset(depth / 2, depth / 2),
            blurRadius: depth,
            // inset: true,
          ),
          BoxShadow(
            color: lightColor,
            offset: Offset(-depth / 2, -depth / 2),
            blurRadius: depth,
            // inset: true,
          ),
        ] : [
          BoxShadow(
            color: shadowColor,
            offset: Offset(depth, depth),
            blurRadius: depth,
          ),
          BoxShadow(
            color: lightColor,
            offset: Offset(-depth, -depth),
            blurRadius: depth,
          ),
        ];
        break;
      
      case NeumorphicStyle.concave:
        boxShadows = isPressed ? [
          BoxShadow(
            color: lightColor,
            offset: Offset(depth / 2, depth / 2),
            blurRadius: depth,
            inset: true,
          ),
          BoxShadow(
            color: shadowColor,
            offset: Offset(-depth / 2, -depth / 2),
            blurRadius: depth,
            inset: true,
          ),
        ] : [
          BoxShadow(
            color: shadowColor,
            offset: Offset(depth, depth),
            blurRadius: depth,
          ),
          BoxShadow(
            color: lightColor,
            offset: Offset(-depth, -depth),
            blurRadius: depth,
          ),
        ];
        break;
      
      case NeumorphicStyle.pressed:
        boxShadows = [
          BoxShadow(
            color: shadowColor,
            offset: Offset(depth / 2, depth / 2),
            blurRadius: depth,
            inset: true,
          ),
          BoxShadow(
            color: lightColor,
            offset: Offset(-depth / 2, -depth / 2),
            blurRadius: depth,
            inset: true,
          ),
        ];
        break;
    }

    // Create gradient for convex/concave effect
    Gradient? gradient;
    if (style == NeumorphicStyle.convex && !isPressed) {
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          lightColor.withOpacity(0.5),
          shadowColor.withOpacity(0.5),
        ],
      );
    } else if (style == NeumorphicStyle.concave && !isPressed) {
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          shadowColor.withOpacity(0.5),
          lightColor.withOpacity(0.5),
        ],
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient,
        boxShadow: boxShadows,
      ),
      child: child,
    );
  }

  Color _calculateLightColor(Color baseColor, double intensity) {
    final hslColor = HSLColor.fromColor(baseColor);
    return hslColor.withLightness((hslColor.lightness + intensity).clamp(0.0, 1.0)).toColor();
  }

  Color _calculateShadowColor(Color baseColor, double intensity) {
    final hslColor = HSLColor.fromColor(baseColor);
    return hslColor.withLightness((hslColor.lightness - intensity).clamp(0.0, 1.0)).toColor();
  }
}

enum NeumorphicStyle {
  flat,
  convex,
  concave,
  pressed,
}

class GradientBorderContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final double borderWidth;
  final Gradient gradient;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  const GradientBorderContainer({
    Key? key,
    required this.child,
    required this.width,
    required this.height,
    this.borderRadius = 15.0,
    this.borderWidth = 2.0,
    required this.gradient,
    this.backgroundColor,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius + borderWidth),
        gradient: gradient,
        boxShadow: boxShadow,
      ),
      child: Center(
        child: Container(
          width: width - borderWidth * 2,
          height: height - borderWidth * 2,
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}

class FrostedGlassCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final Color color;
  final double blur;
  final double opacity;

  const FrostedGlassCard({
    Key? key,
    required this.child,
    required this.width,
    required this.height,
    this.borderRadius = 15.0,
    this.color = Colors.white,
    this.blur = 10.0,
    this.opacity = 0.2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
        ),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ShadowContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final Color backgroundColor;
  final List<BoxShadow> boxShadow;
  final Border? border;

  const ShadowContainer({
    Key? key,
    required this.child,
    required this.width,
    required this.height,
    this.borderRadius = 15.0,
    required this.backgroundColor,
    required this.boxShadow,
    this.border,
  }) : super(key: key);

  factory ShadowContainer.elevated({
    required Widget child,
    required double width,
    required double height,
    double borderRadius = 15.0,
    Color backgroundColor = Colors.white,
    double elevation = 5.0,
    Border? border,
  }) {
    return ShadowContainer(
      child: child,
      width: width,
      height: height,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      border: border,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: elevation * 2,
          spreadRadius: elevation / 2,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }

  factory ShadowContainer.layered({
    required Widget child,
    required double width,
    required double height,
    double borderRadius = 15.0,
    Color backgroundColor = Colors.white,
    Border? border,
  }) {
    return ShadowContainer(
      child: child,
      width: width,
      height: height,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      border: border,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 2,
          spreadRadius: 1,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
          spreadRadius: 2,
          offset: Offset(0, 3),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 10,
          spreadRadius: 3,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
        border: border,
      ),
      child: child,
    );
  }
}
