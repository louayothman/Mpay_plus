import 'package:flutter/material.dart';
import 'package:mpay_app/utils/device_compatibility_manager.dart';
import 'package:mpay_app/utils/screen_adaptation_manager.dart';
import 'package:mpay_app/utils/error_handler.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';

class AccessibilityManager {
  // Device compatibility manager
  final DeviceCompatibilityManager _deviceCompatibilityManager = DeviceCompatibilityManager();
  
  // Screen adaptation manager
  final ScreenAdaptationManager _screenAdaptationManager = ScreenAdaptationManager();
  
  // Error handler
  final ErrorHandler _errorHandler = ErrorHandler();
  
  // Accessibility settings
  bool _largeTextEnabled = false;
  bool _highContrastEnabled = false;
  bool _reduceAnimationsEnabled = false;
  bool _screenReaderEnabled = false;
  
  // Singleton pattern
  static final AccessibilityManager _instance = AccessibilityManager._internal();
  
  factory AccessibilityManager() {
    return _instance;
  }
  
  AccessibilityManager._internal();
  
  // Initialize the manager
  Future<void> initialize(BuildContext context) async {
    try {
      // Get accessibility settings from MediaQuery
      final mediaQuery = MediaQuery.of(context);
      
      _largeTextEnabled = mediaQuery.textScaleFactor > 1.3;
      _highContrastEnabled = mediaQuery.highContrast;
      _reduceAnimationsEnabled = mediaQuery.disableAnimations;
      _screenReaderEnabled = mediaQuery.accessibleNavigation;
      
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to initialize accessibility manager',
        ErrorSeverity.medium,
      );
    }
  }
  
  // Apply accessibility settings to text style
  TextStyle getAccessibleTextStyle({
    required BuildContext context,
    required TextStyle baseStyle,
  }) {
    try {
      // Apply large text if enabled
      if (_largeTextEnabled) {
        final fontSize = baseStyle.fontSize ?? 14.0;
        final increasedFontSize = fontSize * 1.3;
        
        baseStyle = baseStyle.copyWith(
          fontSize: increasedFontSize,
          height: 1.5, // Increase line height for better readability
        );
      }
      
      // Apply high contrast if enabled
      if (_highContrastEnabled) {
        final color = baseStyle.color;
        
        if (color != null) {
          // Increase contrast by making dark colors darker and light colors lighter
          final brightness = ThemeData.estimateBrightnessForColor(color);
          
          if (brightness == Brightness.dark) {
            baseStyle = baseStyle.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            );
          } else {
            baseStyle = baseStyle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            );
          }
        }
      }
      
      return baseStyle;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible text style',
        ErrorSeverity.low,
      );
      return baseStyle;
    }
  }
  
  // Get accessible font size
  double getAccessibleFontSize(double fontSize, BuildContext context) {
    try {
      if (_largeTextEnabled) {
        return fontSize * 1.3;
      }
      
      return fontSize;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible font size',
        ErrorSeverity.low,
      );
      return fontSize;
    }
  }
  
  // Get accessible colors
  Color getAccessibleTextColor(Color color, BuildContext context) {
    try {
      if (_highContrastEnabled) {
        final brightness = ThemeData.estimateBrightnessForColor(color);
        
        if (brightness == Brightness.dark) {
          return Colors.black;
        } else {
          return Colors.white;
        }
      }
      
      return color;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible text color',
        ErrorSeverity.low,
      );
      return color;
    }
  }
  
  // Get accessible background color
  Color getAccessibleBackgroundColor(Color color, BuildContext context) {
    try {
      if (_highContrastEnabled) {
        final brightness = ThemeData.estimateBrightnessForColor(color);
        
        if (brightness == Brightness.dark) {
          return Colors.black;
        } else {
          return Colors.white;
        }
      }
      
      return color;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible background color',
        ErrorSeverity.low,
      );
      return color;
    }
  }
  
  // Get accessible icon size
  double getAccessibleIconSize(double size, BuildContext context) {
    try {
      if (_largeTextEnabled) {
        return size * 1.3;
      }
      
      return size;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible icon size',
        ErrorSeverity.low,
      );
      return size;
    }
  }
  
  // Get accessible padding
  EdgeInsets getAccessiblePadding(EdgeInsets padding, BuildContext context) {
    try {
      if (_largeTextEnabled) {
        return EdgeInsets.only(
          left: padding.left * 1.3,
          top: padding.top * 1.3,
          right: padding.right * 1.3,
          bottom: padding.bottom * 1.3,
        );
      }
      
      return padding;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible padding',
        ErrorSeverity.low,
      );
      return padding;
    }
  }
  
  // Get accessible button size
  Size getAccessibleButtonSize(Size size, BuildContext context) {
    try {
      if (_largeTextEnabled) {
        return Size(
          size.width * 1.3,
          size.height * 1.3,
        );
      }
      
      return size;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible button size',
        ErrorSeverity.low,
      );
      return size;
    }
  }
  
  // Get accessible duration for animations
  Duration getAccessibleAnimationDuration(Duration duration) {
    try {
      if (_reduceAnimationsEnabled) {
        return Duration.zero; // Disable animations
      }
      
      return duration;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible animation duration',
        ErrorSeverity.low,
      );
      return duration;
    }
  }
  
  // Check if screen reader is enabled
  bool isScreenReaderEnabled() {
    return _screenReaderEnabled;
  }
  
  // Check if large text is enabled
  bool isLargeTextEnabled() {
    return _largeTextEnabled;
  }
  
  // Check if high contrast is enabled
  bool isHighContrastEnabled() {
    return _highContrastEnabled;
  }
  
  // Check if reduce animations is enabled
  bool isReduceAnimationsEnabled() {
    return _reduceAnimationsEnabled;
  }
  
  // Get accessible widget
  Widget getAccessibleWidget({
    required BuildContext context,
    required Widget child,
    String? semanticLabel,
    String? semanticHint,
    bool excludeSemantics = false,
  }) {
    try {
      if (excludeSemantics) {
        return ExcludeSemantics(
          child: child,
        );
      }
      
      if (semanticLabel != null || semanticHint != null) {
        return Semantics(
          label: semanticLabel,
          hint: semanticHint,
          child: child,
        );
      }
      
      return child;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible widget',
        ErrorSeverity.low,
      );
      return child;
    }
  }
  
  // Get accessible button
  Widget getAccessibleButton({
    required BuildContext context,
    required Widget child,
    required VoidCallback onPressed,
    String? semanticLabel,
    Color? color,
    EdgeInsets? padding,
    double? minWidth,
    double? height,
  }) {
    try {
      // Apply accessibility settings
      final accessiblePadding = padding != null ? getAccessiblePadding(padding, context) : null;
      final accessibleMinWidth = minWidth != null && _largeTextEnabled ? minWidth * 1.3 : minWidth;
      final accessibleHeight = height != null && _largeTextEnabled ? height * 1.3 : height;
      final accessibleColor = color != null && _highContrastEnabled ? getAccessibleBackgroundColor(color, context) : color;
      
      return Semantics(
        label: semanticLabel,
        button: true,
        enabled: true,
        child: MaterialButton(
          onPressed: onPressed,
          color: accessibleColor,
          padding: accessiblePadding,
          minWidth: accessibleMinWidth,
          height: accessibleHeight,
          child: child,
        ),
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible button',
        ErrorSeverity.low,
      );
      
      return MaterialButton(
        onPressed: onPressed,
        color: color,
        padding: padding,
        minWidth: minWidth,
        height: height,
        child: child,
      );
    }
  }
  
  // Get accessible text field
  Widget getAccessibleTextField({
    required BuildContext context,
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
    InputDecoration? decoration,
  }) {
    try {
      // Apply accessibility settings
      final accessibleLabelText = labelText;
      final accessibleHintText = hintText;
      
      // Create accessible decoration
      InputDecoration accessibleDecoration;
      
      if (decoration != null) {
        accessibleDecoration = decoration.copyWith(
          labelText: accessibleLabelText,
          hintText: accessibleHintText,
          labelStyle: decoration.labelStyle != null ? 
            getAccessibleTextStyle(context: context, baseStyle: decoration.labelStyle!) : 
            null,
          hintStyle: decoration.hintStyle != null ? 
            getAccessibleTextStyle(context: context, baseStyle: decoration.hintStyle!) : 
            null,
          contentPadding: decoration.contentPadding != null ? 
            getAccessiblePadding(decoration.contentPadding!, context) : 
            null,
        );
      } else {
        accessibleDecoration = InputDecoration(
          labelText: accessibleLabelText,
          hintText: accessibleHintText,
        );
      }
      
      return Semantics(
        textField: true,
        label: labelText,
        hint: hintText,
        obscured: obscureText,
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          decoration: accessibleDecoration,
          style: _largeTextEnabled ? 
            TextStyle(fontSize: 16 * 1.3) : 
            null,
        ),
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible text field',
        ErrorSeverity.low,
      );
      
      return TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        decoration: decoration ?? InputDecoration(
          labelText: labelText,
          hintText: hintText,
        ),
      );
    }
  }
  
  // Get accessible image
  Widget getAccessibleImage({
    required BuildContext context,
    required ImageProvider image,
    String? semanticLabel,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    try {
      // Apply accessibility settings
      final accessibleWidth = width != null && _largeTextEnabled ? width * 1.3 : width;
      final accessibleHeight = height != null && _largeTextEnabled ? height * 1.3 : height;
      
      return Semantics(
        label: semanticLabel,
        image: true,
        child: Image(
          image: image,
          width: accessibleWidth,
          height: accessibleHeight,
          fit: fit,
        ),
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible image',
        ErrorSeverity.low,
      );
      
      return Image(
        image: image,
        width: width,
        height: height,
        fit: fit,
      );
    }
  }
  
  // Get accessible icon
  Widget getAccessibleIcon({
    required BuildContext context,
    required IconData icon,
    String? semanticLabel,
    double? size,
    Color? color,
  }) {
    try {
      // Apply accessibility settings
      final accessibleSize = size != null ? getAccessibleIconSize(size, context) : null;
      final accessibleColor = color != null ? getAccessibleTextColor(color, context) : null;
      
      return Semantics(
        label: semanticLabel,
        child: Icon(
          icon,
          size: accessibleSize,
          color: accessibleColor,
        ),
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible icon',
        ErrorSeverity.low,
      );
      
      return Icon(
        icon,
        size: size,
        color: color,
      );
    }
  }
  
  // Get accessible text
  Widget getAccessibleText({
    required BuildContext context,
    required String text,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    try {
      // Apply accessibility settings
      final accessibleStyle = style != null ? 
        getAccessibleTextStyle(context: context, baseStyle: style) : 
        null;
      
      return Semantics(
        label: text,
        excludeSemantics: true, // Prevent double reading by screen readers
        child: Text(
          text,
          style: accessibleStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible text',
        ErrorSeverity.low,
      );
      
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
  }
  
  // Get accessible container
  Widget getAccessibleContainer({
    required BuildContext context,
    required Widget child,
    Color? color,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? width,
    double? height,
    BoxDecoration? decoration,
  }) {
    try {
      // Apply accessibility settings
      final accessiblePadding = padding != null ? getAccessiblePadding(padding, context) : null;
      final accessibleMargin = margin != null ? getAccessiblePadding(margin, context) : null;
      final accessibleWidth = width != null && _largeTextEnabled ? width * 1.3 : width;
      final accessibleHeight = height != null && _largeTextEnabled ? height * 1.3 : height;
      final accessibleColor = color != null ? getAccessibleBackgroundColor(color, context) : null;
      
      BoxDecoration? accessibleDecoration;
      if (decoration != null) {
        accessibleDecoration = BoxDecoration(
          color: decoration.color != null ? getAccessibleBackgroundColor(decoration.color!, context) : null,
          border: decoration.border,
          borderRadius: decoration.borderRadius,
          boxShadow: decoration.boxShadow,
          gradient: decoration.gradient,
          image: decoration.image,
          shape: decoration.shape,
        );
      }
      
      return Container(
        color: accessibleDecoration == null ? accessibleColor : null,
        padding: accessiblePadding,
        margin: accessibleMargin,
        width: accessibleWidth,
        height: accessibleHeight,
        decoration: accessibleDecoration,
        child: child,
      );
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible container',
        ErrorSeverity.low,
      );
      
      return Container(
        color: color,
        padding: padding,
        margin: margin,
        width: width,
        height: height,
        decoration: decoration,
        child: child,
      );
    }
  }
  
  // Apply accessibility to theme data
  ThemeData getAccessibleThemeData(ThemeData baseTheme, BuildContext context) {
    try {
      if (!_highContrastEnabled && !_largeTextEnabled) {
        return baseTheme;
      }
      
      // Apply high contrast if enabled
      if (_highContrastEnabled) {
        baseTheme = baseTheme.copyWith(
          primaryColor: Colors.blue,
          accentColor: Colors.orange,
          errorColor: Colors.red,
          backgroundColor: Colors.white,
          scaffoldBackgroundColor: Colors.white,
          cardColor: Colors.white,
          dividerColor: Colors.black,
          textTheme: baseTheme.textTheme.apply(
            bodyColor: Colors.black,
            displayColor: Colors.black,
          ),
          primaryTextTheme: baseTheme.primaryTextTheme.apply(
            bodyColor: Colors.black,
            displayColor: Colors.black,
          ),
          accentTextTheme: baseTheme.accentTextTheme.apply(
            bodyColor: Colors.black,
            displayColor: Colors.black,
          ),
        );
      }
      
      // Apply large text if enabled
      if (_largeTextEnabled) {
        baseTheme = baseTheme.copyWith(
          textTheme: baseTheme.textTheme.apply(
            fontSizeFactor: 1.3,
            fontSizeDelta: 2.0,
          ),
          primaryTextTheme: baseTheme.primaryTextTheme.apply(
            fontSizeFactor: 1.3,
            fontSizeDelta: 2.0,
          ),
          accentTextTheme: baseTheme.accentTextTheme.apply(
            fontSizeFactor: 1.3,
            fontSizeDelta: 2.0,
          ),
        );
      }
      
      return baseTheme;
    } catch (e) {
      _errorHandler.handleError(
        e,
        'Failed to get accessible theme data',
        ErrorSeverity.low,
      );
      return baseTheme;
    }
  }
}
