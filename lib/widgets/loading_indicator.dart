import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? message;
  final TextStyle? textStyle;

  const LoadingIndicator({
    Key? key,
    this.size = 40.0,
    this.strokeWidth = 4.0,
    this.color,
    this.message,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.primary,
            ),
            strokeWidth: strokeWidth,
          ),
        ),
        if (message != null) ...[
          SizedBox(height: 16),
          Text(
            message!,
            style: textStyle ??
                TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
} 