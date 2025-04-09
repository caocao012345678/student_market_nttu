import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:student_market_nttu/models/product.dart';
import 'package:intl/intl.dart';
import 'package:student_market_nttu/screens/product_detail_screen.dart';
import 'package:student_market_nttu/screens/user_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/services/product_service.dart';
import 'package:student_market_nttu/services/favorites_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:student_market_nttu/widgets/product_card_standard.dart';

/// @deprecated Use ProductCardStandard instead
/// This widget is kept for backward compatibility
class ProductCard extends StatelessWidget {
  final dynamic product;
  final bool showFavoriteButton;
  final bool isCompact;
  final bool isListView;
  final Function()? onFavoriteToggle;

  const ProductCard({
    super.key,
    required this.product,
    this.showFavoriteButton = true,
    this.isCompact = false,
    this.isListView = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Forward to the new implementation
    return ProductCardStandard(
      product: product,
      showFavoriteButton: showFavoriteButton,
      isCompact: isCompact,
      isListView: isListView,
      onFavoriteToggle: onFavoriteToggle,
    );
  }
} 