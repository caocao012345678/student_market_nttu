/**
 * Firebase Cloud Functions for Student Market NTTU
 * Đồng bộ hóa dữ liệu giữa Firestore và Pinecone
 */

// Thêm dotenv để đọc file .env
require('dotenv').config();

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
// const { GoogleGenerativeAI } = require('@google/generative-ai');
const { Pinecone } = require('@pinecone-database/pinecone');

// Khởi tạo ứng dụng Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Đọc cấu hình an toàn
const config = functions.config();
// Biến cấu hình với giá trị dự phòng
// Hiện không cần geminiApiKey vì không sử dụng Google Generative AI
// const geminiApiKey = (config && config.gemini && config.gemini.api_key) || 
//   process.env.GEMINI_API_KEY || '';
const pineconeApiKey = (config && config.pinecone && config.pinecone.api_key) || 
  process.env.PINECONE_API_KEY || '';
const pineconeEnv = (config && config.pinecone && config.pinecone.environment) || 
  process.env.PINECONE_ENVIRONMENT || 'gcp-starter';
const pineconeIndexName = (config && config.pinecone && config.pinecone.index_name) || 
  process.env.PINECONE_INDEX_NAME || 'student-market';
const palmApiKey = (config && config.google && config.google.palm_api_key) || 
  process.env.PALM_API_KEY || '';

// In ra các giá trị để debug
console.log('Pinecone API Key:', pineconeApiKey ? 'Đã thiết lập' : 'Chưa thiết lập');
console.log('Pinecone Environment:', pineconeEnv);
console.log('Pinecone Index Name:', pineconeIndexName);

// Khởi tạo Google AI cho Embeddings hiện không cần thiết
// const genAI = new GoogleGenerativeAI(geminiApiKey);
// const embeddingModel = genAI.getGenerativeModel({ model: 'embedding-001' });

// Khởi tạo Pinecone client nếu có API key
let pinecone;
let index;
if (pineconeApiKey) {
  try {
    pinecone = new Pinecone({
      apiKey: pineconeApiKey,
      environment: pineconeEnv,
    });
    
    // Lấy index từ Pinecone
    index = pinecone.index(pineconeIndexName);
    console.log('Pinecone client đã được khởi tạo thành công');
  } catch (error) {
    console.error('Lỗi khi khởi tạo Pinecone client:', error);
  }
} else {
  console.warn('Thiếu Pinecone API key, các tính năng liên quan đến Pinecone sẽ không hoạt động');
}

/**
 * Hàm này tạo văn bản mô tả từ dữ liệu sản phẩm
 * @param {Object} product - Đối tượng sản phẩm
 * @return {string} - Văn bản mô tả sản phẩm
 */
function createProductDescription(product) {
  return `
    Tên sản phẩm: ${product.name}
    Giá: ${product.price} VND
    Danh mục: ${product.category || 'Không có'}
    Mô tả: ${product.description || 'Không có mô tả'}
    Trạng thái: ${product.status || 'Đang bán'}
    Người bán: ${product.sellerName || 'Không có thông tin'}
  `;
}

/**
 * Hàm gọi API để nhúng văn bản thành vector
 * @param {string} text - Văn bản cần nhúng
 * @return {Promise<Array<number>>} - Vector nhúng
 */
async function getEmbedding(text) {
  try {
    if (!palmApiKey) {
      throw new Error('Không có Palm API key');
    }
    
    const API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/embedding-gecko-001:embedText';
    
    const response = await axios.post(
      `${API_URL}?key=${palmApiKey}`,
      {
        text: text,
      }
    );
    
    return response.data.embedding.values;
  } catch (error) {
    console.error('Lỗi khi tạo embedding:', error);
    throw new Error('Không thể tạo embedding');
  }
}

/**
 * Hàm upsert dữ liệu vào Pinecone
 * @param {string} id - ID của document
 * @param {Array<number>} vector - Vector nhúng
 * @param {Object} metadata - Metadata kèm theo
 * @return {Promise<void>}
 */
