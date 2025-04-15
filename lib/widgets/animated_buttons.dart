import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? splashColor;
  final double height;
  final double width;
  final double borderRadius;
  final bool isLoading;
  final Duration animationDuration;
  final AnimationType animationType;

  const AnimatedButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.splashColor,
    this.height = 50,
    this.width = double.infinity,
    this.borderRadius = 8.0,
    this.isLoading = false,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationType = AnimationType.scale,
  }) : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

enum AnimationType {
  scale,
  bounce,
  pulse,
  ripple,
  elevation,
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  double _scale = 1.0;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isLoading) return;
    setState(() {
      _isPressed = true;
    });
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isLoading) return;
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  void _onTapCancel() {
    if (widget.isLoading) return;
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.primaryColor;
    final splashColor = widget.splashColor ?? theme.colorScheme.onPrimary.withOpacity(0.3);

    Widget buttonContent = widget.isLoading
        ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.onPrimary,
              ),
            ),
          )
        : widget.child;

    Widget buttonWidget;

    switch (widget.animationType) {
      case AnimationType.scale:
        buttonWidget = ScaleTransition(
          scale: _scaleAnimation,
          child: _buildBaseButton(backgroundColor, splashColor, buttonContent),
        );
        break;
      case AnimationType.bounce:
        buttonWidget = _buildBounceButton(backgroundColor, splashColor, buttonContent);
        break;
      case AnimationType.pulse:
        buttonWidget = _buildPulseButton(backgroundColor, splashColor, buttonContent);
        break;
      case AnimationType.ripple:
        buttonWidget = _buildRippleButton(backgroundColor, splashColor, buttonContent);
        break;
      case AnimationType.elevation:
        buttonWidget = _buildElevationButton(backgroundColor, splashColor, buttonContent);
        break;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: buttonWidget,
    );
  }

  Widget _buildBaseButton(Color backgroundColor, Color splashColor, Widget buttonContent) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: buttonContent,
      ),
    );
  }

  Widget _buildBounceButton(Color backgroundColor, Color splashColor, Widget buttonContent) {
    return AnimatedContainer(
      duration: widget.animationDuration,
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isPressed ? 0.05 : 0.1),
            blurRadius: _isPressed ? 4 : 8,
            offset: Offset(0, _isPressed ? 1 : 2),
          ),
        ],
      ),
      transform: Matrix4.identity()..translate(0.0, _isPressed ? 2.0 : 0.0),
      child: Center(
        child: buttonContent,
      ),
    );
  }

  Widget _buildPulseButton(Color backgroundColor, Color splashColor, Widget buttonContent) {
    return AnimatedContainer(
      duration: widget.animationDuration,
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(_isPressed ? 0.3 : 0.0),
            spreadRadius: _isPressed ? 8 : 0,
            blurRadius: _isPressed ? 16 : 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: buttonContent,
      ),
    );
  }

  Widget _buildRippleButton(Color backgroundColor, Color splashColor, Widget buttonContent) {
    return Stack(
      children: [
        Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: buttonContent,
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: splashColor,
              highlightColor: Colors.transparent,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              onTap: () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElevationButton(Color backgroundColor, Color splashColor, Widget buttonContent) {
    return AnimatedContainer(
      duration: widget.animationDuration,
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: _isPressed ? 4 : 8,
            offset: Offset(0, _isPressed ? 1 : 3),
          ),
        ],
      ),
      transform: Matrix4.identity()
        ..translate(0.0, _isPressed ? 2.0 : 0.0)
        ..scale(_isPressed ? 0.98 : 1.0),
      child: Center(
        child: buttonContent,
      ),
    );
  }
}

class BounceButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final double height;
  final double width;
  final double borderRadius;

  const BounceButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.height = 50,
    this.width = double.infinity,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  _BounceButtonState createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    )..addListener(() {
        setState(() {});
      });

    final springSimulation = SpringSimulation(
      SpringDescription(
        mass: 1,
        stiffness: 500,
        damping: 20,
      ),
      1.0, // starting value
      0.0, // ending value
      0.0, // starting velocity
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.primaryColor;

    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      onTap: widget.onPressed,
      child: Transform.scale(
        scale: _scale.value,
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
