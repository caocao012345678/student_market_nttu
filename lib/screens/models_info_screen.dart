import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/services/gemini_service.dart';

class GeminiModelsInfoScreen extends StatefulWidget {
  const GeminiModelsInfoScreen({Key? key}) : super(key: key);

  @override
  State<GeminiModelsInfoScreen> createState() => _GeminiModelsInfoScreenState();
}

class _GeminiModelsInfoScreenState extends State<GeminiModelsInfoScreen> {
  bool _isLoading = false;
  List<String> _models = [];
  String? _selectedModel;
  Map<String, dynamic>? _modelDetails;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      
      // Nếu đã có danh sách models
      if (geminiService.availableModels.isNotEmpty) {
        setState(() {
          _models = geminiService.availableModels;
          _isLoading = false;
        });
        return;
      }
      
      // Lấy API key từ dotenv
      final apiKey = geminiService.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _error = 'API key không hợp lệ';
          _isLoading = false;
        });
        return;
      }
      
      // Gọi API để lấy danh sách models
      final models = await geminiService.fetchAvailableModels(apiKey);
      setState(() {
        _models = models;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải danh sách models: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadModelDetails(String modelName) async {
    setState(() {
      _isLoading = true;
      _modelDetails = null;
      _error = null;
      _selectedModel = modelName;
    });

    try {
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final apiKey = geminiService.getApiKey();
      
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _error = 'API key không hợp lệ';
          _isLoading = false;
        });
        return;
      }
      
      final details = await geminiService.getModelDetails(modelName, apiKey);
      setState(() {
        _modelDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi tải chi tiết model: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Models'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadModels,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadModels,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : _models.isEmpty
                  ? const Center(child: Text('Không có models nào được tìm thấy'))
                  : Row(
                      children: [
                        // Danh sách models bên trái
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: Colors.grey[100],
                            child: ListView.separated(
                              itemCount: _models.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final model = _models[index];
                                final isSelected = model == _selectedModel;
                                
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                  title: Text(
                                    model,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  tileColor: isSelected ? Colors.blue[50] : null,
                                  onTap: () => _loadModelDetails(model),
                                  selected: isSelected,
                                  dense: true,
                                  trailing: isSelected ? const Icon(Icons.arrow_forward_ios, size: 14) : null,
                                );
                              },
                            ),
                          ),
                        ),
                        
                        // Chi tiết model bên phải
                        Expanded(
                          flex: 2,
                          child: _selectedModel == null
                              ? const Center(
                                  child: Text('Chọn một model để xem chi tiết'),
                                )
                              : _modelDetails == null
                                  ? const Center(child: CircularProgressIndicator())
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedModel!,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          
                                          // Hiển thị các thông tin chi tiết
                                          _buildDetailSection('Tên đầy đủ', _modelDetails!['name']),
                                          _buildDetailSection('Phiên bản', _modelDetails!['version']),
                                          _buildDetailSection('Mô tả', _modelDetails!['description']),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // Hiển thị các tính năng được hỗ trợ
                                          if (_modelDetails!.containsKey('supportedGenerationMethods'))
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Phương thức được hỗ trợ:',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[50],
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.grey.shade200),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: _modelDetails!['supportedGenerationMethods']
                                                        .map<Widget>((method) => Padding(
                                                              padding: const EdgeInsets.only(bottom: 4),
                                                              child: Row(
                                                                children: [
                                                                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                                                  const SizedBox(width: 8),
                                                                  Expanded(
                                                                    child: Text(
                                                                      method,
                                                                      style: const TextStyle(fontSize: 13),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ))
                                                        .toList(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // Hiển thị các tham số khác trong một card
                                          Card(
                                            margin: const EdgeInsets.only(top: 8),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Giới hạn và thông số:',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  if (_modelDetails!.containsKey('inputTokenLimit'))
                                                    _buildInfoRow('Token đầu vào', _modelDetails!['inputTokenLimit'].toString()),
                                                  
                                                  if (_modelDetails!.containsKey('outputTokenLimit'))
                                                    _buildInfoRow('Token đầu ra', _modelDetails!['outputTokenLimit'].toString()),
                                                ],
                                              ),
                                            ),
                                          ),
                                          
                                          // Hiển thị toàn bộ JSON
                                          const SizedBox(height: 16),
                                          ExpansionTile(
                                            title: const Text('Xem JSON đầy đủ'),
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  _modelDetails.toString(),
                                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
} 