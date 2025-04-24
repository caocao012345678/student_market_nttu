const functions = require('firebase-functions');
const admin = require('firebase-admin');
const vision = require('@google-cloud/vision');
const axios = require('axios');

// Khởi tạo Vision API client
const visionClient = new vision.ImageAnnotatorClient();

// Trạng thái kiểm duyệt
const ModerationStatus = {
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected',
  IN_REVIEW: 'in_review'
};

// Trạng thái sản phẩm
const ProductStatus = {
  AVAILABLE: 'available',
  PENDING_REVIEW: 'pending_review',
  REJECTED: 'rejected'
};

// Danh sách từ khóa bị cấm
const BANNED_KEYWORDS = [
  'vũ khí', 'súng', 'dao', 'ma túy', 'cần sa', 'cocaine', 'heroin',
  'khỏa thân', 'khiêu dâm', 'cờ bạc', 'viagra', 'thuốc lá điện tử',
];

// Danh sách danh mục bị cấm
const BANNED_CATEGORIES = [
  'vũ khí', 'chất kích thích', 'thuốc lá', 'đồ 18+', 'cờ bạc'
];

// Gemini API Key từ environment
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

// Cloud Function xử lý khi có sản phẩm mới được thêm vào hàng đợi kiểm duyệt
exports.moderateNewProduct = functions.firestore
  .document('moderation_queue/{productId}')
  .onCreate(async (snapshot, context) => {
    const productId = context.params.productId;
    const queueData = snapshot.data();
    
    console.log(`Bắt đầu kiểm duyệt sản phẩm: ${productId}`);
    
    try {
      // Lấy thông tin sản phẩm từ collection products
      const productDoc = await admin.firestore().collection('products').doc(productId).get();
      
      if (!productDoc.exists) {
        console.error(`Không tìm thấy sản phẩm: ${productId}`);
        return null;
      }
      
      const productData = productDoc.data();
      
      // Tạo ID mới cho kết quả kiểm duyệt
      const moderationId = admin.firestore().collection('moderation_results').doc().id;
      
      // Phân tích nội dung văn bản
      const contentAnalysisResult = await analyzeTextContent({
        title: productData.title || '',
        description: productData.description || '',
        category: productData.category || '',
        tags: productData.tags || [],
        price: productData.price || 0,
      });
      
      // Phân tích hình ảnh
      const imageAnalysisResult = await analyzeImages(productData.images || []);
      
      // Tính điểm
      const contentScore = contentAnalysisResult.score;
      const imageScore = imageAnalysisResult.score;
      const complianceScore = calculateComplianceScore(contentAnalysisResult, imageAnalysisResult, productData.category);
      
      // Tính tổng điểm (trọng số: nội dung 40%, hình ảnh 40%, tuân thủ 20%)
      const totalScore = Math.round((contentScore * 0.4) + (imageScore * 0.4) + (complianceScore * 0.2));
      
      // Tổng hợp các vấn đề
      const issues = [];
      
      // Thêm vấn đề từ phân tích nội dung
      if (contentAnalysisResult.issues && contentAnalysisResult.issues.length > 0) {
        for (const issue of contentAnalysisResult.issues) {
          issues.push({
            type: 'content',
            severity: issue.severity || 'low',
            description: issue.description || '',
            field: issue.field,
          });
        }
      }
      
      // Thêm vấn đề từ phân tích hình ảnh
      if (imageAnalysisResult.issues && imageAnalysisResult.issues.length > 0) {
        for (const issue of imageAnalysisResult.issues) {
          issues.push({
            type: 'image',
            severity: issue.severity || 'low',
            description: issue.description || '',
            imageIndex: issue.imageIndex,
          });
        }
      }
      
      // Xác định trạng thái kiểm duyệt dựa trên điểm số
      let moderationStatus;
      let rejectionReason = null;
      let productStatus;
      
      if (totalScore >= 85) {
        moderationStatus = ModerationStatus.APPROVED;
        productStatus = ProductStatus.AVAILABLE;
      } else if (totalScore < 60) {
        moderationStatus = ModerationStatus.REJECTED;
        productStatus = ProductStatus.REJECTED;
        rejectionReason = generateRejectionReason(issues);
      } else {
        moderationStatus = ModerationStatus.IN_REVIEW;
        productStatus = ProductStatus.PENDING_REVIEW;
      }
      
      // Tạo kết quả kiểm duyệt
      const moderationResult = {
        productId: productId,
        status: moderationStatus,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        imageScore: imageScore,
        contentScore: contentScore,
        complianceScore: complianceScore,
        totalScore: totalScore,
        issues: issues.length > 0 ? issues : null,
        suggestedTags: contentAnalysisResult.suggestedTags || null,
        rejectionReason: rejectionReason,
        imageAnalysis: imageAnalysisResult,
        contentAnalysis: contentAnalysisResult,
      };
      
      // Lưu kết quả kiểm duyệt
      await admin.firestore().collection('moderation_results').doc(moderationId).set(moderationResult);
      
      // Cập nhật trạng thái sản phẩm
      await admin.firestore().collection('products').doc(productId).update({
        status: productStatus,
        moderationInfo: {
          moderationId: moderationId,
          moderationScore: totalScore,
          moderationTimestamp: admin.firestore.FieldValue.serverTimestamp(),
          rejectionReason: rejectionReason,
        },
      });
      
      // Xóa khỏi hàng đợi
      await snapshot.ref.delete();
      
      console.log(`Kiểm duyệt hoàn tất cho sản phẩm ${productId}: ${moderationStatus} (${totalScore} điểm)`);
      
      return { success: true, moderationId: moderationId };
    } catch (error) {
      console.error(`Lỗi khi kiểm duyệt sản phẩm ${productId}:`, error);
      
      // Trong trường hợp lỗi, chuyển sản phẩm sang kiểm duyệt thủ công
      try {
        await admin.firestore().collection('products').doc(productId).update({
          status: ProductStatus.PENDING_REVIEW,
          moderationInfo: {
            error: error.message,
            errorTimestamp: admin.firestore.FieldValue.serverTimestamp(),
          },
        });
        
        // Giữ lại trong hàng đợi nhưng đánh dấu lỗi
        await snapshot.ref.update({
          status: 'error',
          error: error.message,
          errorTimestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (updateError) {
        console.error('Lỗi khi cập nhật trạng thái lỗi:', updateError);
      }
      
      return { success: false, error: error.message };
    }
  });

// Phân tích nội dung văn bản
async function analyzeTextContent({ title, description, category, tags, price }) {
  try {
    const issues = [];
    const combinedText = `${title} ${description} ${tags.join(' ')}`.toLowerCase();
    
    // Kiểm tra từ khóa không phù hợp
    for (const keyword of BANNED_KEYWORDS) {
      if (combinedText.includes(keyword.toLowerCase())) {
        issues.push({
          severity: 'high',
          description: `Nội dung chứa từ khóa bị cấm: ${keyword}`,
          field: determineIssueField(keyword, title, description, tags),
        });
      }
    }
    
    // Kiểm tra danh mục bị cấm
    if (BANNED_CATEGORIES.includes(category.toLowerCase())) {
      issues.push({
        severity: 'high',
        description: `Danh mục sản phẩm không được phép: ${category}`,
        field: 'category',
      });
    }
    
    // Kiểm tra giá trị giá cả
    if (price <= 0) {
      issues.push({
        severity: 'medium',
        description: `Giá không hợp lệ: ${price}`,
        field: 'price',
      });
    } else if (price > 100000000) { // Giá quá cao (100 triệu)
      issues.push({
        severity: 'medium',
        description: `Giá có vẻ quá cao: ${price}`,
        field: 'price',
      });
    }
    
    // Kiểm tra độ dài tiêu đề và mô tả
    if (title.length < 5) {
      issues.push({
        severity: 'low',
        description: 'Tiêu đề quá ngắn',
        field: 'title',
      });
    }
    
    if (description.length < 20) {
      issues.push({
        severity: 'low',
        description: 'Mô tả quá ngắn',
        field: 'description',
      });
    }
    
    // Sử dụng Gemini hoặc phân tích ngữ nghĩa nâng cao
    let geminiAnalysis = {};
    try {
      geminiAnalysis = await geminiTextAnalysis({ title, description, category, tags });
    } catch (error) {
      console.error('Lỗi khi phân tích văn bản với Gemini:', error);
      // Fallback: Tự tính điểm nếu Gemini không khả dụng
      geminiAnalysis = { relevanceScore: 70 };
    }
    
    // Đánh giá mức độ liên quan giữa tiêu đề, mô tả và danh mục
    const relevanceScore = geminiAnalysis.relevanceScore || 70;
    
    // Gợi ý tags nếu cần
    const suggestedTags = [];
    if (tags.length === 0 || tags.length < 3) {
      if (geminiAnalysis.suggestedTags && geminiAnalysis.suggestedTags.length > 0) {
        suggestedTags.push(...geminiAnalysis.suggestedTags);
      }
    }
    
    // Bổ sung issues từ kết quả phân tích Gemini
    if (geminiAnalysis.issues && geminiAnalysis.issues.length > 0) {
      issues.push(...geminiAnalysis.issues);
    }
    
    // Tính điểm nội dung dựa trên nhiều yếu tố
    const contentScore = calculateContentScore({
      relevanceScore,
      titleLength: title.length,
      descriptionLength: description.length,
      tagsCount: tags.length,
      specificationsCount: 0, // Không có thông tin specifications ở đây
      issues,
    });
    
    return {
      score: contentScore,
      issues,
      suggestedTags,
      relevanceScore,
      geminiAnalysis,
    };
  } catch (error) {
    console.error('Lỗi phân tích nội dung:', error);
    return {
      score: 60, // Điểm mặc định khi có lỗi
      issues: [{
        severity: 'medium',
        description: `Lỗi khi phân tích nội dung: ${error.message}`,
        field: 'content',
      }],
    };
  }
}

// Phân tích hình ảnh
async function analyzeImages(imageUrls) {
  try {
    if (!imageUrls || imageUrls.length === 0) {
      return {
        score: 0,
        issues: [{
          severity: 'high',
          description: 'Không có hình ảnh nào được cung cấp',
        }],
      };
    }
    
    const imageIssues = [];
    const imageResults = [];
    
    // Kiểm tra số lượng hình ảnh
    if (imageUrls.length < 2) {
      imageIssues.push({
        severity: 'low',
        description: 'Khuyến nghị cung cấp nhiều hình ảnh hơn để tăng độ tin cậy',
      });
    }
    
    // Phân tích từng hình ảnh
    for (let i = 0; i < imageUrls.length; i++) {
      const url = imageUrls[i];
      
      // Phân tích hình ảnh với Vision API
      const imageAnalysis = await analyzeImageWithVision(url, i);
      imageResults.push(imageAnalysis);
      
      // Kiểm tra vấn đề với hình ảnh
      if (imageAnalysis.issues && imageAnalysis.issues.length > 0) {
        for (const issue of imageAnalysis.issues) {
          issue.imageIndex = i;
          imageIssues.push(issue);
        }
      }
    }
    
    // Tính điểm trung bình cho hình ảnh
    let totalScore = 0;
    for (const result of imageResults) {
      totalScore += (result.score || 0);
    }
    const averageScore = imageResults.length > 0 ? Math.round(totalScore / imageResults.length) : 0;
    
    return {
      score: averageScore,
      issues: imageIssues,
      results: imageResults,
    };
  } catch (error) {
    console.error('Lỗi phân tích hình ảnh:', error);
    return {
      score: 60, // Điểm mặc định khi có lỗi
      issues: [{
        severity: 'medium',
        description: `Lỗi khi phân tích hình ảnh: ${error.message}`,
      }],
    };
  }
}

// Phân tích hình ảnh với Vision API
async function analyzeImageWithVision(imageUrl, index) {
  try {
    // Chuẩn bị request cho Vision API
    const [result] = await visionClient.annotateImage({
      image: { source: { imageUri: imageUrl } },
      features: [
        { type: 'LABEL_DETECTION', maxResults: 10 },
        { type: 'SAFE_SEARCH_DETECTION' },
        { type: 'IMAGE_PROPERTIES' },
        { type: 'OBJECT_LOCALIZATION', maxResults: 5 },
      ],
    });
    
    // Phân tích kết quả
    const issues = [];
    let safetyScore = 100;
    const objects = [];
    
    // Phân tích SafeSearch
    if (result.safeSearchAnnotation) {
      const safeSearch = result.safeSearchAnnotation;
      
      // Kiểm tra các nhãn an toàn
      const adultRating = safeSearch.adult;
      const violenceRating = safeSearch.violence;
      const racyRating = safeSearch.racy;
      
      const highLikelihood = ['LIKELY', 'VERY_LIKELY'];
      
      if (highLikelihood.includes(adultRating)) {
        issues.push({
          severity: 'high',
          description: 'Hình ảnh có thể chứa nội dung người lớn',
        });
        safetyScore -= 50;
      }
      
      if (highLikelihood.includes(violenceRating)) {
        issues.push({
          severity: 'high',
          description: 'Hình ảnh có thể chứa nội dung bạo lực',
        });
        safetyScore -= 40;
      }
      
      if (highLikelihood.includes(racyRating)) {
        issues.push({
          severity: 'medium',
          description: 'Hình ảnh có thể chứa nội dung nhạy cảm',
        });
        safetyScore -= 30;
      }
    }
    
    // Kiểm tra nhãn
    if (result.labelAnnotations) {
      for (const label of result.labelAnnotations) {
        const description = label.description || '';
        objects.push(description);
        
        // Kiểm tra xem có nhãn liên quan đến vật phẩm bị cấm không
        for (const keyword of BANNED_KEYWORDS) {
          if (description.toLowerCase().includes(keyword.toLowerCase())) {
            issues.push({
              severity: 'high',
              description: `Hình ảnh có thể chứa vật phẩm bị cấm: ${description}`,
            });
            safetyScore -= 50;
            break;
          }
        }
      }
    }
    
    // Đánh giá chất lượng hình ảnh
    let quality = 'medium';
    if (result.imagePropertiesAnnotation) {
      // Đánh giá độ sáng và tương phản (thêm logic chi tiết hơn nếu cần)
      quality = 'high';
    }
    
    // Giới hạn điểm trong khoảng 0-100
    safetyScore = Math.max(0, Math.min(100, safetyScore));
    
    return {
      objects,
      score: safetyScore,
      quality,
      issues,
      raw_response: result,
    };
  } catch (error) {
    console.error(`Lỗi khi phân tích hình ảnh ${index}:`, error);
    return {
      score: 60,
      issues: [{
        severity: 'medium',
        description: 'Không thể phân tích hình ảnh này',
        imageIndex: index,
      }],
    };
  }
}

// Phân tích văn bản với Gemini
async function geminiTextAnalysis({ title, description, category, tags }) {
  try {
    if (!GEMINI_API_KEY) {
      throw new Error('Không có Gemini API Key');
    }
    
    // Tạo prompt cho Gemini
    const prompt = `
    Phân tích nội dung sản phẩm sau và đánh giá tính phù hợp:
    
    Tiêu đề: ${title}
    Mô tả: ${description}
    Danh mục: ${category}
    Tags: ${tags.join(', ')}
    
    Phân tích các khía cạnh sau:
    1. Mức độ phù hợp giữa tiêu đề, mô tả và danh mục (thang điểm 0-100)
    2. Phát hiện nội dung không phù hợp, vi phạm hoặc lừa đảo
    3. Đề xuất 3-5 tags liên quan nếu người dùng chưa cung cấp đủ
    
    Trả về kết quả dưới dạng JSON với cấu trúc:
    {
      "relevanceScore": 85,
      "suggestedTags": ["tag1", "tag2", "tag3"],
      "issues": [
        {"severity": "high/medium/low", "description": "Mô tả vấn đề", "field": "title/description/tags"}
      ],
      "analysis": "Phân tích tổng quan và nhận xét"
    }
    `;
    
    // Gửi request đến Gemini API
    const response = await axios.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
      {
        contents: [{
          parts: [{
            text: prompt
          }]
        }],
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 1024,
        }
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': GEMINI_API_KEY,
        }
      }
    );
    
    // Trích xuất phản hồi
    const responseText = response.data.candidates[0].content.parts[0].text;
    
    // Trích xuất JSON từ phản hồi
    const jsonString = extractJsonFromText(responseText);
    if (!jsonString) {
      return { relevanceScore: 70 };
    }
    
    // Parse JSON
    const result = JSON.parse(jsonString);
    return result;
  } catch (error) {
    console.error('Lỗi khi phân tích văn bản với Gemini:', error);
    return { relevanceScore: 70 };
  }
}

