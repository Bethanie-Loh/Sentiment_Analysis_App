import 'dart:ui';
import 'package:app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AppLoading extends StatelessWidget {
  final Color color;
  final double size;

  const AppLoading({
    super.key,
    this.color = AppColors.turquiose,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          ),
        ),
        Center(
          child: SpinKitPouringHourGlass(
            color: color,
            size: size,
          ),
        ),
      ],
    );
  }
}
