import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../services/user_service.dart';
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
  
  // Biến kiểm tra đây có phải là đồ tặng không
  bool _isGiftItem = false;
  
  // Thêm biến lưu địa điểm đã chọn
  String? _selectedLocationId;
  
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
  bool _showLocationSelect = false;

  @override
  void initState() {
    super.initState();
    // Sử dụng addPostFrameCallback để đảm bảo context hoàn thiện
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCategories();
    });
  }

  Future<void> _initializeCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categoryService = Provider.of<CategoryService>(context, listen: false);
      
      // Kiểm tra xem CategoryService đã được khởi tạo chưa
      if (!categoryService.isInitialized) {
        await categoryService.initialize();
      } else if (categoryService.categories.isEmpty) {
        // Nếu đã khởi tạo nhưng danh sách trống, thử tải lại
        await categoryService.fetchCategories();
      }
      
      setState(() {
        _filteredCategories = categoryService.activeCategories;
        _isLoadingCategories = false;
      });
      
    } catch (e) {
      print('Lỗi khi tải danh mục: $e');
      setState(() {
        _isLoadingCategories = false;
      });
      
      // Hiển thị thông báo lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải danh mục: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  // Mở giao diện chọn địa điểm từ danh sách đã lưu
  void _openLocationSelectDialog() {
    setState(() {
      _showLocationSelect = true;
    });
    
    final userService = Provider.of<UserService>(context, listen: false);
    final locations = userService.getUserLocations();
    
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
              initialChildSize: 0.6,
              maxChildSize: 0.8,
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

  // Kiểm tra xem danh mục đã chọn có phải là "Đồ tặng" không
  void _checkIfGiftCategory(String categoryId) {
    if (categoryId.isEmpty) {
      setState(() {
        _isGiftItem = false;
      });
      return;
    }
    
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    final category = categoryService.activeCategories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => Category(
        id: '',
        name: '',
        iconName: '',
        icon: Icons.category,
        color: Colors.blue,
        createdAt: DateTime.now(),
      ),
    );
    
    setState(() {
      _isGiftItem = category.name == 'Đồ tặng';
      
      // Nếu là đồ tặng, đặt giá = 0
      if (_isGiftItem) {
        _priceController.text = '0';
        _originalPriceController.text = '0';
      }
    });
  }

  // Cập nhật phương thức hiển thị danh mục
  void _showCategoryDialog() {
    // Load lại danh mục nếu danh sách trống
    if (_filteredCategories.isEmpty && !_isLoadingCategories) {
      _initializeCategories();
    }
    
    setState(() {
      _showCategorySearch = true;
    });
    
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
              final categoryService = Provider.of<CategoryService>(context, listen: false);
              setState(() {
                _filteredCategories = categoryService.searchCategories(value);
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
                          hintText: 'Tìm kiếm danh mục',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          filterCategories(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Refresh button
                      if (_isLoadingCategories)
                        const Center(child: CircularProgressIndicator())
                      else if (_filteredCategories.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Không tìm thấy danh mục phù hợp'),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isLoadingCategories = true;
                                  });
                                  
                                  // Tải lại danh mục
                                  final categoryService = Provider.of<CategoryService>(context, listen: false);
                                  categoryService.fetchCategories().then((_) {
                                    setState(() {
                                      _filteredCategories = categoryService.activeCategories;
                                      _isLoadingCategories = false;
                                    });
                                  }).catchError((e) {
                                    setState(() {
                                      _isLoadingCategories = false;
                                    });
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tải lại'),
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
                                    subtitle: category.description != null 
                                      ? Text(
                                          category.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : category.parentId.isNotEmpty
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
                                      // Kiểm tra nếu là đồ tặng
                                      _checkIfGiftCategory(category.id);
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
                            enabled: !_isGiftItem, // Vô hiệu hóa nếu là đồ tặng
                            decoration: InputDecoration(
                              labelText: 'Giá',
                              border: const OutlineInputBorder(),
                              prefixText: 'đ ',
                              helperText: _isGiftItem ? 'Đồ tặng miễn phí' : null,
                              filled: _isGiftItem,
                              fillColor: _isGiftItem ? Colors.grey[200] : null,
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
                            enabled: !_isGiftItem, // Vô hiệu hóa nếu là đồ tặng
                            decoration: InputDecoration(
                              labelText: 'Giá gốc (nếu có)',
                              border: const OutlineInputBorder(),
                              prefixText: 'đ ',
                              filled: _isGiftItem,
                              fillColor: _isGiftItem ? Colors.grey[200] : null,
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

                    // Location (Now uses saved locations)
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
                        onPressed: _images.isEmpty || _isLoading
                            ? null
                            : _submitProduct,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Đăng sản phẩm'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final List<String> imageUrls = [];
    
    try {
      if (_images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ít nhất một hình ảnh')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Upload hình ảnh
      for (int i = 0; i < _images.length; i++) {
        List<String> urls = await Provider.of<ProductService>(context, listen: false)
            .uploadProductImages([_images[i] as File]);
        imageUrls.addAll(urls);
      }
      
      // Hiển thị thông báo kiểm duyệt
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang gửi sản phẩm để kiểm duyệt...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Tạo Map specifications
      final Map<String, String> specifications = {};
      for (var entry in _specifications.entries) {
        specifications[entry.key] = entry.value;
      }
      
      // Thêm sản phẩm với kiểm duyệt
      final productId = await Provider.of<ProductService>(context, listen: false)
          .addProductWithModeration(
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        category: _selectedCategoryId,
        images: imageUrls,
        condition: _condition,
        location: _locationController.text,
        tags: _tags,
        specifications: specifications,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      // Hiển thị thông báo thành công và rời khỏi màn hình
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sản phẩm đã được thêm và đang chờ kiểm duyệt')          
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }
} 