async function upsertToPinecone(id, vector, metadata) {
  try {
    if (!index) {
      throw new Error('Pinecone client chưa được khởi tạo');
    }
    
    await index.upsert({
      vectors: [
        {
          id: id,
          values: vector,
          metadata: metadata,
        },
      ],
    });
    console.log(`Đã upsert document ${id} vào Pinecone`);
  } catch (error) {
    console.error('Lỗi khi upsert vào Pinecone:', error);
    throw new Error('Không thể upsert vào Pinecone');
  }
}

/**
 * Cloud Function xử lý khi tạo/cập nhật sản phẩm
 */
exports.syncProductToPinecone = functions.firestore
  .document('products/{productId}')
  .onWrite(async (change, context) => {
    if (!index) {
      console.error('Pinecone client chưa được khởi tạo');
      return null;
    }
    
    const productId = context.params.productId;
    
    // Sản phẩm đã bị xóa
    if (!change.after.exists) {
      try {
        await index.deleteOne(productId);
        console.log(`Đã xóa sản phẩm ${productId} từ Pinecone`);
        return null;
      } catch (error) {
        console.error(`Lỗi khi xóa sản phẩm ${productId} từ Pinecone:`, error);
        throw error;
      }
    }
    
    // Lấy dữ liệu sản phẩm mới
    const productData = change.after.data();
    const description = createProductDescription(productData);
    
    try {
      // Tạo embedding từ mô tả sản phẩm
      const embedding = await getEmbedding(description);
      
      // Chuẩn bị metadata
      const metadata = {
        name: productData.name,
        price: productData.price,
        category: productData.category || '',
        status: productData.status || 'active',
        sellerId: productData.sellerId,
        sellerName: productData.sellerName || '',
        createdAt: productData.createdAt 
          ? productData.createdAt.toDate().toISOString() 
          : new Date().toISOString(),
      };
      
      // Upsert vào Pinecone
      await upsertToPinecone(productId, embedding, metadata);
      
      return null;
    } catch (error) {
      console.error(`Lỗi khi đồng bộ sản phẩm ${productId} với Pinecone:`, error);
      throw error;
    }
  });

/**
 * Cloud Function để tìm kiếm sản phẩm tương tự
 */
exports.findSimilarProducts = functions.https.onCall(async (data) => {
  if (!index) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Pinecone client chưa được khởi tạo'
    );
  }
  
  // Kiểm tra xác thực
  if (!data || !data.productId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Cần có ID sản phẩm để tìm kiếm'
    );
  }
  
  const { productId, limit = 5 } = data;
  
  try {
    // Lấy thông tin sản phẩm từ Firestore
    const productDoc = await db.collection('products').doc(productId).get();
    
    if (!productDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'Không tìm thấy sản phẩm'
      );
    }
    
    const productData = productDoc.data();
    const description = createProductDescription(productData);
    
    // Tạo embedding từ mô tả sản phẩm
    const embedding = await getEmbedding(description);
    
    // Tìm kiếm các sản phẩm tương tự trong Pinecone
    const queryResult = await index.query({
      vector: embedding,
      topK: limit + 1, // +1 vì có thể kết quả bao gồm chính sản phẩm đó
      includeMetadata: true,
    });
    
    // Lọc bỏ chính sản phẩm đó nếu có trong kết quả
    const similarProducts = queryResult.matches
      .filter((match) => match.id !== productId)
      .slice(0, limit)
      .map((match) => ({
        id: match.id,
        score: match.score,
        ...match.metadata,
      }));
    
    return { products: similarProducts };
  } catch (error) {
    console.error('Lỗi khi tìm kiếm sản phẩm tương tự:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Đã xảy ra lỗi khi tìm kiếm sản phẩm tương tự'
    );
  }
});

/**
 * Cloud Function tìm kiếm sản phẩm theo văn bản
 */
