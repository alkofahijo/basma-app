import 'package:flutter/material.dart';

class HomeScreenButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;

  const HomeScreenButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: size.width,
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
          vertical: size.height * 0.02,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 5),
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: size.width * 0.16,
              height: size.width * 0.16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: size.width * 0.095),
            ),

            SizedBox(width: size.width * 0.04),

            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),

                  SizedBox(height: size.height * 0.005),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: size.width * 0.035,
                      color: Colors.black.withOpacity(0.75),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: size.width * 0.02),

            Icon(
              Icons.chevron_right_rounded,
              color: Colors.black.withOpacity(0.45),
              size: size.width * 0.075,
            ),
          ],
        ),
      ),
    );
  }
}
