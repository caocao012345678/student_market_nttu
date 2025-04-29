import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/models/knowledge_base.dart';
import 'package:student_market_nttu/services/auth_service.dart';
import 'package:student_market_nttu/services/knowledge_base_service.dart';
import '../data/mock_knowledge_data.dart';

class ChatbotHelpScreen extends StatefulWidget {
  static const routeName = '/chatbot-help';

  const ChatbotHelpScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotHelpScreen> createState() => _ChatbotHelpScreenState();
}

class _ChatbotHelpScreenState extends State<ChatbotHelpScreen> {
  bool _isLoading = false;
  List<KnowledgeDocument> _filteredDocuments = [];
  String _selectedCategory = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _categories = [
    'Tất cả',
    'account',
    'product',
    'payment',
    'search',
    'support',
    'ai_features',
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sử dụng KnowledgeBaseService để tải dữ liệu
      await Provider.of<KnowledgeBaseService>(context, listen: false).loadDocuments();
      
      // Cập nhật danh sách lọc
      _updateFilteredDocuments();
      
    } catch (e) {
      print('Error loading documents: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải dữ liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Cập nhật danh sách đã lọc
  void _updateFilteredDocuments() {
    final knowledgeService = Provider.of<KnowledgeBaseService>(context, listen: false);
    final allDocuments = knowledgeService.documents;
    
    setState(() {
      if (_selectedCategory == 'Tất cả') {
        _filteredDocuments = allDocuments;
      } else {
        _filteredDocuments = allDocuments
            .where((doc) => doc.category == _selectedCategory)
            .toList();
      }
      
      // Tìm kiếm nếu có từ khóa
      if (_searchController.text.isNotEmpty) {
        final searchText = _searchController.text.toLowerCase();
        _filteredDocuments = _filteredDocuments.where((doc) {
          return doc.title.toLowerCase().contains(searchText) ||
                doc.content.toLowerCase().contains(searchText);
        }).toList();
      }
    });
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
        onSave: () {
          _loadDocuments();
        },
      ),
    );
  }

