import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/services/rag_service.dart';
import 'package:student_market_nttu/services/theme_service.dart';

class ProductRecommendationScreen extends StatefulWidget {
  const ProductRecommendationScreen({Key? key}) : super(key: key);

  @override
  State<ProductRecommendationScreen> createState() => _ProductRecommendationScreenState();
}

class _ProductRecommendationScreenState extends State<ProductRecommendationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _firstSearch = true;
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() => _firstSearch = false);
    
    // Access the RAG service and perform product retrieval
    final ragService = Provider.of<RAGService>(context, listen: false);
    await ragService.retrieveRelevantData(query);
    
    // Focus is removed after search
    _searchFocusNode.unfocus();
  }
  
  Widget _buildSearchResults() {
    return Consumer<RAGService>(
      builder: (context, ragService, child) {
        // If there's a search error
        if (ragService.searchError.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Lỗi tìm kiếm: ${ragService.searchError}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _performSearch(_searchController.text),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        
        // If searching
        if (ragService.isSearching) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tìm kiếm sản phẩm phù hợp...'),
              ],
            ),
          );
        }
        
        // If has results
        final docs = ragService.retrievedDocuments.where(
          (doc) => doc['type'] == 'product'
        ).toList();
        
        if (docs.isEmpty && !_firstSearch) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Không tìm thấy sản phẩm phù hợp\nHãy thử từ khóa khác',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _searchController.clear(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Xóa tìm kiếm'),
                ),
              ],
            ),
          );
        }
        
        // Display product results
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final productData = doc['data'] as Map<String, dynamic>;
            final similarityScore = doc['similarityScore'] as double;
            
            return _buildProductCard(productData, similarityScore);
          },
        );
      },
    );
  }
  
  Widget _buildProductCard(Map<String, dynamic> product, double similarityScore) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDarkMode = themeService.isDarkMode;
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image if available
          if (product['imageUrl'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                product['imageUrl'],
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported, size: 48),
                ),
              ),
            ),
            
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Relevance indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRelevanceColor(similarityScore),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.analytics,
                            size: 14,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Độ phù hợp: ${(similarityScore * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${product['price']} VNĐ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Product name
                Text(
                  product['name'] ?? 'Sản phẩm không tên',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Product description
                Text(
                  product['description'] ?? 'Không có mô tả',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // User info and action button
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Đăng bởi: ${product['postedBy'] ?? 'Ẩn danh'}',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Chi tiết'),
                      onPressed: () {
                        // Navigate to product detail
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Xem chi tiết: ${product['name']}'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getRelevanceColor(double score) {
    if (score >= 0.8) return Colors.green[100]!;
    if (score >= 0.6) return Colors.lightGreen[100]!;
    if (score >= 0.5) return Colors.amber[100]!;
    return Colors.orange[100]!;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gợi ý sản phẩm'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mô tả sản phẩm bạn muốn tìm:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Ví dụ: laptop mỏng nhẹ để học tập...',
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _searchController.clear,
                          ),
                        ),
                        onSubmitted: _performSearch,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _performSearch(_searchController.text),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Tìm'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gợi ý: Hãy mô tả chi tiết về sản phẩm cần tìm để có kết quả tốt nhất',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          
          // Results
          Expanded(
            child: _firstSearch
                ? _buildWelcomeContent()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag,
            size: 64,
            color: Colors.blue.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tìm kiếm sản phẩm thông minh',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Hãy mô tả sản phẩm bạn muốn tìm, hệ thống sẽ gợi ý các sản phẩm phù hợp nhất',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Bắt đầu tìm kiếm'),
            onPressed: () => _searchFocusNode.requestFocus(),
          ),
        ],
      ),
    );
  }
} 