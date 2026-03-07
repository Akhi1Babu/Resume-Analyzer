import 'package:flutter/material.dart';
import 'dart:math' as math;

class KineticBackground extends StatefulWidget {
  final Widget child;
  const KineticBackground({super.key, required this.child});

  @override
  State<KineticBackground> createState() => _KineticBackgroundState();
}

class _KineticBackgroundState extends State<KineticBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> particles;
  final int particleCount = 70;
  final math.Random random = math.Random();
  Offset _mousePos = const Offset(-1, -1);
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    particles = List.generate(particleCount, (i) {
      return _Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        vx: (random.nextDouble() - 0.5) * 0.003,
        vy: (random.nextDouble() - 0.5) * 0.003,
        radius: random.nextDouble() * 2 + 1.5,
        color: _getRandomColor(),
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _controller.addListener(() {
      _updateParticles();
    });
  }

  Color _getRandomColor() {
    final colors = [
      const Color(0xFF00FFC2),
      const Color(0xFF7000FF),
      const Color(0xFFFFB800),
      const Color(0xFFFF4949),
      Colors.white,
    ];
    return colors[random.nextInt(colors.length)].withOpacity(
      random.nextDouble() * 0.5 + 0.2,
    );
  }

  void _updateParticles() {
    for (var p in particles) {
      // Base movement
      p.x += p.vx;
      p.y += p.vy;

      if (_screenSize != Size.zero && _mousePos != const Offset(-1, -1)) {
        // Calculate distance from mouse
        final dx = (p.x * _screenSize.width) - _mousePos.dx;
        final dy = (p.y * _screenSize.height) - _mousePos.dy;
        final distSq = dx * dx + dy * dy;

        // Repel from mouse if close
        if (distSq < 20000) {
          final dist = math.sqrt(distSq);
          if (dist > 0) {
            final f = (20000 - distSq) / 20000;
            p.x += (dx / dist) * f * 0.005;
            p.y += (dy / dist) * f * 0.005;
          }
        }
      }

      if (p.x < 0) {
        p.x = 0;
        p.vx *= -1;
      } else if (p.x > 1) {
        p.x = 1;
        p.vx *= -1;
      }

      if (p.y < 0) {
        p.y = 0;
        p.vy *= -1;
      } else if (p.y > 1) {
        p.y = 1;
        p.vy *= -1;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0F1E),
      body: Stack(
        children: [
          Positioned.fill(
            child: MouseRegion(
              onHover: (event) {
                setState(() {
                  _mousePos = event.localPosition;
                });
              },
              onExit: (event) {
                setState(() {
                  _mousePos = const Offset(-1, -1);
                });
              },
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      _screenSize = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return CustomPaint(
                        painter: _KineticPainter(
                          particles: particles,
                          mousePos: _mousePos,
                          screenSize: _screenSize,
                        ),
                        size: Size.infinite,
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

class _Particle {
  double x, y;
  double vx, vy;
  double radius;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
  });
}

class _KineticPainter extends CustomPainter {
  final List<_Particle> particles;
  final Offset mousePos;
  final Size screenSize;

  _KineticPainter({
    required this.particles,
    required this.mousePos,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()..color = p.color;
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        paint,
      );
    }

    final linePaint = Paint()..strokeWidth = 1.0;

    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final p1 = particles[i];
        final p2 = particles[j];

        final dx = p1.x - p2.x;
        final dy = p1.y - p2.y;
        final distSq = dx * dx + dy * dy;

        // Draw line if particles are relatively close to each other
        if (distSq < 0.02) {
          double opacity = (0.02 - distSq) * 50;
          if (opacity > 0.3) opacity = 0.3;
          linePaint.color = Colors.white.withOpacity(opacity);
          canvas.drawLine(
            Offset(p1.x * size.width, p1.y * size.height),
            Offset(p2.x * size.width, p2.y * size.height),
            linePaint,
          );
        }
      }
    }

    // Connect cursor to nearby particles
    if (mousePos != const Offset(-1, -1) && screenSize != Size.zero) {
      for (var p in particles) {
        final px = p.x * size.width;
        final py = p.y * size.height;
        final dx = px - mousePos.dx;
        final dy = py - mousePos.dy;
        final distSq = dx * dx + dy * dy;

        if (distSq < 30000) {
          double opacity = (30000 - distSq) / 30000 * 0.5;
          if (opacity > 0.5) opacity = 0.5;
          linePaint.color = const Color(0xFF00FFC2).withOpacity(opacity);
          canvas.drawLine(mousePos, Offset(px, py), linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KineticPainter oldDelegate) => true;
}
