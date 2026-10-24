import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Ikon khas LINAKAN, digambar pada grid 24×24 dengan garis 2 px.
/// Simbol ini dipakai untuk navigasi dan aksi utama; logo tetap aset asli.
enum AgrarianSymbol {
  barn,
  harvestCrate,
  exchange,
  market,
  receiptScale,
  coinPouch,
  grower,
  sprout,
}

class AgrarianIcon extends StatelessWidget {
  final AgrarianSymbol symbol;
  final double size;
  final Color color;
  final bool active;

  const AgrarianIcon(
    this.symbol, {
    super.key,
    this.size = 24,
    this.color = AppColors.kColorPrimary,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _AgrarianPainter(symbol, color, active),
        ),
      );
}

class _AgrarianPainter extends CustomPainter {
  final AgrarianSymbol symbol;
  final Color color;
  final bool active;

  const _AgrarianPainter(this.symbol, this.color, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = active ? 1.9 : 1.65
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final tint = Paint()
      ..color = color.withValues(alpha: active ? .12 : .035)
      ..style = PaintingStyle.fill;

    switch (symbol) {
      case AgrarianSymbol.barn:
        final house = Path()
          ..moveTo(4, 9)
          ..lineTo(12, 3)
          ..lineTo(20, 9)
          ..lineTo(20, 21)
          ..lineTo(4, 21)
          ..close();
        canvas.drawPath(house, tint);
        canvas.drawPath(house, stroke);
        final door = Path()
          ..moveTo(9, 21)
          ..lineTo(9, 14)
          ..quadraticBezierTo(12, 11, 15, 14)
          ..lineTo(15, 21);
        canvas.drawPath(door, stroke);
        _line(canvas, stroke, 8, 9, 16, 9);
        break;

      case AgrarianSymbol.harvestCrate:
        final crate = Path()
          ..moveTo(3, 10)
          ..lineTo(21, 10)
          ..lineTo(19, 21)
          ..lineTo(5, 21)
          ..close();
        canvas.drawPath(crate, tint);
        canvas.drawPath(crate, stroke);
        _line(canvas, stroke, 5, 14, 19, 14);
        _line(canvas, stroke, 9, 14, 9.5, 20);
        _line(canvas, stroke, 15, 14, 14.5, 20);
        _line(canvas, stroke, 12, 10, 12, 5);
        _leaf(canvas, stroke, 12, 7, 7, 3, 7, 8);
        _leaf(canvas, stroke, 12, 7, 17, 3, 17, 8);
        break;

      case AgrarianSymbol.exchange:
        _line(canvas, stroke, 4, 5, 20, 5);
        _line(canvas, stroke, 16.5, 2.5, 20, 5);
        _line(canvas, stroke, 16.5, 7.5, 20, 5);
        _line(canvas, stroke, 20, 19, 4, 19);
        _line(canvas, stroke, 7.5, 16.5, 4, 19);
        _line(canvas, stroke, 7.5, 21.5, 4, 19);
        _line(canvas, stroke, 12, 16, 12, 11);
        _leaf(canvas, stroke, 12, 13, 8, 9, 8, 13);
        _leaf(canvas, stroke, 12, 12, 16, 8, 16, 12);
        break;

      case AgrarianSymbol.market:
        _line(canvas, stroke, 4, 11, 4, 21);
        _line(canvas, stroke, 20, 11, 20, 21);
        _line(canvas, stroke, 4, 21, 20, 21);
        final canopy = Path()
          ..moveTo(3, 10)
          ..lineTo(5, 4)
          ..lineTo(19, 4)
          ..lineTo(21, 10)
          ..quadraticBezierTo(19, 13, 16.5, 10.5)
          ..quadraticBezierTo(14.2, 13, 12, 10.5)
          ..quadraticBezierTo(9.8, 13, 7.5, 10.5)
          ..quadraticBezierTo(5, 13, 3, 10)
          ..close();
        canvas.drawPath(canopy, tint);
        canvas.drawPath(canopy, stroke);
        _line(canvas, stroke, 8, 17, 16, 17);
        _line(canvas, stroke, 10, 17, 10, 21);
        break;

      case AgrarianSymbol.receiptScale:
        final paper = Path()
          ..moveTo(5, 3)
          ..lineTo(19, 3)
          ..lineTo(19, 21)
          ..lineTo(16.5, 19.5)
          ..lineTo(14, 21)
          ..lineTo(12, 19.5)
          ..lineTo(10, 21)
          ..lineTo(7.5, 19.5)
          ..lineTo(5, 21)
          ..close();
        canvas.drawPath(paper, tint);
        canvas.drawPath(paper, stroke);
        _line(canvas, stroke, 8, 7, 16, 7);
        _line(canvas, stroke, 12, 10, 12, 15);
        _line(canvas, stroke, 8, 11, 16, 11);
        final pan = Path()
          ..moveTo(8, 14)
          ..quadraticBezierTo(12, 19, 16, 14);
        canvas.drawPath(pan, stroke);
        break;

      case AgrarianSymbol.coinPouch:
        final pouch = Path()
          ..moveTo(8, 8)
          ..quadraticBezierTo(4, 10, 4, 16)
          ..quadraticBezierTo(4, 21, 12, 21)
          ..quadraticBezierTo(20, 21, 20, 16)
          ..quadraticBezierTo(20, 10, 16, 8)
          ..close();
        canvas.drawPath(pouch, tint);
        canvas.drawPath(pouch, stroke);
        _line(canvas, stroke, 9, 8, 15, 8);
        _line(canvas, stroke, 8, 4, 12, 6);
        _line(canvas, stroke, 16, 4, 12, 6);
        canvas.drawCircle(const Offset(12, 15), 2.3, stroke);
        break;

      case AgrarianSymbol.grower:
        final hat = Path()
          ..moveTo(6, 8)
          ..lineTo(8, 4)
          ..quadraticBezierTo(12, 2, 16, 4)
          ..lineTo(18, 8)
          ..moveTo(4, 8)
          ..quadraticBezierTo(12, 10, 20, 8);
        canvas.drawPath(hat, stroke);
        canvas.drawCircle(const Offset(12, 12.5), 3.2, stroke);
        final shoulders = Path()
          ..moveTo(4, 21)
          ..quadraticBezierTo(5.5, 17, 9, 17)
          ..moveTo(15, 17)
          ..quadraticBezierTo(18.5, 17, 20, 21)
          ..lineTo(4, 21);
        canvas.drawPath(shoulders, stroke);
        break;

      case AgrarianSymbol.sprout:
        _line(canvas, stroke, 12, 21, 12, 9);
        _leaf(canvas, stroke, 12, 13, 5, 6, 5, 14);
        _leaf(canvas, stroke, 12, 11, 19, 4, 19, 12);
        _line(canvas, stroke, 7, 21, 17, 21);
        break;
    }
    canvas.restore();
  }

  void _line(
      Canvas canvas, Paint paint, double x1, double y1, double x2, double y2) {
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
  }

  void _leaf(Canvas canvas, Paint paint, double sx, double sy, double tipX,
      double tipY, double endX, double endY) {
    final path = Path()
      ..moveTo(sx, sy)
      ..quadraticBezierTo(tipX, tipY, endX, endY)
      ..quadraticBezierTo((tipX + sx) / 2, (tipY + sy) / 2 + 2, sx, sy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AgrarianPainter oldDelegate) =>
      oldDelegate.symbol != symbol ||
      oldDelegate.color != color ||
      oldDelegate.active != active;
}
