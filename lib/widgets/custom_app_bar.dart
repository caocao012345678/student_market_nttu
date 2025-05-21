import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class CustomAppBar extends PreferredSize {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showBackButton;
  final Widget? leadingIcon;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final double elevation;
  final VoidCallback? onBackPressed;

  CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.showBackButton = false,
    this.leadingIcon,
    this.flexibleSpace,
    this.bottom,
    this.elevation = 0.0,
    this.onBackPressed,
  }) : super(
          key: key,
          preferredSize: Size.fromHeight(bottom != null ? 100.0 : 56.0),
          child: Builder(
            builder: (context) => AppBar(
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: centerTitle,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: elevation,
              leading: showBackButton
                  ? (leadingIcon ??
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: onBackPressed ??
                            () {
                              Navigator.of(context).pop();
                            },
                      ))
                  : leadingIcon,
              actions: actions,
              flexibleSpace: flexibleSpace,
              bottom: bottom,
            ),
          ),
        );
} 