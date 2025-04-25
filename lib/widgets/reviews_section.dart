import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import 'review_form.dart';

class ReviewsSection extends StatefulWidget {
  final String productId;
  final String productName;
  final double rating;
  final int reviewCount;

  const ReviewsSection({
    Key? key,
    required this.productId,
    required this.productName,
    required this.rating,
    required this.reviewCount,
  }) : super(key: key);

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  bool _showAddReview = false;

  void _toggleAddReview() {
    setState(() {
      _showAddReview = !_showAddReview;
    });
  }

  void _onReviewAdded() {
    setState(() {
      _showAddReview = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final reviewService = Provider.of<ReviewService>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề và điểm đánh giá tổng quan
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đánh giá (${widget.reviewCount})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (currentUser != null && !_showAddReview)
                ElevatedButton.icon(
                  icon: const Icon(Icons.rate_review),
                  label: const Text('Viết đánh giá'),
                  onPressed: _toggleAddReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),

        // Hiển thị tổng quan điểm đánh giá
        if (widget.reviewCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  widget.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < widget.rating.floor()
                              ? Icons.star
                              : (index < widget.rating.ceil() &&
                                      widget.rating.floor() != widget.rating.ceil())
                                  ? Icons.star_half
                                  : Icons.star_border,
                          color: Colors.amber,
                          size: 24,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.reviewCount} đánh giá',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Form thêm đánh giá mới
        if (_showAddReview)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ReviewForm(
                  productId: widget.productId,
                  productName: widget.productName,
                  onReviewAdded: _onReviewAdded,
                ),
                TextButton(
                  onPressed: _toggleAddReview,
                  child: const Text('Hủy'),
                ),
              ],
            ),
          ),

        // Danh sách đánh giá
        StreamBuilder<List<Review>>(
          stream: reviewService.getReviewsByProductId(widget.productId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Lỗi: ${snapshot.error}'),
              );
            }

            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.rate_review_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có đánh giá nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!_showAddReview && currentUser != null)
                        ElevatedButton(
                          onPressed: _toggleAddReview,
                          child: const Text('Viết đánh giá đầu tiên'),
                        ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _buildReviewItem(context, review);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewItem(BuildContext context, Review review) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final reviewService = Provider.of<ReviewService>(context, listen: false);
    final bool isUserReview = currentUser?.uid == review.userId;
    final bool userLiked = review.likes.contains(currentUser?.uid);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin người dùng và thời gian
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userEmail,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dateFormat.format(review.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUserReview)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xóa đánh giá'),
                          content: const Text('Bạn có chắc chắn muốn xóa đánh giá này?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await reviewService.deleteReview(review.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã xóa đánh giá')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi khi xóa đánh giá: $e')),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Xếp hạng sao
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Nội dung đánh giá
            Text(review.comment),
            const SizedBox(height: 8),
            
            // Hiển thị hình ảnh nếu có
            if (review.images != null && review.images!.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images!.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // Show full image when tapped
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: CachedNetworkImage(
                              imageUrl: review.images![index],
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 100,
                        height: 100,
                        child: CachedNetworkImage(
                          imageUrl: review.images![index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            
            // Like button and count
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    userLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: userLiked ? Colors.blue : null,
                  ),
                  onPressed: currentUser != null
                      ? () async {
                          try {
                            await reviewService.toggleReviewLike(
                              review.id,
                              currentUser!.uid,
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e')),
                            );
                          }
                        }
                      : null,
                ),
                Text(
                  review.likes.length.toString(),
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 