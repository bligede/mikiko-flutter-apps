import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// Logo **Mikiko Technology** — perusahaan yang memiliki sistem ini.
///
/// Memakai `assets/logos/mikiko_technology.png` bila tersedia; kalau belum,
/// menampilkan versi vektor bawaan (lingkaran teal + mark + wordmark).
class MikikoTechnologyLogo extends StatelessWidget {
  const MikikoTechnologyLogo({
    super.key,
    this.height = 34,
    this.showWordmark = true,
  });

  final double height;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BrandAssets.mikiko,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          _MikikoVector(height: height, showWordmark: showWordmark),
    );
  }
}

/// Mark Mikiko saja (tanpa wordmark), untuk ruang sempit.
class MikikoMark extends StatelessWidget {
  const MikikoMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: const CustomPaint(painter: _DogMarkPainter()),
    );
  }
}

class _MikikoVector extends StatelessWidget {
  const _MikikoVector({required this.height, required this.showWordmark});

  final double height;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: height,
          width: height,
          child: const CustomPaint(painter: _DogMarkPainter()),
        ),
        if (showWordmark) ...<Widget>[
          SizedBox(width: height * 0.28),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'MIKIKO',
                style: TextStyle(
                  fontSize: height * 0.42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: height * 0.03,
                  height: 1.0,
                  color: Palette.mist,
                ),
              ),
              SizedBox(height: height * 0.05),
              Text(
                'TECHNOLOGY',
                style: TextStyle(
                  fontSize: height * 0.19,
                  fontWeight: FontWeight.w500,
                  letterSpacing: height * 0.075,
                  height: 1.0,
                  color: Palette.mistDim,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Kepala anjing putih di dalam lingkaran teal — mark Mikiko Technology.
class _DogMarkPainter extends CustomPainter {
  const _DogMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(c, s / 2, Paint()..color = Palette.mikikoTeal);

    final fg = Paint()..color = Colors.white;
    final cut = Paint()..color = Palette.mikikoTeal;

    // Telinga kiri & kanan.
    for (final side in <double>[-1, 1]) {
      canvas.save();
      canvas.translate(c.dx + side * s * 0.27, c.dy - s * 0.05);
      canvas.rotate(side * 0.32);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s * 0.21, height: s * 0.36),
        fg,
      );
      canvas.restore();
    }

    // Kepala.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy - s * 0.03),
          width: s * 0.47,
          height: s * 0.45,
        ),
        Radius.circular(s * 0.16),
      ),
      fg,
    );

    // Moncong.
    canvas.drawCircle(Offset(c.dx, c.dy + s * 0.17), s * 0.155, fg);

    // Mata & hidung (warna latar).
    canvas.drawCircle(Offset(c.dx - s * 0.10, c.dy - s * 0.05), s * 0.034, cut);
    canvas.drawCircle(Offset(c.dx + s * 0.10, c.dy - s * 0.05), s * 0.034, cut);
    canvas.drawCircle(Offset(c.dx, c.dy + s * 0.17), s * 0.052, cut);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Logo **Petani Muda Keren** — komunitas yang memayungi aktivitas perusahaan.
///
/// Memakai `assets/logos/petani_muda_keren.png` bila tersedia; kalau belum,
/// menampilkan versi vektor bawaan (teks + sapuan kuas hijau).
class PetaniMudaKerenLogo extends StatelessWidget {
  const PetaniMudaKerenLogo({super.key, this.height = 68});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BrandAssets.petaniMudaKeren,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(
        height: height,
        child: const FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          child: _PetaniVector(),
        ),
      ),
    );
  }
}

class _PetaniVector extends StatelessWidget {
  const _PetaniVector();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'PETANI MUDA',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
            height: 1.05,
            color: Palette.petaniBlue,
          ),
        ),
        const Text(
          'Keren!',
          style: TextStyle(
            fontSize: 58,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            height: 1.0,
            color: Palette.petaniGreen,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 268,
          height: 34,
          child: CustomPaint(painter: _BrushSwooshPainter()),
        ),
      ],
    );
  }
}

/// Sapuan kuas hijau di bawah tulisan "Keren!".
class _BrushSwooshPainter extends CustomPainter {
  const _BrushSwooshPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = Palette.petaniGreen
      ..style = PaintingStyle.fill;

    // Sapuan utama (bulan sabit).
    final main = Path()
      ..moveTo(w * 0.02, h * 0.38)
      ..cubicTo(w * 0.30, h * 1.02, w * 0.70, h * 1.02, w * 0.94, h * 0.24)
      ..cubicTo(w * 0.72, h * 0.66, w * 0.34, h * 0.74, w * 0.02, h * 0.38)
      ..close();
    canvas.drawPath(main, paint);

    // Ekor tipis di ujung kanan.
    final tail = Path()
      ..moveTo(w * 0.66, h * 0.70)
      ..cubicTo(w * 0.80, h * 0.62, w * 0.90, h * 0.46, w * 0.99, h * 0.22)
      ..cubicTo(w * 0.90, h * 0.48, w * 0.80, h * 0.62, w * 0.64, h * 0.76)
      ..close();
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Blok atribusi merek: perusahaan + komunitas.
class BrandBanner extends StatelessWidget {
  const BrandBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'SISTEM INI DIKEMBANGKAN OLEH',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          const MikikoTechnologyLogo(height: 32),
          if (compact) const SizedBox(height: 14) else const SizedBox(height: 18),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 14),
          Text(
            'DIPAYUNGI KOMUNITAS',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          PetaniMudaKerenLogo(height: compact ? 52 : 62),
        ],
      ),
    );
  }
}
