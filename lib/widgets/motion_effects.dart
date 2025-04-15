import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final Color color1;
  final Color color2;
  final Color color3;
  final Duration duration;
  final bool enableGradientMotion;
  final bool enableParticles;
  final int particleCount;

  const AnimatedBackground({
    Key? key,
    required this.child,
    required this.color1,
    required this.color2,
    required this.color3,
    this.duration = const Duration(seconds: 10),
    this.enableGradientMotion = true,
    this.enableParticles = true,
    this.particleCount = 50,
  }) : super(key: key);

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    if (widget.enableParticles) {
      _initParticles();
    }
  }

  void _initParticles() {
    final random = math.Random();
    _particles = List.generate(
      widget.particleCount,
      (_) => Particle(
        position: Offset(
          random.nextDouble() * 400,
          random.nextDouble() * 800,
        ),
        speed: Offset(
          (random.nextDouble() - 0.5) * 2,
          (random.nextDouble() - 0.5) * 2,
        ),
        radius: random.nextDouble() * 8 + 2,
        color: [widget.color1, widget.color2, widget.color3][random.nextInt(3)]
            .withOpacity(random.nextDouble() * 0.6 + 0.1),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated gradient background
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.color1, widget.color2, widget.color3],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [
                    0.0,
                    widget.enableGradientMotion ? _controller.value : 0.5,
                    1.0,
                  ],
                ),
              ),
            );
          },
        ),

        // Particles
        if (widget.enableParticles)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: _particles,
                  animationValue: _controller.value,
                ),
                size: Size.infinite,
              );
            },
          ),

        // Content
        widget.child,
      ],
    );
  }
}

class Particle {
  Offset position;
  Offset speed;
  double radius;
  Color color;

  Particle({
    required this.position,
    required this.speed,
    required this.radius,
    required this.color,
  });

  void update(Size size, double animationValue) {
    // Update position based on speed and animation value
    position += speed * (1 + math.sin(animationValue * math.pi * 2) * 0.2);

    // Wrap around screen edges
    if (position.dx < -radius) position = Offset(size.width + radius, position.dy);
    if (position.dx > size.width + radius) position = Offset(-radius, position.dy);
    if (position.dy < -radius) position = Offset(position.dx, size.height + radius);
    if (position.dy > size.height + radius) position = Offset(position.dx, -radius);
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update(size, animationValue);

      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class PulsingEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final Curve curve;

  const PulsingEffect({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.curve = Curves.easeInOut,
  }) : super(key: key);

  @override
  _PulsingEffectState createState() => _PulsingEffectState();
}

class _PulsingEffectState extends State<PulsingEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class FloatingEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double floatHeight;
  final Curve curve;

  const FloatingEffect({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.floatHeight = 10.0,
    this.curve = Curves.easeInOut,
  }) : super(key: key);

  @override
  _FloatingEffectState createState() => _FloatingEffectState();
}

class _FloatingEffectState extends State<FloatingEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: widget.floatHeight,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_animation.value),
          child: widget.child,
        );
      },
    );
  }
}

class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final bool enabled;

  const ShimmerEffect({
    Key? key,
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    this.duration = const Duration(seconds: 1),
    this.enabled = true,
  }) : super(key: key);

  @override
  _ShimmerEffectState createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class RotatingEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double maxRotation;
  final Axis axis;

  const RotatingEffect({
    Key? key,
    required this.child,
    this.duration = const Duration(seconds: 10),
    this.maxRotation = 0.1, // in radians
    this.axis = Axis.vertical,
  }) : super(key: key);

  @override
  _RotatingEffectState createState() => _RotatingEffectState();
}

class _RotatingEffectState extends State<RotatingEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -widget.maxRotation,
      end: widget.maxRotation,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: widget.axis == Axis.vertical
              ? Matrix4.rotationY(_animation.value)
              : Matrix4.rotationX(_animation.value),
          child: widget.child,
        );
      },
    );
  }
}