exports.searchProductsByText = functions.https.onCall(async (data) => {
  if (!index) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Pinecone client chưa được khởi tạo'
    );
  }
  
  const { query, limit = 10, filter = {} } = data;
  
  if (!query || query.trim() === '') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Vui lòng nhập từ khóa tìm kiếm'
    );
  }
  
  try {
    // Tạo embedding từ truy vấn tìm kiếm
    const embedding = await getEmbedding(query);
    
    // Xây dựng filter nếu có
    const pineconeFilter = {};
    
    if (filter.category) {
      pineconeFilter.category = filter.category;
    }
    
    if (filter.priceMin || filter.priceMax) {
      pineconeFilter.price = {};
      if (filter.priceMin) pineconeFilter.price['$gte'] = filter.priceMin;
      if (filter.priceMax) pineconeFilter.price['$lte'] = filter.priceMax;
    }
    
    // Chỉ tìm kiếm sản phẩm đang bán
    pineconeFilter.status = filter.status || 'active';
    
    // Thực hiện tìm kiếm vector trong Pinecone
    const queryResult = await index.query({
      vector: embedding,
      topK: limit,
      includeMetadata: true,
      filter: Object.keys(pineconeFilter).length > 0 ? pineconeFilter : undefined,
    });
    
    // Chuyển đổi kết quả
    const searchResults = queryResult.matches.map((match) => ({
      id: match.id,
      score: match.score,
      ...match.metadata,
    }));
    
    return { results: searchResults };
  } catch (error) {
    console.error('Lỗi khi tìm kiếm sản phẩm:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Đã xảy ra lỗi khi tìm kiếm sản phẩm'
    );
  }
});

/**
 * Cloud Function đồng bộ lại toàn bộ sản phẩm với Pinecone
 * Chức năng này chỉ dành cho admin
 */
exports.rebuildPineconeIndex = functions.https.onCall(async (data, context) => {
  if (!index) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Pinecone client chưa được khởi tạo'
    );
  }
  
  // Kiểm tra quyền admin
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Chỉ admin mới có thể sử dụng chức năng này'
    );
  }
  
  try {
    // Xóa toàn bộ index (tùy chọn)
    if (data.clearExisting === true) {
      await index.deleteAll();
      console.log('Đã xóa toàn bộ index');
    }
    
    // Lấy tất cả sản phẩm từ Firestore
    const productsSnapshot = await db.collection('products').get();
    
    // Đếm số lượng sản phẩm đã xử lý
    let processedCount = 0;
    const totalProducts = productsSnapshot.size;
    
    // Xử lý mỗi lô 100 sản phẩm
    const batchSize = 100;
    const batches = [];
    
    for (let i = 0; i < totalProducts; i += batchSize) {
      const batch = productsSnapshot.docs
        .slice(i, i + batchSize)
        .map(async (doc) => {
          const productId = doc.id;
          const productData = doc.data();
          const description = createProductDescription(productData);
          
          try {
            // Tạo embedding
            const embedding = await getEmbedding(description);
            
            // Chuẩn bị metadata
            const metadata = {
              name: productData.name,
              price: productData.price,
              category: productData.category || '',
              status: productData.status || 'active',
              sellerId: productData.sellerId,
              sellerName: productData.sellerName || '',
              createdAt: productData.createdAt 
                ? productData.createdAt.toDate().toISOString() 
                : new Date().toISOString(),
            };
            
            // Upsert vào Pinecone
            await upsertToPinecone(productId, embedding, metadata);
            processedCount++;
            
            return { success: true, id: productId };
          } catch (error) {
            console.error(`Lỗi khi xử lý sản phẩm ${productId}:`, error);
            return { success: false, id: productId, error: error.message };
          }
        });
      
      batches.push(Promise.all(batch));
    }
    
    // Chờ tất cả các batch hoàn thành
    const results = await Promise.all(batches);
    
    // Tổng hợp kết quả
    const flatResults = results.flat();
    const successCount = flatResults.filter((r) => r.success).length;
    const failedResults = flatResults.filter((r) => !r.success);
    
    return {
      success: true,
      processed: processedCount,
      total: totalProducts,
      successful: successCount,
      failed: failedResults.length,
      failedDetails: failedResults,
    };
  } catch (error) {
    console.error('Lỗi khi rebuild Pinecone index:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Đã xảy ra lỗi khi rebuild Pinecone index'
    );
  }
}); 