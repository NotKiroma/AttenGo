import 'package:flutter/material.dart';

/// Тёмный PageRoute — без белой вспышки при переходе
class DarkPageRoute<T> extends MaterialPageRoute<T> {
  DarkPageRoute({required super.builder, super.settings});

  @override
  Color? get barrierColor => const Color(0xFF101C22);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return Container(
      color: const Color(0xFF101C22),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}
