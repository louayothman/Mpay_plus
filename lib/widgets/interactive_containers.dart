import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';

class InteractiveCard extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final Color? backgroundColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool enableTilt;
  final bool enableShadowEffect;
  final bool enableHoverScale;
  final double maxTiltAngle;
  final double hoverScale;

  const InteractiveCard({
    Key? key,
    required this.child,
    this.width = double.infinity,
    this.height = 200,
    this.backgroundColor,
    this.borderRadius = 12.0,
    this.onTap,
    this.enableTilt = true,
    this.enableShadowEffect = true,
    this.enableHoverScale = true,
    this.maxTiltAngle = 0.05,
    this.hoverScale = 1.03,
  }) : super(key: key);

  @override
  _InteractiveCardState createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> with SingleTickerProviderStateMixin {
  double _rotateX = 0;
  double _rotateY = 0;
  double _shadowOffsetX = 0;
  double _shadowOffsetY = 0;
  double _shadowBlur = 8;
  double _scale = 1.0;
  bool _isHovering = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.hoverScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.addListener(() {
      setState(() {
        _scale = _scaleAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });

    if (widget.enableHoverScale) {
      if (isHovering) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableTilt) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size size = box.size;
    final double width = size.width;
    final double height = size.height;

    final double xPosition = details.localPosition.dx;
    final double yPosition = details.localPosition.dy;

    // Calculate rotation based on position
    final double xRotation = ((yPosition / height) - 0.5) * widget.maxTiltAngle;
    final double yRotation = ((xPosition / width) - 0.5) * -widget.maxTiltAngle;

    // Calculate shadow offset
    final double shadowX = yRotation * 20;
    final double shadowY = xRotation * 20;
    final double shadowBlur = widget.enableShadowEffect ? (_isHovering ? 16 : 8) : 8;

    setState(() {
      _rotateX = xRotation;
      _rotateY = yRotation;
      _shadowOffsetX = shadowX;
      _shadowOffsetY = shadowY;
      _shadowBlur = shadowBlur;
    });
  }

  void _resetTilt() {
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
      _shadowOffsetX = 0;
      _shadowOffsetY = 0;
      _shadowBlur = 8;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.cardColor;

    return MouseRegion(
      onEnter: (_) => _onHoverChanged(true),
      onExit: (_) {
        _onHoverChanged(false);
        _resetTilt();
      },
      onHover: widget.enableTilt ? (event) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset localPosition = box.globalToLocal(event.position);
        _onPanUpdate(DragUpdateDetails(localPosition: localPosition));
      } : null,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: _onPanUpdate,
        onPanEnd: (_) => _resetTilt(),
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(_rotateX)
            ..rotateY(_rotateY)
            ..scale(_scale),
          alignment: Alignment.center,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: _shadowBlur,
                  offset: Offset(_shadowOffsetX, _shadowOffsetY),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class WaveContainer extends StatefulWidget {
  final Widget child;
  final Color color;
  final double height;
  final double width;
  final double borderRadius;
  final int numberOfWaves;
  final double waveAmplitude;
  final double waveFrequency;
  final double wavePhase;
  final Duration animationDuration;

  const WaveContainer({
    Key? key,
    required this.child,
    required this.color,
    this.height = 200,
    this.width = double.infinity,
    this.borderRadius = 0,
    this.numberOfWaves = 3,
    this.waveAmplitude = 20,
    this.waveFrequency = 1.5,
    this.wavePhase = 0,
    this.animationDuration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  _WaveContainerState createState() => _WaveContainerState();
}

class _WaveContainerState extends State<WaveContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          children: [
            Positioned.fill(
              child: widget.child,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WavePainter(
                      color: widget.color,
                      animationValue: _controller.value,
                      numberOfWaves: widget.numberOfWaves,
                      waveAmplitude: widget.waveAmplitude,
                      waveFrequency: widget.waveFrequency,
                      wavePhase: widget.wavePhase,
                    ),
                    child: Container(
                      height: widget.waveAmplitude * 2,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;
  final double animationValue;
  final int numberOfWaves;
  final double waveAmplitude;
  final double waveFrequency;
  final double wavePhase;

  WavePainter({
    required this.color,
    required this.animationValue,
    required this.numberOfWaves,
    required this.waveAmplitude,
    required this.waveFrequency,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (int i = 0; i < numberOfWaves; i++) {
      final waveOpacity = 1.0 - (i / numberOfWaves);
      final adjustedAmplitude = waveAmplitude * waveOpacity;
      final adjustedFrequency = waveFrequency * (1 + i * 0.1);
      final adjustedPhase = wavePhase + (i * math.pi / 4);
      
      drawWave(
        canvas, 
        size, 
        paint.copyWith(color: color.withOpacity(waveOpacity)), 
        adjustedAmplitude, 
        adjustedFrequency, 
        adjustedPhase + (animationValue * 2 * math.pi)
      );
    }
  }

  void drawWave(Canvas canvas, Size size, Paint paint, double amplitude, double frequency, double phase) {
    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height - amplitude * math.sin((x / size.width * frequency * math.pi * 2) + phase);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}

class ParallaxCard extends StatefulWidget {
  final Widget background;
  final Widget foreground;
  final double height;
  final double width;
  final double borderRadius;
  final double parallaxFactor;
  final VoidCallback? onTap;

  const ParallaxCard({
    Key? key,
    required this.background,
    required this.foreground,
    this.height = 200,
    this.width = double.infinity,
    this.borderRadius = 12.0,
    this.parallaxFactor = 0.1,
    this.onTap,
  }) : super(key: key);

  @override
  _ParallaxCardState createState() => _ParallaxCardState();
}

class _ParallaxCardState extends State<ParallaxCard> {
  Offset _offset = Offset.zero;

  void _onHover(PointerHoverEvent event) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size size = box.size;
    final Offset localPosition = box.globalToLocal(event.position);
    
    // Convert to values between -1 and 1
    final double dx = (localPosition.dx / size.width) * 2 - 1;
    final double dy = (localPosition.dy / size.height) * 2 - 1;
    
    setState(() {
      _offset = Offset(dx, dy);
    });
  }

  void _onExit(PointerExitEvent event) {
    setState(() {
      _offset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onExit: _onExit,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                // Background with parallax effect
                AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.identity()
                    ..translate(
                      _offset.dx * -widget.parallaxFactor * 20,
                      _offset.dy * -widget.parallaxFactor * 20,
                    ),
                  child: widget.background,
                ),
                
                // Foreground with opposite parallax effect
                AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.identity()
                    ..translate(
                      _offset.dx * widget.parallaxFactor * 10,
                      _offset.dy * widget.parallaxFactor * 10,
                    ),
                  child: widget.foreground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