// Tính điểm nội dung
function calculateContentScore({
  relevanceScore,
  titleLength,
  descriptionLength,
  tagsCount,
  specificationsCount,
  issues,
}) {
  let baseScore = relevanceScore;
  
  // Đánh giá độ dài tiêu đề
  if (titleLength < 5) {
    baseScore -= 10;
  } else if (titleLength < 10) {
    baseScore -= 5;
  } else if (titleLength > 50) {
    baseScore -= 5;
  }
  
  // Đánh giá độ dài mô tả
  if (descriptionLength < 20) {
    baseScore -= 15;
  } else if (descriptionLength < 50) {
    baseScore -= 10;
  } else if (descriptionLength > 100) {
    baseScore += 5;
  }
  
  // Đánh giá số lượng tags
  if (tagsCount === 0) {
    baseScore -= 10;
  } else if (tagsCount < 3) {
    baseScore -= 5;
  } else if (tagsCount >= 5) {
    baseScore += 5;
  }
  
  // Đánh giá số lượng thông số kỹ thuật
  if (specificationsCount > 0) {
    baseScore += specificationsCount * 2;
  }
  
  // Trừ điểm cho mỗi vấn đề được phát hiện
  for (const issue of issues) {
    const severity = issue.severity || 'low';
    if (severity === 'high') {
      baseScore -= 30;
    } else if (severity === 'medium') {
      baseScore -= 15;
    } else {
      baseScore -= 5;
    }
  }
  
  // Giới hạn điểm trong khoảng 0-100
  return Math.max(0, Math.min(100, baseScore));
}

