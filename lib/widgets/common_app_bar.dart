import 'package:flutter/material.dart';
import 'package:student_market_nttu/screens/search_screen.dart';
import 'package:student_market_nttu/widgets/cart_badge.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showCartBadge;
  final bool showDrawer;
  final List<Widget>? additionalActions;
  final PreferredSizeWidget? bottom;

  const CommonAppBar({
    Key? key,
    required this.title,
    this.showCartBadge = true,
    this.showDrawer = true,
    this.additionalActions,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue[900],
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchScreen(),
              ),
            );
          },
        ),
        if (showCartBadge) const CartBadge(),
        if (additionalActions != null) ...additionalActions!,
      ],
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(bottom == null ? kToolbarHeight : kToolbarHeight + bottom!.preferredSize.height);
} 