import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  const SvgIcon(
    this.iconName, {
    super.key,
    this.color,
    this.size,
    this.useOriginalColor = false,
  });

  final String iconName;
  final Color? color;
  final bool useOriginalColor;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final IconThemeData iconTheme = IconTheme.of(context);
    final double iconSize = size ?? iconTheme.size ?? kDefaultFontSize;
    final Color iconColor = color ?? IconTheme.of(context).color!;
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: Center(
          child: SvgPicture.asset(
        'assets/icons/$iconName.svg',
        colorFilter: useOriginalColor
            ? null
            : ColorFilter.mode(iconColor, BlendMode.srcIn),
      )),
    );
  }
}
