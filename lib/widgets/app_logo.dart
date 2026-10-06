// ============================================================
// WIDGET: LOGO APLIKASI
// Menampilkan logo PERSIS seperti ikon launcher di home screen:
//   - latar gradasi penuh (indigo -> deep indigo, sudut 135°)
//   - mark (ring + centang + spark) dari assets/logo/app_mark.svg
//     yang proporsinya identik dengan foreground ikon adaptif.
// Fallback: app_logo.svg -> app_logo.png -> ikon centang bawaan.
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color fallbackColor;
  const AppLogo({
    super.key,
    this.size = 40,
    this.fallbackColor = const Color(0xFF4F46E5),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: SizedBox(
        width: size,
        height: size,
        // Latar gradasi penuh = latar ikon launcher (icon_bg.png).
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.7, -0.7), // 135deg: kiri-atas
              end: Alignment(0.7, 0.7), //    ke kanan-bawah
              colors: [
                Color(0xFF6366F1), // 0%
                Color(0xFF4F46E5), // 45%
                Color(0xFF3730A3), // 100%
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
          alignment: Alignment.center,
          // Mark saja, proporsi 62% persis seperti foreground launcher.
          child: SvgPicture.asset(
            'assets/logo/app_mark.svg',
            width: size,
            height: size,
            // Jika mark gagal dimuat, coba logo utuh...
            errorBuilder: (context, error, stackTrace) => SvgPicture.asset(
              'assets/logo/app_logo.svg',
              width: size,
              height: size,
              fit: BoxFit.cover,
              // ...lalu PNG, dan terakhir ikon bawaan.
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/logo/app_logo.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: size * 0.55,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
