import 'package:flutter/material.dart';

import '../models/models.dart';
import 'common.dart';

/// Grafik garis ringan tanpa dependensi eksternal.
class MetricLineChart extends StatelessWidget {
  const MetricLineChart({
    super.key,
    required this.points,
    required this.color,
    this.height = 170,
    this.showLabels = true,
  });

  final List<TimePoint> points;
  final Color color;
  final double height;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: const EmptyState(icon: Icons.show_chart, title: 'Belum ada data'),
      );
    }
    return Column(
      children: <Widget>[
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(
              points: points,
              color: color,
              gridColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              labelStyle: theme.textTheme.labelSmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  kTimeFormat.format(points.first.time),
                  style: theme.textTheme.labelSmall,
                ),
                Text(
                  kTimeFormat.format(points.last.time),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.points,
    required this.color,
    required this.gridColor,
    required this.labelStyle,
  });

  final List<TimePoint> points;
  final Color color;
  final Color gridColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 34.0;
    const topPad = 8.0;
    const bottomPad = 6.0;
    final chartWidth = size.width - leftPad;
    final chartHeight = size.height - topPad - bottomPad;

    var minV = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    var maxV = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    if ((maxV - minV).abs() < 0.001) {
      maxV += 1;
      minV -= 1;
    }
    final padding = (maxV - minV) * 0.12;
    minV -= padding;
    maxV += padding;

    double xFor(int i) => leftPad + chartWidth * (i / (points.length - 1));
    double yFor(double v) => topPad + chartHeight * (1 - (v - minV) / (maxV - minV));

    // Garis bantu horizontal + label nilai.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const gridLines = 4;
    for (var i = 0; i <= gridLines; i++) {
      final y = topPad + chartHeight * (i / gridLines);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      final value = maxV - (maxV - minV) * (i / gridLines);
      final tp = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(0), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Area di bawah garis.
    final areaPath = Path()..moveTo(xFor(0), yFor(points.first.value));
    for (var i = 1; i < points.length; i++) {
      areaPath.lineTo(xFor(i), yFor(points[i].value));
    }
    areaPath
      ..lineTo(xFor(points.length - 1), topPad + chartHeight)
      ..lineTo(xFor(0), topPad + chartHeight)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[color.withValues(alpha: 0.32), color.withValues(alpha: 0.02)],
        ).createShader(Rect.fromLTWH(leftPad, topPad, chartWidth, chartHeight)),
    );

    // Garis utama.
    final linePath = Path()..moveTo(xFor(0), yFor(points.first.value));
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(xFor(i), yFor(points[i].value));
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Titik terakhir.
    final last = Offset(xFor(points.length - 1), yFor(points.last.value));
    canvas.drawCircle(last, 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(last, 3.0, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