// Tính điểm tuân thủ
function calculateComplianceScore(contentAnalysisResult, imageAnalysisResult, category) {
  let baseScore = 100;
  
  // Kiểm tra danh mục bị cấm
  if (BANNED_CATEGORIES.includes(category.toLowerCase())) {
    return 0;  // Không tuân thủ hoàn toàn
  }
  
  // Kiểm tra vấn đề nội dung
  const contentIssues = contentAnalysisResult.issues || [];
  for (const issue of contentIssues) {
    const severity = issue.severity || 'low';
    if (severity === 'high') {
      baseScore -= 40;
    } else if (severity === 'medium') {
      baseScore -= 20;
    } else {
      baseScore -= 10;
    }
  }
  
  // Kiểm tra vấn đề hình ảnh
  const imageIssues = imageAnalysisResult.issues || [];
  for (const issue of imageIssues) {
    const severity = issue.severity || 'low';
    if (severity === 'high') {
      baseScore -= 40;
    } else if (severity === 'medium') {
      baseScore -= 20;
    } else {
      baseScore -= 10;
    }
  }
  
  // Giới hạn điểm trong khoảng 0-100
  return Math.max(0, Math.min(100, baseScore));
}

// Tạo lý do từ chối
function generateRejectionReason(issues) {
  if (!issues || issues.length === 0) {
    return 'Sản phẩm không đáp ứng các tiêu chuẩn của nền tảng.';
  }
  
  // Tìm và ưu tiên vấn đề nghiêm trọng
  const highSeverityIssues = issues.filter(i => i.severity === 'high');
  if (highSeverityIssues.length > 0) {
    return highSeverityIssues.map(i => i.description).join('. ');
  }
  
  // Nếu không có vấn đề nghiêm trọng, liệt kê tất cả vấn đề
  return 'Sản phẩm bị từ chối vì các lý do sau: ' + issues.map(i => i.description).join('; ');
}

// Xác định trường có vấn đề
function determineIssueField(keyword, title, description, tags) {
  if (title.toLowerCase().includes(keyword.toLowerCase())) {
    return 'title';
  } else if (description.toLowerCase().includes(keyword.toLowerCase())) {
    return 'description';
  } else {
    for (const tag of tags) {
      if (tag.toLowerCase().includes(keyword.toLowerCase())) {
        return 'tags';
      }
    }
  }
  return 'content';
}

// Trích xuất JSON từ phản hồi văn bản
function extractJsonFromText(text) {
  try {
    // Tìm vị trí bắt đầu và kết thúc của JSON
    const startIndex = text.indexOf('{');
    const endIndex = text.lastIndexOf('}') + 1;
    
    if (startIndex >= 0 && endIndex > startIndex) {
      return text.substring(startIndex, endIndex);
    }
    return null;
  } catch (error) {
    console.error('Lỗi khi trích xuất JSON:', error);
    return null;
  }
} 