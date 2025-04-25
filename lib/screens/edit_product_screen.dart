import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../services/user_service.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../screens/moderation_result_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  
  const EditProductScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController();
  final _specsController = TextEditingController();
  final _searchCategoryController = TextEditingController();
  
  String _selectedCategoryId = '';
  String _selectedCategoryName = '';
  String _condition = 'Mới';
  bool _isLoadingCategories = true;
  List<Category> _filteredCategories = [];
  String _categoriesError = '';
  
  bool _isGiftItem = false;
  String? _selectedLocationId;
  
  List<dynamic> _images = [];
  List<dynamic> _imageWidgets = [];
  List<String> _tags = [];
  Map<String, String> _specifications = {};
  
  bool _isLoading = false;
  bool _showCategorySearch = false;
  bool _showLocationSelect = false;
  List<String> _existingImageUrls = [];
  
  bool _isGiftCategory = false;
  
  final List<String> _conditionOptions = [
    'Mới',
    'Như mới (99%)',
    'Tốt (90%)',
    'Đã qua sử dụng',
    'Cần sửa chữa',
  ];

  @override
  void initState() {
    super.initState();
    _loadProductData();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCategories();
    });
  }

  // Tải dữ liệu sản phẩm hiện tại
  void _loadProductData() {
    // Lấy dữ liệu từ sản phẩm được truyền vào widget
    final product = widget.product;
    
    _titleController.text = product.title;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toString();
    _originalPriceController.text = product.originalPrice.toString();
    _locationController.text = product.location;
    _quantityController.text = product.quantity.toString();
    
    setState(() {
      _selectedCategoryId = product.category;
      _condition = product.condition;
      _tags = List<String>.from(product.tags);
      
      // Tải specifications
      _specifications = Map<String, String>.from(product.specifications);
      
      // Lưu lại danh sách URL hình ảnh hiện tại
      _existingImageUrls = List<String>.from(product.images);
      
      // Xóa danh sách widget hình ảnh hiện tại
      _imageWidgets = [];
    });
    
    // Tạo widget hiển thị hình ảnh hiện tại
    _createImageWidgets();
  }
  
  // Tạo widget hiển thị các hình ảnh hiện tại
  void _createImageWidgets() {
    // Đảm bảo danh sách rỗng trước khi thêm
    _imageWidgets.clear();
    
    for (final imageUrl in _existingImageUrls) {
      _imageWidgets.add(
        Stack(
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: 100,
              height: 100,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    final index = _existingImageUrls.indexOf(imageUrl);
                    _existingImageUrls.removeAt(index);
                    _imageWidgets.removeAt(index);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          key: ValueKey(imageUrl),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _specsController.dispose();
    _searchCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa sản phẩm'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image picker
                    const Text(
                      'Hình ảnh sản phẩm',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Add image button
                          GestureDetector(
                            onTap: () {
                              // Hiển thị dialog chọn hình từ máy ảnh hoặc thư viện
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Chọn hình ảnh'),
                                    content: SingleChildScrollView(
                                      child: ListBody(
                                        children: [
                                          ListTile(
                                            leading: Icon(Icons.photo_library),
                                            title: Text('Chọn từ thư viện'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              // Chọn ảnh từ thư viện
                                            },
                                          ),
                                          ListTile(
                                            leading: Icon(Icons.photo_camera),
                                            title: Text('Chụp ảnh'),
                                            onTap: () {
                                              Navigator.pop(context);
                                              // Mở camera
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          // Image previews
                          for (var widget in _imageWidgets)
                            Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: widget,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tên sản phẩm',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên sản phẩm';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả sản phẩm',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mô tả sản phẩm';
                        }
                        return null;
                      },
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Price and Original Price
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            enabled: !_isGiftCategory, // Vô hiệu hóa nếu là đồ tặng
                            decoration: InputDecoration(
                              labelText: 'Giá',
                              border: const OutlineInputBorder(),
                              prefixText: 'đ ',
                              helperText: _isGiftCategory ? 'Đồ tặng miễn phí' : null,
                              filled: _isGiftCategory,
                              fillColor: _isGiftCategory ? Colors.grey[200] : null,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập giá';
                              }
                              if (double.tryParse(
                                      value.replaceAll(RegExp(r'[^0-9]'), '')) ==
                                  null) {
                                return 'Giá không hợp lệ';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _originalPriceController,
                            keyboardType: TextInputType.number,
                            enabled: !_isGiftCategory, // Vô hiệu hóa nếu là đồ tặng
                            decoration: InputDecoration(
                              labelText: 'Giá gốc (nếu có)',
                              border: const OutlineInputBorder(),
                              prefixText: 'đ ',
                              filled: _isGiftCategory,
                              fillColor: _isGiftCategory ? Colors.grey[200] : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category
                    GestureDetector(
                      onTap: _showCategoryDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.category, color: Colors.grey),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedCategoryId.isNotEmpty
                                    ? _selectedCategoryName
                                    : 'Chọn danh mục',
                                style: TextStyle(
                                  color: _selectedCategoryId.isNotEmpty
                                      ? Colors.black
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Condition
                    const Text(
                      'Tình trạng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      value: _condition,
                      items: _conditionOptions
                          .map((String condition) => DropdownMenuItem<String>(
                                value: condition,
                                child: Text(condition),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _condition = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quantity
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số lượng';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Số lượng không hợp lệ';
                        }
                        if (int.parse(value) <= 0) {
                          return 'Số lượng phải lớn hơn 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Location
                    GestureDetector(
                      onTap: _openLocationSelectDialog,
                      child: TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Địa điểm',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        enabled: false, // Disable direct editing, only select from list
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn địa điểm';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chọn từ danh sách địa điểm đã lưu trong trang cá nhân',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    
                    // Tags
                    const Text(
                      'Từ khóa tìm kiếm',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _tags.map((tag) => Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () => _removeTag(tag),
                      )).toList(),
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Thêm từ khóa',
                        border: OutlineInputBorder(),
                        helperText: 'Nhập từ khóa và nhấn Enter',
                      ),
                      onFieldSubmitted: (value) {
                        _addTag(value.trim());
                        // Clear the field
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          FocusScope.of(context).previousFocus();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Specifications
                    const Text(
                      'Thông số kỹ thuật',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: _specifications.entries.map((entry) => ListTile(
                        title: Text(entry.key),
                        subtitle: Text(entry.value),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeSpec(entry.key),
                        ),
                      )).toList(),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _specsController,
                            decoration: const InputDecoration(
                              labelText: 'Thêm thông số (Tên: Giá trị)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addSpec,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[900],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: _updateProduct,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Lưu thay đổi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _addSpec() {
    String specText = _specsController.text.trim();
    if (specText.isNotEmpty && specText.contains(':')) {
      List<String> parts = specText.split(':');
      if (parts.length >= 2) {
        String key = parts[0].trim();
        String value = parts.sublist(1).join(':').trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          setState(() {
            _specifications[key] = value;
            _specsController.clear();
          });
        }
      }
    }
  }

  void _removeSpec(String key) {
    setState(() {
      _specifications.remove(key);
    });
  }

  // Cập nhật thông tin sản phẩm
  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      final double price = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final double originalPrice = double.tryParse(_originalPriceController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      final int quantity = int.tryParse(_quantityController.text) ?? 1;
      
      if (_selectedCategoryId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn danh mục')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Cập nhật sản phẩm với thông tin mới
      await Provider.of<ProductService>(context, listen: false).updateProductWithModeration(
        id: widget.product.id,
        title: _titleController.text,
        description: _descriptionController.text,
        price: price,
        category: _selectedCategoryId,
        images: _existingImageUrls,
        condition: _condition,
        location: _locationController.text,
        tags: _tags,
        specifications: _specifications,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật sản phẩm thành công')),
      );
      
      // Trả về true để thông báo rằng đã cập nhật thành công
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  // Khởi tạo danh sách danh mục
  Future<void> _initializeCategories() async {
    try {
      final categoryService = Provider.of<CategoryService>(context, listen: false);
      
      // Kiểm tra nếu danh sách danh mục đã được tải
      if (categoryService.categories.isEmpty) {
        setState(() {
          _isLoadingCategories = true;
        });
        
        await categoryService.fetchCategories();
        
        setState(() {
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _isLoadingCategories = false;
        });
      }
      
      // Lấy tên danh mục từ id đã chọn
      if (_selectedCategoryId.isNotEmpty) {
        _selectedCategoryName = _getCategoryName(_selectedCategoryId);
        _checkIfGiftCategory(_selectedCategoryId);
      }
    } catch (error) {
      setState(() {
        _isLoadingCategories = false;
        _categoriesError = 'Không thể tải danh mục: $error';
      });
      print('Lỗi khởi tạo danh mục: $error');
    }
  }

  // Kiểm tra nếu danh mục đã chọn là danh mục đồ tặng
  void _checkIfGiftCategory(String categoryId) {
    try {
      if (categoryId.isEmpty) {
        setState(() {
          _isGiftCategory = false;
        });
        return;
      }

      final categoryService = Provider.of<CategoryService>(context, listen: false);
      
      if (categoryService.categories.isEmpty) {
        return;
      }
      
      final category = categoryService.categories.firstWhere(
        (category) => category.id == categoryId,
        orElse: () => Category(
          id: '',
          name: '',
          iconName: '',
          icon: Icons.category,
          color: Colors.blue,
          createdAt: DateTime.now(),
        ),
      );

      // Kiểm tra nếu danh mục là 'Đồ tặng' hoặc 'Gift Items'
      final bool isGiftCategory = category.name == 'Đồ tặng' || category.name == 'Gift Items';

      // Cập nhật giá trị _isGiftCategory và giá nếu cần
      setState(() {
        _isGiftCategory = isGiftCategory;
        
        // Nếu là danh mục đồ tặng, đặt giá = 0
        if (isGiftCategory) {
          _priceController.text = '0';
          _originalPriceController.text = '0';
        }
      });
    } catch (e) {
      print('Lỗi khi kiểm tra danh mục đồ tặng: $e');
    }
  }
  
  // Lấy tên danh mục từ ID
  String _getCategoryName(String categoryId) {
    try {
      if (categoryId.isEmpty) return '';
      
      final categoryService = Provider.of<CategoryService>(context, listen: false);
      
      if (categoryService.categories.isEmpty) {
        return '';
      }
      
      final category = categoryService.categories.firstWhere(
        (category) => category.id == categoryId,
        orElse: () => Category(
          id: '',
          name: '',
          iconName: '',
          icon: Icons.category,
          color: Colors.blue,
          createdAt: DateTime.now(),
        ),
      );
      
      return category.name;
    } catch (error) {
      print('Lỗi khi lấy tên danh mục: $error');
      return '';
    }
  }

  // Hiển thị hộp thoại chọn danh mục
  Future<void> _showCategoryDialog() async {
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    
    // Lấy danh sách danh mục và sắp xếp theo tên A-Z
    List<Category> filteredCategories = categoryService.categories;
    filteredCategories.sort((a, b) => a.name.compareTo(b.name));
    
    _searchCategoryController.clear(); // Xóa nội dung tìm kiếm
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final scrollController = ScrollController();
        
        return StatefulBuilder(
          builder: (context, setState) {
            // Lọc danh mục với từ khóa tìm kiếm hiện tại
            void filterCategories(String value) {
              List<Category> categories = categoryService.searchCategories(value);
              categories.sort((a, b) => a.name.compareTo(b.name));
              setState(() {
                filteredCategories = categories;
              });
            }
            
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Chọn danh mục',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchCategoryController.clear();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search box
                      TextField(
                        controller: _searchCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'Tìm kiếm danh mục',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        onChanged: filterCategories,
                      ),
                      const SizedBox(height: 16),
                      // Danh sách danh mục
                      Expanded(
                        child: _isLoadingCategories
                          ? const Center(child: CircularProgressIndicator())
                          : filteredCategories.isEmpty
                            ? const Center(child: Text('Không tìm thấy danh mục phù hợp'))
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filteredCategories.length,
                                itemBuilder: (context, index) {
                                  final category = filteredCategories[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: category.color.withOpacity(0.1),
                                      child: Icon(
                                        category.icon,
                                        color: category.color,
                                      ),
                                    ),
                                    title: Text(category.name),
                                    subtitle: category.description != null 
                                      ? Text(
                                          category.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedCategoryId = category.id;
                                        _selectedCategoryName = category.name;
                                      });
                                      _searchCategoryController.clear();
                                      Navigator.pop(context);
                                      // Cập nhật state của màn hình chính
                                      this.setState(() {});
                                      // Kiểm tra nếu là đồ tặng
                                      _checkIfGiftCategory(_selectedCategoryId);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Hiển thị hộp thoại chọn địa điểm
  Future<void> _openLocationSelectDialog() async {
    final userService = Provider.of<UserService>(context, listen: false);
    final authUser = Provider.of<AuthService>(context, listen: false).user;
    
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để tiếp tục')),
      );
      return;
    }
    
    setState(() {
      _showLocationSelect = true;
    });
    
    // Lấy danh sách địa điểm đã lưu của người dùng
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(authUser.uid).get();
    final locations = userDoc.exists && userDoc.data()!.containsKey('locations') 
        ? List<Map<String, dynamic>>.from(userDoc.data()!['locations'])
        : [];
    
    if (!mounted) return;
    
    if (locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn chưa lưu địa điểm nào. Vui lòng thêm địa điểm trong trang cá nhân.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Hiển thị bottomsheet chọn địa điểm
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Chọn địa điểm',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Danh sách địa điểm
                      Expanded(
                        child: locations.isEmpty
                            ? const Center(
                                child: Text(
                                  'Bạn chưa thêm địa điểm nào.\nVui lòng thêm địa điểm tại trang cá nhân.',
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: locations.length,
                                itemBuilder: (context, index) {
                                  final location = locations[index];
                                  final address = [
                                    location['addressDetail'],
                                    location['ward'],
                                    location['district'],
                                    location['province'],
                                  ].where((e) => e != null && e.isNotEmpty).join(', ');
                                  
                                  return RadioListTile<String>(
                                    title: Text(
                                      address,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    value: location['id'],
                                    groupValue: _selectedLocationId,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedLocationId = value;
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                      
                      const SizedBox(height: 16),
                      // Nút chọn
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_selectedLocationId != null) {
                              final location = locations.firstWhere(
                                (loc) => loc['id'] == _selectedLocationId,
                              );
                              
                              final address = [
                                location['addressDetail'],
                                location['ward'],
                                location['district'],
                                location['province'],
                              ].where((e) => e != null && e.isNotEmpty).join(', ');
                              
                              this.setState(() {
                                _locationController.text = address;
                              });
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('Chọn địa điểm'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        );
      },
    );
  }
} 