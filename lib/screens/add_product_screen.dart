import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../models/product.dart';

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
  String _selectedCategory = 'Khác';
  String _condition = 'Mới';
  final List<String> _categories = [
    'Sách',
    'Đồ điện tử',
    'Quần áo',
    'Đồ dùng học tập',
    'Khác',
  ];
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _specsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          // For web
          _images.add(pickedFile); // Store XFile for web
          _imageWidgets.add(pickedFile); // For display
        } else {
          // For mobile
          _images.add(File(pickedFile.path));
          _imageWidgets.add(File(pickedFile.path));
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _imageWidgets.removeAt(index);
    });
  }

  void _addTag() {
    final text = _specsController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _tags.add(text);
        _specsController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
  }

  void _addSpecification() {
    showDialog(
      context: context,
      builder: (context) {
        final keyController = TextEditingController();
        final valueController = TextEditingController();
        return AlertDialog(
          title: const Text('Thêm thông số kỹ thuật'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'Tên thông số',
                  hintText: 'Ví dụ: CPU, RAM, Màu sắc...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: 'Giá trị',
                  hintText: 'Ví dụ: Intel i5, 8GB, Đỏ...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                final key = keyController.text.trim();
                final value = valueController.text.trim();
                if (key.isNotEmpty && value.isNotEmpty) {
                  setState(() {
                    _specifications[key] = value;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  void _removeSpecification(String key) {
    setState(() {
      _specifications.remove(key);
    });
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
        category: _selectedCategory,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
        ),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm sản phẩm'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image picker
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _imageWidgets.isEmpty
                    ? Center(
                        child: TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Thêm ảnh'),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imageWidgets.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _imageWidgets.length) {
                            return Center(
                              child: IconButton(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.add_photo_alternate),
                              ),
                            );
                          }
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: kIsWeb
                                    ? FutureBuilder<Uint8List>(
                                        future: (_imageWidgets[index] as XFile).readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                            return Image.memory(
                                              snapshot.data!,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            );
                                          }
                                          return const SizedBox(
                                            width: 100,
                                            height: 100,
                                            child: Center(child: CircularProgressIndicator()),
                                          );
                                        },
                                      )
                                    : Image.file(
                                        _imageWidgets[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeImage(index),
                                ),
                              ),
                            ],
                          );
                        },
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
              // Price and original price
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
              // Category and Condition
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(),
                        isDense: true, // Make the dropdown more compact
                      ),
                      isExpanded: true, // Prevent overflow
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis, // Handle text overflow
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _condition,
                      decoration: const InputDecoration(
                        labelText: 'Tình trạng',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      isExpanded: true,
                      items: _conditionOptions.map((condition) {
                        return DropdownMenuItem(
                          value: condition,
                          child: Text(
                            condition,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _condition = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Location and Quantity
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Địa điểm',
                        border: OutlineInputBorder(),
                        hintText: 'Ví dụ: TP.HCM, Hà Nội...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số lượng',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nhập số lượng';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 1) {
                          return 'Không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Tags
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _specsController,
                      decoration: const InputDecoration(
                        labelText: 'Thêm tag',
                        border: OutlineInputBorder(),
                        hintText: 'Ví dụ: secondhand, hot deal...',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addTag,
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _tags.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeTag(entry.key),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              // Specifications
              Row(
                children: [
                  const Text('Thông số kỹ thuật:'),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _addSpecification,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm thông số'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              if (_specifications.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: _specifications.entries.map((entry) {
                        return ListTile(
                          title: Text(entry.key),
                          subtitle: Text(entry.value),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeSpecification(entry.key),
                          ),
                          dense: true,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Đăng sản phẩm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 