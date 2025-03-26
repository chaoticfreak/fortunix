// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'chatbot_page.dart';
import 'package:google_fonts/google_fonts.dart';

class RippleClipper extends CustomClipper<Path> {
  final double progress;
  final Offset center;

  RippleClipper(this.progress, this.center);

  @override
  Path getClip(Size size) {
    final radius = progress * 1.5 * size.longestSide;
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(RippleClipper oldClipper) =>
      progress != oldClipper.progress || center != oldClipper.center;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double scrollOffset = 0;
  bool isHovering = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final centerTrigger = _scrollController.position.maxScrollExtent * 0.3;
      if (_scrollController.offset > centerTrigger) {
        _scrollController.jumpTo(centerTrigger);
      }
      setState(() {
        scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: BackgroundPainter(),
          ),
          SingleChildScrollView(
            controller: _scrollController,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 1.5,
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  AnimatedOpacity(
                    duration: Duration(milliseconds: 400),
                    opacity: 1.0 - (scrollOffset / 250).clamp(0.0, 1.0),
                    child: AnimatedScale(
                      duration: Duration(milliseconds: 400),
                      scale: 1.0 - (scrollOffset / 800).clamp(0.0, 0.2),
                      child: Center(
                        child: Text(
                          'Fortunix',
                          style: TextStyle(
                            fontFamily: GoogleFonts.orbitron().fontFamily,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.blueAccent.withOpacity(0.6),
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 180),
                  AnimatedOpacity(
                    opacity: scrollOffset > 100 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 600),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => isHovering = true),
                      onExit: (_) => setState(() => isHovering = false),
                      child: GestureDetector(
                        onTapDown: (TapDownDetails details) {
                          final tapPosition = details.globalPosition;

                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                  ChatbotPage(),
                              transitionsBuilder: (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                  ) {
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: AnimatedBuilder(
                                        animation: animation,
                                        builder: (context, _) {
                                          return ClipPath(
                                            clipper: RippleClipper(
                                              animation.value,
                                              tapPosition,
                                            ),
                                            child: child,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0F2027),
                                Color(0xFF2C5364)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.6),
                                blurRadius: isHovering ? 25 : 15,
                                spreadRadius: isHovering ? 3 : 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.blueAccent.withOpacity(0.6),
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          child: Text(
                            'Chat with Assistant',
                            style: TextStyle(
                              fontFamily: GoogleFonts.orbitron().fontFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (scrollOffset < 30)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withOpacity(0.4), size: 40),
              ),
            ),
        ],
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0C1424),
          Color(0xFF0A0F1A),
          Color(0xFF050812),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), gradient);

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    double spacing = 80;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
