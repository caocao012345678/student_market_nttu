import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/product.dart';
import '../screens/product_detail_screen.dart';
import '../screens/user_profile_page.dart';
import '../services/favorites_service.dart';

class ProductCardStandard extends StatefulWidget {
  final Product product;
  final bool showFavoriteButton;
  final bool isCompact;
  final bool isListView;
  final Function()? onFavoriteToggle;

  const ProductCardStandard({
    super.key,
    required this.product,
    this.showFavoriteButton = true,
    this.isCompact = false,
    this.isListView = false,
    this.onFavoriteToggle,
  });

  @override
  State<ProductCardStandard> createState() => _ProductCardStandardState();
}

class _ProductCardStandardState extends State<ProductCardStandard> {
  bool _isFavorite = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    if (!widget.showFavoriteButton) return;
    
    final favoritesService = Provider.of<FavoritesService>(context, listen: false);
    final isFav = await favoritesService.isProductFavorite(widget.product.id);
    
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final favoritesService = Provider.of<FavoritesService>(context, listen: false);
      
      if (_isFavorite) {
        await favoritesService.removeFromFavorites(widget.product.id);
      } else {
        await favoritesService.addToFavorites(widget.product.id);
      }
      
      setState(() {
        _isFavorite = !_isFavorite;
        _isLoading = false;
      });
      
      if (widget.onFavoriteToggle != null) {
        widget.onFavoriteToggle!();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra: $e')),
      );
    }
  }

  String _getTimeAgo() {
    if (widget.product.createdAt == null) return '';
    
    return timeago.format(widget.product.createdAt!, locale: 'vi');
  }
  
  Widget _buildFavoriteButton() {
    if (!widget.showFavoriteButton) return const SizedBox.shrink();
    
    return _isLoading 
      ? const SizedBox(
          width: 36,
          height: 36,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        )
      : IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.grey,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          onPressed: _toggleFavorite,
        );
  }

  Widget _buildPriceSection() {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    
    final hasDiscount = widget.product.originalPrice > 0 && 
                        widget.product.originalPrice > widget.product.price;
    
    if (hasDiscount) {
      return Row(
        children: [
          Text(
            currencyFormat.format(widget.product.price),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              currencyFormat.format(widget.product.originalPrice),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
                decoration: TextDecoration.lineThrough,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      return Text(
        currencyFormat.format(widget.product.price),
        style: const TextStyle(
          fontSize: 14,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  Widget _buildDiscountBadge() {
    final hasDiscount = widget.product.originalPrice > 0 && 
                      widget.product.originalPrice > widget.product.price;
    
    if (!hasDiscount) return const SizedBox.shrink();
    
    final discountPercentage = ((widget.product.originalPrice - widget.product.price) / 
                            widget.product.originalPrice * 100).round();
    
    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.isListView ? 4 : 8, 
          vertical: widget.isListView ? 2 : 4
        ),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(widget.isListView ? 8 : 12),
          ),
        ),
        child: Text(
          '-$discountPercentage%',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: widget.isListView ? 10 : 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSoldOverlay() {
    if (!widget.product.isSold) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'ĐÃ BÁN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: widget.isListView ? 12 : 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConditionBadge() {
    if (widget.product.condition == 'Mới' || widget.isListView) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      bottom: 0,
      left: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.product.condition == 'Cũ - Còn tốt' 
              ? Colors.orange 
              : Colors.blue[700],
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
          ),
        ),
        child: Text(
          widget.product.condition,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeAgoBadge() {
    if (widget.product.createdAt == null || widget.isCompact || widget.isListView) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      top: 0,
      right: widget.showFavoriteButton ? 40 : 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _getTimeAgo(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildSellerInfo() {
    if (widget.isCompact || widget.isListView) return const SizedBox.shrink();
    
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfilePage(
                      userId: widget.product.sellerId,
                      username: widget.product.sellerName.isNotEmpty
                          ? widget.product.sellerName
                          : 'Người bán',
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Hero(
                    tag: 'seller-avatar-${widget.product.sellerId}',
                    child: CircleAvatar(
                      radius: 10,
                      backgroundImage: widget.product.sellerAvatar.isNotEmpty
                          ? NetworkImage(widget.product.sellerAvatar)
                          : null,
                      backgroundColor: Colors.grey[300],
                      child: widget.product.sellerAvatar.isEmpty
                          ? const Icon(Icons.person, size: 12, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.product.sellerName.isNotEmpty
                          ? widget.product.sellerName
                          : 'Người bán',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.remove_red_eye, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 2),
              Text(
                '${widget.product.viewCount}',
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListViewLayout() {
    return SizedBox(
      height: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: widget.product),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              SizedBox(
                width: 120,
                height: 140,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Hero(
                        tag: 'product-${widget.product.id}',
                        child: CachedNetworkImage(
                          imageUrl: widget.product.images.isNotEmpty
                              ? widget.product.images.first
                              : 'https://via.placeholder.com/400x300',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    _buildSoldOverlay(),
                    _buildDiscountBadge(),
                  ],
                ),
              ),
              // Info section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildPriceSection(),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.product.location.isNotEmpty
                                  ? widget.product.location
                                  : 'NTTU',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (widget.product.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.product.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Favorite button
              if (widget.showFavoriteButton)
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: _buildFavoriteButton(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridViewLayout() {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: widget.product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with badges section
            AspectRatio(
              aspectRatio: widget.isCompact ? 1 : 1.2,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: 'product-${widget.product.id}',
                      child: CachedNetworkImage(
                        imageUrl: widget.product.images.isNotEmpty
                            ? widget.product.images.first
                            : 'https://via.placeholder.com/400x300',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  _buildSoldOverlay(),
                  _buildDiscountBadge(),
                  _buildConditionBadge(),
                  _buildTimeAgoBadge(),
                  // Favorite button
                  if (widget.showFavoriteButton)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: _buildFavoriteButton(),
                      ),
                    ),
                ],
              ),
            ),
            // Product info section
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildPriceSection(),
                  const SizedBox(height: 6),
                  // Show the category and location in a more compact way
                  if (!widget.isCompact) 
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.product.location.isNotEmpty
                                ? widget.product.location
                                : 'NTTU',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.product.category.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.product.category,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  if (!widget.isCompact)
                    const SizedBox(height: 6),
                  // Seller info
                  _buildSellerInfo(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isListView ? _buildListViewLayout() : _buildGridViewLayout();
  }
} 