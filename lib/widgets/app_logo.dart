import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Widget pour afficher le logo ENVIROX
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final MainAxisAlignment alignment;

  const AppLogo({
    Key? key,
    this.size = 48,
    this.showText = true,
    this.alignment = MainAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo ENVIROX depuis le fichier image
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo-envirox.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            'ENVIROX',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
          Text(
            'Sauvegarde Environnementale',
            style: TextStyle(
              fontSize: size * 0.15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Logo compact pour les AppBar
class AppLogoCompact extends StatelessWidget {
  final double size;

  const AppLogoCompact({
    Key? key,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo-envirox.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
