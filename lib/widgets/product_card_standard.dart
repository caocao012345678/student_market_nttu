import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/product.dart';
import '../screens/product_detail_screen.dart';
import '../screens/user_profile_page.dart';
import '../services/favorites_service.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../utils/location_utils.dart';

class ProductCardStandard extends StatefulWidget {
  final Product product;
  final bool showFavoriteButton;
  final bool isCompact;
  final bool isListView;
  final Function()? onFavoriteToggle;
  final bool showDistance;
  final Map<String, double>? userLocation;

  const ProductCardStandard({
    super.key,
    required this.product,
    this.showFavoriteButton = true,
    this.isCompact = false,
    this.isListView = false,
    this.onFavoriteToggle,
    this.showDistance = false,
    this.userLocation,
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
    // Register Vietnamese locale for timeago
    timeago.setLocaleMessages('vi', timeago.ViMessages());
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

  Future<void> _addToCart() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final cartService = Provider.of<CartService>(context, listen: false);
    
    if (authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      await cartService.addToCart(widget.product, authService.currentUser!.uid);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${widget.product.title} vào giỏ hàng')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getTimeAgo() {
    if (widget.product.createdAt == null) return '';
    
    // Calculate time difference
    final now = DateTime.now();
    final difference = now.difference(widget.product.createdAt!);
    
    // Custom Vietnamese time text
    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years năm trước';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create a theme-aware design
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final cardRadius = BorderRadius.circular(widget.isCompact ? 8 : 12);
    final double cardHeight = widget.isCompact ? 
                        (widget.isListView ? 120.0 : 200.0) : 
                        (widget.isListView ? 150.0 : 260.0);
                        
    // Format currency
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    
    // Discount calculations
    final hasDiscount = widget.product.originalPrice > 0 && 
                        widget.product.originalPrice > widget.product.price;
    final discountPercentage = hasDiscount ? 
      ((widget.product.originalPrice - widget.product.price) / 
      widget.product.originalPrice * 100).round() : 0;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              product: widget.product,
            ),
          ),
        );
      },
      child: Container(
        height: cardHeight.toDouble(),
        decoration: BoxDecoration(
          borderRadius: cardRadius,
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: widget.isListView 
          ? _buildListViewLayout(primaryColor, currencyFormat, hasDiscount, discountPercentage)
          : _buildGridViewLayout(primaryColor, currencyFormat, hasDiscount, discountPercentage),
      ),
    );
  }
  
  Widget _buildGridViewLayout(Color primaryColor, NumberFormat currencyFormat, bool hasDiscount, int discountPercentage) {
    // Tính khoảng cách nếu có vị trí
    double? distance;
    if (widget.showDistance && widget.userLocation != null) {
      final productLocation = LocationUtils.getLocationFromAddress(widget.product.location);
      if (productLocation != null) {
        distance = LocationUtils.calculateDistance(
          widget.userLocation!['lat']!, widget.userLocation!['lng']!,
          productLocation['lat']!, productLocation['lng']!
        );
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image with badges
        Expanded(
          flex: 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Product image
              _buildProductImage(),
              
              // Sold overlay
              if (widget.product.isSold)
                _buildSoldOverlay(),
              
              // Discount badge
              if (hasDiscount)
                _buildDiscountBadge(discountPercentage),
              
              // New badge (less than 3 days old)
              if (!widget.product.isSold && 
                  widget.product.createdAt != null &&
                  DateTime.now().difference(widget.product.createdAt!).inDays < 3)
                _buildNewBadge(),
              
              // Distance badge
              if (widget.showDistance && distance != null)
                _buildDistanceBadge(distance),
              
              // Favorite button
              if (widget.showFavoriteButton && !widget.product.isSold)
                Positioned(
                  top: 4,
                  right: 4,
                  child: _buildFavoriteButton(),
                ),
            ],
          ),
        ),
        
        // Product info
        Expanded(
          flex: widget.isCompact ? 2 : 3,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  widget.product.title,
                  maxLines: widget.isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.isCompact ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Price
                _buildPriceSection(currencyFormat, hasDiscount, primaryColor),
                
                const SizedBox(height: 4),
                
                // Seller row or time ago
                if (!widget.isCompact)
                  Row(
                    children: [
                      // Sử dụng CircleAvatar với CachedNetworkImageProvider cho avatar
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: widget.product.sellerAvatar.isNotEmpty
                            ? CachedNetworkImageProvider(widget.product.sellerAvatar) as ImageProvider
                            : null,
                        backgroundColor: Colors.grey[200],
                        child: widget.product.sellerAvatar.isEmpty
                            ? const Icon(Icons.store, size: 10, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.product.sellerName.isNotEmpty
                              ? widget.product.sellerName
                              : 'Người bán',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    _getTimeAgo(),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[700],
                    ),
                  ),
                
                // Location and stats row
                if (!widget.isCompact) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Location
                      if (widget.product.location != null)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: Colors.grey[700]),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  widget.product.location?['address'] ?? 'Không xác định',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Views
                      Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 12, color: Colors.grey[700]),
                          const SizedBox(width: 2),
                          Text(
                            widget.product.viewCount.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Add to cart button (only show for non-compact, non-sold products)
        if (!widget.isCompact && !widget.product.isSold && !widget.isListView)
          InkWell(
            onTap: _addToCart,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Thêm vào giỏ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildListViewLayout(Color primaryColor, NumberFormat currencyFormat, bool hasDiscount, int discountPercentage) {
    // Tính khoảng cách nếu có vị trí
    double? distance;
    if (widget.showDistance && widget.userLocation != null) {
      final productLocation = LocationUtils.getLocationFromAddress(widget.product.location);
      if (productLocation != null) {
        distance = LocationUtils.calculateDistance(
          widget.userLocation!['lat']!, widget.userLocation!['lng']!,
          productLocation['lat']!, productLocation['lng']!
        );
      }
    }
    
    return Row(
      children: [
        // Image container (left side)
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildProductImage(),
              
              // Sold overlay
              if (widget.product.isSold)
                _buildSoldOverlay(),
              
              // Discount badge
              if (hasDiscount)
                _buildDiscountBadge(discountPercentage),
              
              // New badge
              if (!widget.product.isSold && 
                  widget.product.createdAt != null &&
                  DateTime.now().difference(widget.product.createdAt!).inDays < 3)
                _buildNewBadge(),
                
              // Distance badge
              if (widget.showDistance && distance != null)
                _buildDistanceBadge(distance),
                
              // Favorite button
              if (widget.showFavoriteButton && !widget.product.isSold)
                Positioned(
                  top: 4,
                  right: 4,
                  child: _buildFavoriteButton(),
                ),
            ],
          ),
        ),
        
        // Product info (right side)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title
                Text(
                  widget.product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Price
                _buildPriceSection(currencyFormat, hasDiscount, primaryColor),
                
                const Spacer(),
                
                // Bottom row with seller/time and location
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Time or seller
                    Text(
                      _getTimeAgo(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                    
                    // Location
                    if (widget.product.location != null)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.grey[700]),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              widget.product.location?['address'] ?? 'Không xác định',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                
                // Add to cart button (for non-sold products in ListView mode)
                if (!widget.product.isSold)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: InkWell(
                      onTap: _addToCart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Thêm vào giỏ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildProductImage() {
    return widget.product.images.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: widget.product.images.first,
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(
              child: Container(
                color: Colors.grey[200],
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.image_not_supported,
                color: Colors.grey,
              ),
            ),
            // Thêm options để cải thiện hiển thị
            memCacheWidth: 400,
            memCacheHeight: 400,
            maxWidthDiskCache: 800,
            maxHeightDiskCache: 800,
          )
        : Container(
            color: Colors.grey[200],
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
            ),
          );
  }
  
  Widget _buildSoldOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Text(
          'ĐÃ BÁN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
  
  Widget _buildDiscountBadge(int discountPercentage) {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '-$discountPercentage%',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  
  Widget _buildDistanceBadge(double distance) {
    // Định dạng khoảng cách thành m hoặc km
    String distanceText;
    if (distance < 1) {
      // Dưới 1km hiển thị theo mét
      distanceText = '${(distance * 1000).toInt()}m';
    } else {
      // Trên 1km hiển thị theo km, làm tròn 1 số thập phân
      distanceText = '${distance.toStringAsFixed(1)}km';
    }
    
    return Positioned(
      top: widget.product.isSold ? 40 : 8,
      right: widget.showFavoriteButton ? 40 : 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 12,
              color: Colors.amber.shade800,
            ),
            const SizedBox(width: 2),
            Text(
              distanceText,
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNewBadge() {
    return Positioned(
      top: widget.isListView ? 26 : 32,
      left: 0,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.isListView ? 4 : 6, 
          vertical: widget.isListView ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(widget.isListView ? 8 : 12),
            topRight: Radius.circular(widget.isListView ? 8 : 12),
          ),
        ),
        child: Text(
          'MỚI',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: widget.isCompact ? 9 : 11,
          ),
        ),
      ),
    );
  }
  
  Widget _buildFavoriteButton() {
    if (!widget.showFavoriteButton) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
      child: _isLoading 
        ? const SizedBox(
            width: 30,
            height: 30,
            child: Padding(
              padding: EdgeInsets.all(6.0),
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          )
        : IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.grey,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 30,
            ),
            iconSize: 18,
            onPressed: _toggleFavorite,
          ),
    );
  }
  
  Widget _buildPriceSection(NumberFormat currencyFormat, bool hasDiscount, Color primaryColor) {
    if (hasDiscount) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currencyFormat.format(widget.product.price),
            style: TextStyle(
              fontSize: widget.isCompact ? 13 : 15,
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            currencyFormat.format(widget.product.originalPrice),
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.normal,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      );
    } else {
      return Text(
        currencyFormat.format(widget.product.price),
        style: TextStyle(
          fontSize: widget.isCompact ? 13 : 15,
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }
} 