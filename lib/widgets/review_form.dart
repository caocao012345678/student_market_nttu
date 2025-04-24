import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/review_service.dart';
import '../models/review.dart';
import '../services/product_service.dart';

class ReviewForm extends StatefulWidget {
  final String productId;
  final String productName;
  final Function onReviewAdded;

  const ReviewForm({
    Key? key,
    required this.productId,
    required this.productName,
    required this.onReviewAdded,
  }) : super(key: key);

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 5;
  List<dynamic> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final result = await picker.pickMultiImage();
    
    if (result.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(result);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn cần đăng nhập để đánh giá')),
        );
        return;
      }

      final reviewService = Provider.of<ReviewService>(context, listen: false);
      final productService = Provider.of<ProductService>(context, listen: false);

      // Upload images if any
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await productService.uploadProductImages(_selectedImages);
      }

      // Create review object
      final review = Review(
        id: '',
        productId: widget.productId,
        userId: currentUser.uid,
        userEmail: currentUser.email ?? 'Người dùng',
        rating: _rating,
        comment: _commentController.text,
        createdAt: DateTime.now(),
        images: imageUrls.isNotEmpty ? imageUrls : null,
        likes: [],
        comments: [],
      );

      // Add review
      final reviewId = await reviewService.addReview(review);

      // Clear form
      _commentController.clear();
      setState(() {
        _rating = 5;
        _selectedImages = [];
        _isSubmitting = false;
      });

      // Callback
      widget.onReviewAdded();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đánh giá của bạn đã được gửi thành công')),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi đánh giá: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đánh giá sản phẩm: ${widget.productName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Rating stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(
                        i <= _rating ? Icons.star : Icons.star_border,
                        color: i <= _rating ? Colors.amber : Colors.grey,
                        size: 36,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = i.toDouble();
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Comment field
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Nhận xét của bạn',
                  hintText: 'Chia sẻ trải nghiệm của bạn về sản phẩm này',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập nhận xét';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Image selection
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Thêm ảnh'),
                    onPressed: _pickImages,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedImages.length} ảnh đã chọn',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Display selected images
              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: kIsWeb
                                ? Image.network(
                                    (_selectedImages[index] as XFile).path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File((_selectedImages[index] as XFile).path),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Gửi đánh giá',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 