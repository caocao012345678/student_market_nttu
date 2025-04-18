import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../models/product.dart';
import '../models/category.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _specsController = TextEditingController();
  final _searchCategoryController = TextEditingController();
  
  String _selectedCategoryId = '';
  String _selectedCategoryName = '';
  String _condition = 'Mới';
  bool _isLoadingCategories = true;
  List<Category> _filteredCategories = [];
  
  final List<String> _conditionOptions = [
    'Mới',
    'Như mới (99%)',
    'Tốt (90%)',
    'Đã qua sử dụng',
    'Cần sửa chữa',
  ];
  
  final List<dynamic> _images = [];
  final List<dynamic> _imageWidgets = [];
  final List<String> _tags = [];
  final Map<String, String> _specifications = {};
  bool _isLoading = false;
  bool _showCategorySearch = false;

  @override
  void initState() {
    super.initState();
    _initializeCategories();
  }

  Future<void> _initializeCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    final categoryService = Provider.of<CategoryService>(context, listen: false);
    
    // Always refresh categories from Firestore
    await categoryService.fetchCategories();
    
    setState(() {
      _filteredCategories = categoryService.activeCategories;
      _isLoadingCategories = false;
    });
  }

  void _searchCategory(String query) {
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    
    setState(() {
      _filteredCategories = categoryService.searchCategories(query);
    });
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (final pickedFile in pickedFiles) {
          if (kIsWeb) {
            // Web
            pickedFile.readAsBytes().then((data) {
              _images.add(data);
              _imageWidgets.add(
                Stack(
                  children: [
                    Image.memory(
                      data,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            final index = _imageWidgets.indexOf(
                              _imageWidgets.firstWhere(
                                (widget) => widget.key == ValueKey(pickedFile.name),
                              ),
                            );
                            _images.removeAt(index);
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
                  key: ValueKey(pickedFile.name),
                ),
              );
            });
          } else {
            // Mobile
            _images.add(File(pickedFile.path));
            _imageWidgets.add(
              Stack(
                children: [
                  Image.file(
                    File(pickedFile.path),
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          final index = _imageWidgets.indexOf(
                            _imageWidgets.firstWhere(
                              (widget) => widget.key == ValueKey(pickedFile.path),
                            ),
                          );
                          _images.removeAt(index);
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
                key: ValueKey(pickedFile.path),
              ),
            );
          }
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất một ảnh'),
        ),
      );
      return;
    }

    if (_selectedCategoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn danh mục cho sản phẩm'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthService>(context, listen: false).user;
      if (user == null) throw Exception('Vui lòng đăng nhập để thêm sản phẩm');

      final imageUrls = await Provider.of<ProductService>(context, listen: false)
          .uploadProductImages(_images);

      final product = Product(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')),
        originalPrice: _originalPriceController.text.isEmpty 
            ? 0.0 
            : double.parse(_originalPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')),
        category: _selectedCategoryId,
        images: imageUrls,
        sellerId: user.uid,
        sellerName: user.displayName ?? '',
        sellerAvatar: user.photoURL ?? '',
        createdAt: DateTime.now(),
        quantity: int.parse(_quantityController.text),
        condition: _condition,
        location: _locationController.text.trim(),
        tags: _tags,
        specifications: _specifications,
      );

      await Provider.of<ProductService>(context, listen: false)
          .createProduct(product);

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm sản phẩm thành công'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
        ),
      );
    }
  }

  // Hiển thị modal chọn danh mục
  void _showCategorySelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Thanh kéo
                          Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          
                          // Tiêu đề
                          const Text(
                            'Chọn danh mục',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          
                          // Thanh tìm kiếm
                          TextField(
                            controller: _searchCategoryController,
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm danh mục...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (value) {
                              _searchCategory(value);
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Danh sách danh mục
                    Expanded(
                      child: _isLoadingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredCategories.isEmpty
                          ? const Center(child: Text('Không tìm thấy danh mục phù hợp'))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _filteredCategories.length,
                              itemBuilder: (context, index) {
                                final category = _filteredCategories[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: category.color.withOpacity(0.1),
                                    child: Icon(
                                      category.icon,
                                      color: category.color,
                                    ),
                                  ),
                                  title: Text(category.name),
                                  subtitle: category.parentId.isNotEmpty
                                    ? FutureBuilder<Category?>(
                                        future: Provider.of<CategoryService>(context, listen: false)
                                            .getCategoryById(category.parentId),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const Text('Đang tải...');
                                          }
                                          if (snapshot.hasData && snapshot.data != null) {
                                            return Text('Thuộc ${snapshot.data!.name}');
                                          }
                                          return const SizedBox();
                                        },
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
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm sản phẩm'),
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
                            onTap: _pickImage,
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
                            decoration: const InputDecoration(
                              labelText: 'Giá',
                              border: OutlineInputBorder(),
                              prefixText: 'đ ',
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
                            decoration: const InputDecoration(
                              labelText: 'Giá gốc (nếu có)',
                              border: OutlineInputBorder(),
                              prefixText: 'đ ',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category
                    const Text(
                      'Danh mục',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showCategorySelectionModal,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedCategoryName.isEmpty 
                                ? 'Chọn danh mục'
                                : _selectedCategoryName,
                              style: TextStyle(
                                color: _selectedCategoryName.isEmpty ? Colors.grey : Colors.black,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
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
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Địa điểm',
                        border: OutlineInputBorder(),
                      ),
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
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[900],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Đăng sản phẩm'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 