  // Xóa tài liệu
  Future<void> _deleteDocument(KnowledgeDocument document) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Kiểm tra quyền
    if (authService.currentUser == null || !authService.isUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không có quyền thực hiện thao tác này.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Xác nhận xóa
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa tài liệu "${document.title}"?'),
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
    
    if (shouldDelete) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Sử dụng KnowledgeBaseService để xóa tài liệu
        final success = await Provider.of<KnowledgeBaseService>(context, listen: false)
            .deleteDocument(document.id);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa tài liệu thành công.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Cập nhật danh sách
          _updateFilteredDocuments();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xóa tài liệu. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Xây dựng lại Pinecone index
  Future<void> _rebuildPineconeIndex() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Kiểm tra quyền
    if (authService.currentUser == null || !authService.isUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không có quyền thực hiện thao tác này.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Xác nhận
    final shouldRebuild = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xây dựng lại index'),
        content: const Text('Quá trình này sẽ xóa và tạo lại toàn bộ index Pinecone cho cơ sở tri thức. Tiếp tục?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ) ?? false;
    
    if (shouldRebuild) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Sử dụng KnowledgeBaseService để xây dựng lại index
        final success = await Provider.of<KnowledgeBaseService>(context, listen: false)
            .rebuildPineconeIndex();
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xây dựng lại index thành công.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xây dựng lại index. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Thêm dữ liệu mẫu (mock data) vào knowledge base
  Future<void> _importMockData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Kiểm tra quyền
    if (authService.currentUser == null || !authService.isUserAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không có quyền thực hiện thao tác này.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Xác nhận
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận import dữ liệu mẫu'),
        content: const Text('Hành động này sẽ thêm các tài liệu mẫu vào cơ sở tri thức và đồng bộ với Pinecone. Tiếp tục?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    ) ?? false;
    
    if (shouldImport) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final knowledgeService = Provider.of<KnowledgeBaseService>(context, listen: false);
        final firestore = FirebaseFirestore.instance;
        int successCount = 0;
        
        // Xử lý từng tài liệu mẫu
        for (final docData in MockKnowledgeData.knowledgeDocuments) {
          // Kiểm tra xem tài liệu đã tồn tại chưa (dựa vào tiêu đề)
          final existingDocs = await firestore
              .collection('knowledge_documents')
              .where('title', isEqualTo: docData['title'])
              .get();
          
          // Nếu tài liệu chưa tồn tại, thêm vào
          if (existingDocs.docs.isEmpty) {
            // Tạo tài liệu
            final doc = KnowledgeDocument(
              id: '',
              title: docData['title'],
              content: docData['content'],
              category: docData['category'],
              keywords: List<String>.from(docData['keywords'] ?? []),
              createdAt: (docData['createdAt'] as Timestamp).toDate(),
              updatedAt: (docData['updatedAt'] as Timestamp).toDate(),
              order: docData['order'] ?? 0,
            );
            
            // Lưu tài liệu
            final success = await knowledgeService.createDocument(doc);
            if (success) successCount++;
          }
        }
        
        // Thông báo kết quả
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm $successCount tài liệu mẫu vào cơ sở tri thức.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Tải lại danh sách
        await _loadDocuments();
        
        // Nếu Pinecone được khởi tạo, xây dựng lại index
        if (knowledgeService.isPineconeInitialized) {
          await knowledgeService.rebuildPineconeIndex();
        }
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi từ KnowledgeBaseService
    final knowledgeService = Provider.of<KnowledgeBaseService>(context);
    final authService = Provider.of<AuthService>(context);
    final bool isAdmin = authService.currentUser != null && authService.isUserAdmin;
    
    // Đảm bảo danh sách lọc được cập nhật khi documents thay đổi
    if (_filteredDocuments.isEmpty && !_isLoading) {
      _updateFilteredDocuments();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trung tâm trợ giúp'),
        actions: isAdmin ? [
          IconButton(
            icon: const Icon(Icons.dataset),
            onPressed: _isLoading ? null : _importMockData,
            tooltip: 'Import dữ liệu mẫu',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _rebuildPineconeIndex,
            tooltip: 'Xây dựng lại index',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isLoading ? null : () => _openDocumentForm(),
            tooltip: 'Thêm tài liệu mới',
          ),
        ] : null,
      ),
      body: _isLoading || knowledgeService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Tìm kiếm',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _updateFilteredDocuments,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => _updateFilteredDocuments(),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: _categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                              _updateFilteredDocuments();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: _filteredDocuments.isEmpty
                      ? const Center(
                          child: Text('Không tìm thấy tài liệu phù hợp.'),
                        )
                      : ListView.builder(
                          itemCount: _filteredDocuments.length,
                          itemBuilder: (ctx, index) {
                            final document = _filteredDocuments[index];
                            return Card(
                              margin: const EdgeInsets.all(8.0),
                              child: ExpansionTile(
                                title: Text(
                                  document.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('Danh mục: ${document.category}'),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(document.content),
                                        if (document.keywords.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 4,
                                            children: document.keywords.map((keyword) {
                                              return Chip(
                                                label: Text(keyword),
                                                backgroundColor: Colors.blue[50],
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                        if (isAdmin) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              TextButton.icon(
                                                icon: const Icon(Icons.edit),
                                                label: const Text('Sửa'),
                                                onPressed: () => _openDocumentForm(document: document),
                                              ),
                                              TextButton.icon(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                                onPressed: () => _deleteDocument(document),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// Dialog form để thêm/chỉnh sửa tài liệu
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
  final _orderController = TextEditingController();
  
  String _selectedCategory = 'general';
  bool _isLoading = false;
  
  final List<String> _categories = [
    'general',
    'account',
    'product',
    'payment',
    'search',
    'support',
    'ai_features',
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.document != null) {
      _titleController.text = widget.document!.title;
      _contentController.text = widget.document!.content;
      _keywordsController.text = widget.document!.keywords.join(', ');
      _selectedCategory = widget.document!.category;
      _orderController.text = widget.document!.order.toString();
    } else {
      _orderController.text = '0';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _keywordsController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final List<String> keywords = _keywordsController.text
          .split(',')
          .map((keyword) => keyword.trim())
          .where((keyword) => keyword.isNotEmpty)
          .toList();
      
      final order = int.tryParse(_orderController.text) ?? 0;
      
      final KnowledgeDocument updatedDocument = KnowledgeDocument(
        id: widget.document?.id ?? '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        keywords: keywords,
        category: _selectedCategory,
        createdAt: widget.document?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        order: order,
      );
      
      final knowledgeService = Provider.of<KnowledgeBaseService>(context, listen: false);
      
      bool success;
      if (widget.document == null) {
        // Tạo mới
        success = await knowledgeService.createDocument(updatedDocument);
      } else {
        // Cập nhật
        success = await knowledgeService.updateDocument(updatedDocument);
      }
      
      if (success) {
        Navigator.of(context).pop();
        widget.onSave();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lưu tài liệu. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.document == null ? 'Thêm tài liệu mới' : 'Chỉnh sửa tài liệu'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Danh mục *',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập nội dung';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keywordsController,
                decoration: const InputDecoration(
                  labelText: 'Từ khóa (ngăn cách bằng dấu phẩy)',
                  border: OutlineInputBorder(),
                  hintText: 'đăng ký, tài khoản, mật khẩu',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _orderController,
                decoration: const InputDecoration(
                  labelText: 'Thứ tự hiển thị',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveDocument,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
} 