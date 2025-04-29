import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import '../models/knowledge_base.dart';

class KnowledgeBaseService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  List<KnowledgeDocument> _documents = [];
  bool _isLoading = false;
  bool _isPineconeInitialized = false;
  
  // Pinecone config
  String _pineconeApiUrl = '';
  String _pineconeHost = '';
  String _pineconeIndexName = '';
  
  List<KnowledgeDocument> get documents => _documents;
  bool get isLoading => _isLoading;
  
  // API URL và key từ environment variable
  String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  String get _pineconeApiKey => dotenv.env['PINECONE_API_KEY'] ?? '';
  
  KnowledgeBaseService() {
    _initPinecone();
    loadDocuments();
  }
  
  // Khởi tạo Pinecone
  Future<void> _initPinecone() async {
    try {
      if (_pineconeApiKey.isEmpty) {
        print('PINECONE_API_KEY not found in environment variables');
        return;
      }
      
      _pineconeHost = dotenv.env['PINECONE_HOST'] ?? '';
      _pineconeIndexName = dotenv.env['PINECONE_INDEX_NAME'] ?? 'student-market-knowledge-data';
      
      if (_pineconeHost.isEmpty) {
        print('PINECONE_HOST not found in environment variables');
        return;
      }
      
      _pineconeApiUrl = 'https://$_pineconeHost';
      _isPineconeInitialized = true;
      print('KnowledgeBaseService: Pinecone initialized with API URL: $_pineconeApiUrl, Index: $_pineconeIndexName');
    } catch (e) {
      print('Error initializing Pinecone: $e');
    }
  }
  
  // Tải danh sách tài liệu từ Firestore
  Future<void> loadDocuments() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await _firestore.collection('knowledge_documents').get();
      
      _documents = snapshot.docs.map((doc) {
        return KnowledgeDocument.fromMap(doc.data(), doc.id);
      }).toList();
      
      // Sắp xếp theo thứ tự và thời gian cập nhật
      _documents.sort((a, b) {
        if (a.order != b.order) {
          return a.order.compareTo(b.order);
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
      
      // Đồng bộ với Pinecone nếu đã khởi tạo
      if (_isPineconeInitialized) {
        for (final doc in _documents) {
          _storeDocumentInPinecone(doc);
        }
      }
    } catch (e) {
      print('Error loading documents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Tìm kiếm tài liệu với query
  Future<List<KnowledgeDocument>> searchDocuments(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      // Nếu Pinecone đã được khởi tạo, sử dụng tìm kiếm ngữ nghĩa
      if (_isPineconeInitialized) {
        final documents = await _searchDocumentsInPinecone(query);
        if (documents.isNotEmpty) {
          return documents;
        }
      }
      
      // Fallback: Tìm kiếm local
      return _searchDocumentsLocally(query);
    } catch (e) {
      print('Error searching documents: $e');
      return _searchDocumentsLocally(query);
    }
  }
  
  // Tìm kiếm tài liệu trong Pinecone
  Future<List<KnowledgeDocument>> _searchDocumentsInPinecone(String query) async {
    if (!_isPineconeInitialized) return [];
    
    try {
      // Tạo embedding cho query
      final embedding = await _createEmbedding(query);
      if (embedding.isEmpty) return [];
      
      // Tìm kiếm vector trong Pinecone
      final url = '$_pineconeApiUrl/query';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': _pineconeApiKey,
        },
        body: jsonEncode({
          'vector': embedding,
          'topK': 5,
          'includeMetadata': true,
          'includeValues': false,
          'filter': {
            'metadata': {
              'type': 'document'
            }
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final matches = List<Map<String, dynamic>>.from(data['matches'] ?? []);
        
        // Chuyển đổi kết quả thành KnowledgeDocument
        return matches.map((match) {
          final metadata = match['metadata'];
          return KnowledgeDocument(
            id: metadata['id'] ?? '',
            title: metadata['title'] ?? '',
            content: metadata['content'] ?? '',
            category: metadata['category'] ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            keywords: [],
          );
        }).toList();
      } else {
        print('Error querying Pinecone: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error searching documents in Pinecone: $e');
      return [];
    }
  }
  
  // Tìm kiếm cục bộ trong danh sách tài liệu đã tải
  List<KnowledgeDocument> _searchDocumentsLocally(String query) {
    final lowerQuery = query.toLowerCase();
    
    return _documents.where((doc) {
      final searchText = '${doc.title.toLowerCase()} ${doc.content.toLowerCase()} ${doc.category.toLowerCase()}';
      final keywordsMatch = doc.keywords.any((keyword) => 
          keyword.toLowerCase().contains(lowerQuery) || 
          lowerQuery.contains(keyword.toLowerCase()));
      return searchText.contains(lowerQuery) || keywordsMatch;
    }).toList();
  }
  
  // Tạo tài liệu mới
  Future<bool> createDocument(KnowledgeDocument document) async {
    try {
      final docRef = await _firestore.collection('knowledge_documents').add(document.toMap());
      
      // Thêm ID vào document và lưu vào danh sách local
      final newDoc = KnowledgeDocument(
        id: docRef.id,
        title: document.title,
        content: document.content,
        category: document.category,
        keywords: document.keywords,
        createdAt: document.createdAt,
        updatedAt: document.updatedAt,
        order: document.order,
      );
      
      _documents.add(newDoc);
      notifyListeners();
      
      // Đồng bộ với Pinecone
      if (_isPineconeInitialized) {
        await _storeDocumentInPinecone(newDoc);
      }
      
      return true;
    } catch (e) {
      print('Error creating document: $e');
      return false;
    }
  }
  
  // Cập nhật tài liệu
  Future<bool> updateDocument(KnowledgeDocument document) async {
    try {
      await _firestore.collection('knowledge_documents')
          .doc(document.id)
          .update(document.toMap());
      
      // Cập nhật trong danh sách local
      final index = _documents.indexWhere((doc) => doc.id == document.id);
      if (index != -1) {
        _documents[index] = document;
        notifyListeners();
      }
      
      // Đồng bộ với Pinecone
      if (_isPineconeInitialized) {
        await _storeDocumentInPinecone(document);
      }
      
      return true;
    } catch (e) {
      print('Error updating document: $e');
      return false;
    }
  }
  
  // Xóa tài liệu
  Future<bool> deleteDocument(String documentId) async {
    try {
      await _firestore.collection('knowledge_documents').doc(documentId).delete();
      
      // Xóa khỏi danh sách local
      _documents.removeWhere((doc) => doc.id == documentId);
      notifyListeners();
      
      // Xóa khỏi Pinecone
      if (_isPineconeInitialized) {
        await _deleteDocumentFromPinecone(documentId);
      }
      
      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }
  
  // Xây dựng lại index Pinecone (dành cho admin)
  Future<bool> rebuildPineconeIndex() async {
    if (!_isPineconeInitialized) return false;
    
    try {
      // Xóa toàn bộ vectors có type=document
      final url = '$_pineconeApiUrl/vectors/delete';
      
      await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': _pineconeApiKey,
        },
        body: jsonEncode({
          'filter': {
            'metadata': {
              'type': 'document'
            }
          }
        }),
      );
      
      // Đồng bộ lại tất cả tài liệu
      for (final doc in _documents) {
        await _storeDocumentInPinecone(doc);
      }
      
      return true;
    } catch (e) {
      print('Error rebuilding Pinecone index: $e');
      return false;
    }
  }
  
  // Lưu tài liệu vào Pinecone
  Future<bool> _storeDocumentInPinecone(KnowledgeDocument document) async {
    if (!_isPineconeInitialized) return false;
    
    try {
      // Tạo embedding cho tài liệu
      final documentText = '${document.title}. ${document.content}. Danh mục: ${document.category}';
      final embedding = await _createEmbedding(documentText);
      
      if (embedding.isEmpty) return false;
      
      // Lưu vào Pinecone
      final url = '$_pineconeApiUrl/vectors/upsert';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': _pineconeApiKey,
        },
        body: jsonEncode({
          'vectors': [
            {
              'id': 'doc_${document.id}',
              'values': embedding,
              'metadata': {
                'type': 'document',
                'id': document.id,
                'title': document.title,
                'category': document.category,
                'content': document.content,
              },
            },
          ],
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error storing document in Pinecone: $e');
      return false;
    }
  }
  
  // Xóa tài liệu khỏi Pinecone
  Future<bool> _deleteDocumentFromPinecone(String documentId) async {
    if (!_isPineconeInitialized) return false;
    
    try {
      final url = '$_pineconeApiUrl/vectors/delete';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': _pineconeApiKey,
        },
        body: jsonEncode({
          'ids': ['doc_$documentId']
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting document from Pinecone: $e');
      return false;
    }
  }
  
  // Tạo embedding vector từ text
  Future<List<double>> _createEmbedding(String text) async {
    try {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/embedding-001:embedContent?key=$_geminiApiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'embedding-001',
          'content': {
            'parts': [
              {
                'text': text
              }
            ]
          },
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embedding = data['embedding']['values'] as List;
        return embedding.map((value) => value as double).toList();
      } else {
        print('Error creating embedding: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception creating embedding: $e');
      return [];
    }
  }
} 