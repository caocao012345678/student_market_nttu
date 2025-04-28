import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/models/knowledge_base.dart';
import 'package:student_market_nttu/services/auth_service.dart';
import '../data/mock_knowledge_data.dart';

class ChatbotHelpScreen extends StatefulWidget {
  static const routeName = '/chatbot-help';

  const ChatbotHelpScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotHelpScreen> createState() => _ChatbotHelpScreenState();
}

class _ChatbotHelpScreenState extends State<ChatbotHelpScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<KnowledgeDocument> _documents = [];
  String _selectedCategory = 'Tất cả';
  
  final List<String> _categories = [
    'Tất cả',
    'account',
    'product',
    'payment',
    'search',
    'support',
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _firestore.collection('knowledge_documents').get();
      
      final docs = snapshot.docs.map((doc) {
        return KnowledgeDocument.fromMap(doc.data(), doc.id);
      }).toList();
      
      // Sắp xếp theo thứ tự (nếu có) hoặc theo thời gian cập nhật
      docs.sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
      
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading documents: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải dữ liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Lọc tài liệu theo danh mục
  List<KnowledgeDocument> get _filteredDocuments {
    if (_selectedCategory == 'Tất cả') {
      return _documents;
    }
    return _documents.where((doc) => doc.category == _selectedCategory).toList();
  }

  // Mở form thêm/chỉnh sửa tài liệu
  void _openDocumentForm({KnowledgeDocument? document}) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Kiểm tra quyền (chỉ admin mới có thể thêm/sửa)
    if (authService.currentUser == null || !authService.isUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không có quyền thực hiện thao tác này.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (ctx) => DocumentFormDialog(
        document: document,
        onSave: _loadDocuments,
      ),
    );
  }

  // Xóa tài liệu
  Future<void> _deleteDocument(String docId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Kiểm tra quyền (chỉ admin mới có thể xóa)
    if (authService.currentUser == null || !authService.isUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không có quyền thực hiện thao tác này.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Hiển thị hộp thoại xác nhận
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa tài liệu này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!shouldDelete) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _firestore.collection('knowledge_documents').doc(docId).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa tài liệu thành công.'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadDocuments();
    } catch (e) {
      print('Error deleting document: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xóa tài liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Thêm phương thức xác nhận và thêm mock data
  void _confirmSeedData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm dữ liệu mẫu'),
        content: const Text('Thao tác này sẽ xóa tất cả tài liệu hiện có và thêm dữ liệu mẫu. Bạn có chắc chắn muốn tiếp tục?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              _seedMockData();
            },
            child: const Text('Xác nhận', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _seedMockData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await MockKnowledgeData.seedDatabase();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm dữ liệu mẫu thành công'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadDocuments();
    } catch (e) {
      print('Error seeding data: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thêm dữ liệu mẫu: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bool isAdmin = authService.isUserAdmin;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý cơ sở tri thức'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Thêm tài liệu mới',
              onPressed: () => _openDocumentForm(),
            ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.dataset),
              tooltip: 'Thêm dữ liệu mẫu',
              onPressed: _confirmSeedData,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadDocuments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Bộ lọc danh mục
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        }
                      },
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Danh sách tài liệu
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDocuments.isEmpty
                    ? const Center(child: Text('Không có tài liệu nào.'))
                    : ListView.builder(
                        itemCount: _filteredDocuments.length,
                        itemBuilder: (context, index) {
                          final document = _filteredDocuments[index];
                          return DocumentItem(
                            document: document,
                            isAdmin: isAdmin,
                            onEdit: () => _openDocumentForm(document: document),
                            onDelete: () => _deleteDocument(document.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// Widget hiển thị từng tài liệu
class DocumentItem extends StatefulWidget {
  final KnowledgeDocument document;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  const DocumentItem({
    Key? key,
    required this.document,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<DocumentItem> createState() => _DocumentItemState();
}

class _DocumentItemState extends State<DocumentItem> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              widget.document.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Danh mục: ${widget.document.category}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isAdmin) ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Chỉnh sửa',
                    onPressed: widget.onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Xóa',
                    onPressed: widget.onDelete,
                  ),
                ],
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Text(
                    'Nội dung:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.document.content),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: widget.document.keywords.map((keyword) {
                      return Chip(
                        label: Text(keyword),
                        backgroundColor: Colors.blue.withOpacity(0.2),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cập nhật lần cuối: ${widget.document.updatedAt.day}/${widget.document.updatedAt.month}/${widget.document.updatedAt.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Form dialog thêm/chỉnh sửa tài liệu
class DocumentFormDialog extends StatefulWidget {
  final KnowledgeDocument? document;
  final VoidCallback onSave;
  
  const DocumentFormDialog({
    Key? key,
    this.document,
    required this.onSave,
  }) : super(key: key);

  @override
  State<DocumentFormDialog> createState() => _DocumentFormDialogState();
}

class _DocumentFormDialogState extends State<DocumentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _keywordsController = TextEditingController();
  String _category = 'account';
  int _order = 0;
  bool _isLoading = false;
  
  final List<String> _categories = [
    'account',
    'product',
    'payment',
    'search',
    'support',
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Điền thông tin nếu là chỉnh sửa
    if (widget.document != null) {
      _titleController.text = widget.document!.title;
      _contentController.text = widget.document!.content;
      _keywordsController.text = widget.document!.keywords.join(', ');
      _category = widget.document!.category;
      _order = widget.document!.order;
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }
  
  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Parse keywords từ text input (cách nhau bởi dấu phẩy)
    final keywordsList = _keywordsController.text
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final firestore = FirebaseFirestore.instance;
      
      final data = {
        'title': _titleController.text,
        'content': _contentController.text,
        'keywords': keywordsList,
        'category': _category,
        'updatedAt': Timestamp.now(),
        'order': _order,
      };
      
      if (widget.document == null) {
        // Thêm mới
        data['createdAt'] = Timestamp.now();
        await firestore.collection('knowledge_documents').add(data);
      } else {
        // Cập nhật
        await firestore.collection('knowledge_documents').doc(widget.document!.id).update(data);
      }
      
      widget.onSave();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu tài liệu thành công.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving document: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu tài liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.document != null;
    
    return AlertDialog(
      title: Text(isEditing ? 'Chỉnh sửa tài liệu' : 'Thêm tài liệu mới'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập nội dung';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keywordsController,
                decoration: const InputDecoration(
                  labelText: 'Từ khóa (cách nhau bởi dấu phẩy)',
                  border: OutlineInputBorder(),
                  hintText: 'từ khóa 1, từ khóa 2, từ khóa 3',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _order.toString(),
                decoration: const InputDecoration(
                  labelText: 'Thứ tự hiển thị',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _order = int.tryParse(value) ?? 0;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        if (_isLoading)
          const CircularProgressIndicator()
        else
          ElevatedButton(
            onPressed: _saveDocument,
            child: Text(isEditing ? 'Cập nhật' : 'Thêm mới'),
          ),
      ],
    );
  }
} 