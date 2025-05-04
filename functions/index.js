/**
 * Firebase Cloud Functions for Student Market NTTU
 * Đồng bộ hóa dữ liệu giữa Firestore và Pinecone
 */

// Thêm dotenv để đọc file .env
require('dotenv').config();

const functions = require('firebase-functions');
const admin = require('firebase-admin');
// Không còn sử dụng axios nên có thể xóa import
// const axios = require('axios');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { Pinecone } = require('@pinecone-database/pinecone');

// Khởi tạo ứng dụng Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Đọc cấu hình an toàn
const config = functions.config();
// Biến cấu hình với giá trị dự phòng
const geminiApiKey = (config && config.gemini && config.gemini.api_key) || 
  process.env.GEMINI_API_KEY || '';
const pineconeApiKey = (config && config.pinecone && config.pinecone.api_key) || 
  process.env.PINECONE_API_KEY || '';
const pineconeHost = (config && config.pinecone && config.pinecone.host) || 
  process.env.PINECONE_HOST || '';
const pineconeIndexName = process.env.PINECONE_INDEX_NAME || '';

// In ra các giá trị để debug
console.log('Gemini API Key:', geminiApiKey ? 'Đã thiết lập' : 'Chưa thiết lập');
console.log('Pinecone API Key:', pineconeApiKey ? 'Đã thiết lập' : 'Chưa thiết lập');
console.log('Pinecone Host:', pineconeHost);
console.log('Pinecone Index Name:', pineconeIndexName);

// Khởi tạo Google AI cho Embeddings 
let genAI = null;
let embeddingModel = null;
if (geminiApiKey) {
  try {
    genAI = new GoogleGenerativeAI(geminiApiKey);
    embeddingModel = genAI.getGenerativeModel({ model: 'embedding-001' });
    console.log('Google Generative AI đã được khởi tạo thành công');
  } catch (error) {
    console.error('Lỗi khi khởi tạo Google Generative AI:', error);
  }
} else {
  console.warn('Thiếu Gemini API key, các tính năng liên quan đến embedding sẽ không hoạt động');
}

// Khởi tạo Pinecone client nếu có API key
let pinecone;
let index;
if (pineconeApiKey && pineconeHost) {
  try {
    // Khởi tạo theo API phiên bản 5.1.2
    pinecone = new Pinecone({
      apiKey: pineconeApiKey,
    });
    
    // Lấy index từ Pinecone
    index = pinecone.Index(pineconeIndexName);
    console.log('Pinecone client đã được khởi tạo thành công');
  } catch (error) {
    console.error('Lỗi khi khởi tạo Pinecone client:', error);
  }
} else {
  console.warn('Thiếu Pinecone API key hoặc Host URL, các tính năng liên quan đến Pinecone sẽ không hoạt động');
}

/**
 * Hàm này tạo văn bản mô tả từ dữ liệu sản phẩm
 * @param {Object} product - Đối tượng sản phẩm
 * @return {string} - Văn bản mô tả sản phẩm
 */
function createProductDescription(product) {
  // Tạo mảng tags từ trường tags nếu có
  const tags = Array.isArray(product.tags) && product.tags.length > 0 
    ? product.tags.join(', ') 
    : 'Không có thẻ';
  
  return `
    Tên sản phẩm: ${product.title || product.name || 'Không có tên'}
    Giá: ${product.price} VND
    Danh mục: ${product.category || 'Không có'}
    Mô tả: ${product.description || 'Không có mô tả'}
    Trạng thái: ${product.status || 'Đang bán'}
    Người bán: ${product.sellerName || 'Không có thông tin'}
    Thẻ: ${tags}
    ${product.isSold ? 'Sản phẩm đã bán' : 'Sản phẩm còn hàng'}
  `;
}

/**
 * Hàm tạo embedding sử dụng Google Generative AI SDK với mô hình embedding-001
 * @param {string} text - Văn bản cần nhúng
 * @return {Promise<Array<number>>} - Vector nhúng
 */
async function createEmbedding(text) {
  try {
    if (!embeddingModel) {
      throw new Error('Google Generative AI embeddingModel chưa được khởi tạo');
    }
    
    console.log('Tạo embedding với GoogleGenerativeAI SDK');
    console.log('Độ dài văn bản:', text.length);
    
    try {
      // Tạo embedding
      const result = await embeddingModel.embedContent(text);
      
      // Đảm bảo có giá trị embedding và values
      let embedding = [];
      
      if (result && result.embedding && Array.isArray(result.embedding.values)) {
        embedding = result.embedding.values;
      } else if (result && result.embedding && typeof result.embedding === 'object') {
        // Trường hợp embedding không có thuộc tính values nhưng là một đối tượng
        console.log('Cấu trúc embedding khác mong đợi, kiểm tra thuộc tính');
        // Thử lấy trường đầu tiên chứa dữ liệu mảng
        for (const key in result.embedding) {
          if (Array.isArray(result.embedding[key])) {
            embedding = result.embedding[key];
            console.log(`Đã tìm thấy mảng giá trị trong thuộc tính ${key}`);
            break;
          }
        }
      } else if (result && Array.isArray(result)) {
        // Trường hợp kết quả trực tiếp là một mảng
        embedding = result;
      }
      
      // Kiểm tra kết quả cuối cùng
      if (!Array.isArray(embedding) || embedding.length === 0) {
        console.error('Không thể lấy vector embedding từ phản hồi:', result);
        throw new Error('Phản hồi từ API không chứa vector embedding hợp lệ');
      }
      
      console.log(`Đã nhận được vector embedding với ${embedding.length} phần tử`);
      return embedding;
    } catch (apiError) {
      console.error('Chi tiết lỗi API:', apiError);
      throw new Error(`Lỗi khi gọi API embedding: ${apiError.message}`);
    }
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
    
    // Kiểm tra vector phải là mảng
    if (!Array.isArray(vector)) {
      console.error('Vector không phải là một mảng. Kiểu dữ liệu:', typeof vector);
      throw new Error('Vector phải là một mảng số');
    }

    // Kiểm tra vector phải chứa các số
    if (vector.length === 0 || vector.some(val => typeof val !== 'number')) {
      console.error('Vector chứa giá trị không hợp lệ. Độ dài:', vector.length);
      throw new Error('Vector phải chứa các giá trị số');
    }
    
    // Đảm bảo metadata là object và không chứa giá trị không hợp lệ
    const safeMetadata = {};
    if (metadata) {
      // Chỉ lấy các trường cần thiết và đảm bảo kiểu dữ liệu đúng
      if (metadata.name !== undefined) safeMetadata.name = String(metadata.name || '');
      if (metadata.title !== undefined) safeMetadata.title = String(metadata.title || '');
      if (metadata.price !== undefined) safeMetadata.price = Number(metadata.price || 0);
      if (metadata.category !== undefined) safeMetadata.category = String(metadata.category || '');
      if (metadata.status !== undefined) safeMetadata.status = String(metadata.status || 'active');
      if (metadata.description !== undefined) safeMetadata.description = String(metadata.description || '');
      if (metadata.sellerId !== undefined) safeMetadata.sellerId = String(metadata.sellerId || '');
      if (metadata.sellerName !== undefined) safeMetadata.sellerName = String(metadata.sellerName || '');
      if (metadata.createdAt !== undefined) safeMetadata.createdAt = String(metadata.createdAt || '');
      
      // Thêm trường mới
      if (metadata.images && Array.isArray(metadata.images) && metadata.images.length > 0) {
        safeMetadata.imageUrl = String(metadata.images[0] || '');
      }
      
      if (metadata.tags && Array.isArray(metadata.tags)) {
        safeMetadata.tags = metadata.tags.map(tag => String(tag || '')).filter(tag => tag !== '');
      }
      
      // Đảm bảo trường isSold được phản ánh qua status
      if (metadata.isSold === true) {
        safeMetadata.status = 'sold';
      }
      
      // Thêm trường type để phân biệt dữ liệu
      safeMetadata.type = 'product'; // Thay thế cho namespace
    }
    
    console.log(`Đang upsert document ${id} với vector ${vector.length} phần tử`);
    console.log('SafeMetadata:', JSON.stringify(safeMetadata));
    
    // Cấu trúc upsert cho phiên bản SDK 5.1.2
    const upsertData = [{
      id: String(id),
      values: vector,
      metadata: safeMetadata
    }];    
    
    await index.upsert(upsertData);
    
    console.log(`Đã upsert document ${id} vào Pinecone`);
  } catch (error) {
    console.error('Lỗi khi upsert vào Pinecone:', error);
    
    if (error.name === 'PineconeArgumentError') {
      console.error('Chi tiết lỗi PineconeArgumentError:', error.message);
      // Không log toàn bộ vector - chỉ log thông tin cần thiết
      console.error('Thông tin về vector:', {
        vectorType: typeof vector,
        isArray: Array.isArray(vector),
        vectorLength: vector ? vector.length : 'null',
        sampleValues: vector && vector.length > 0 ? vector.slice(0, 3) : []
      });
    }
    
    // Hiển thị thông tin SDK version
    try {
      const pineconeVersion = require('@pinecone-database/pinecone/package.json').version;
      console.log('Phiên bản SDK Pinecone:', pineconeVersion);
    } catch (err) {
      console.log('Không thể xác định phiên bản SDK Pinecone');
    }
    
    throw new Error(`Không thể upsert vào Pinecone: ${error.message}`);
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
    
    if (!embeddingModel) {
      console.error('Google Generative AI embeddingModel chưa được khởi tạo');
      return null;
    }
    
    const productId = context.params.productId;
    
    // Sản phẩm đã bị xóa
    if (!change.after.exists) {
      try {
        // API phiên bản 5.1.2 - Xóa vector
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
    
    // Log dữ liệu sản phẩm để debug
    console.log(`Đang xử lý sản phẩm: ${productId}`);
    console.log('Dữ liệu sản phẩm:', JSON.stringify(productData));
    
    try {
      // Tạo embedding từ mô tả sản phẩm
      const embedding = await createEmbedding(description);
      
      // Chuẩn bị metadata đảm bảo kiểu dữ liệu và không có giá trị null/undefined
      const metadata = {
        name: productData.title ? String(productData.title) : '',
        title: productData.title ? String(productData.title) : '',
        price: productData.price ? Number(productData.price) : 0,
        category: productData.category ? String(productData.category) : '',
        status: productData.status ? String(productData.status) : 'active',
        description: productData.description ? String(productData.description) : '',
        sellerId: productData.sellerId ? String(productData.sellerId) : '',
        sellerName: productData.sellerName ? String(productData.sellerName) : '',
        images: Array.isArray(productData.images) ? productData.images : [],
        tags: Array.isArray(productData.tags) ? productData.tags : [],
        isSold: productData.isSold === true || productData.status === 'sold',
      };
      
      // Xử lý timestamp một cách an toàn
      if (productData.createdAt) {
        try {
          // Nếu là Firebase Timestamp, chuyển về ISO string
          if (typeof productData.createdAt.toDate === 'function') {
            metadata.createdAt = productData.createdAt.toDate().toISOString();
          } 
          // Nếu là Date object
          else if (productData.createdAt instanceof Date) {
            metadata.createdAt = productData.createdAt.toISOString();
          }
          // Nếu là timestamp dạng object với _seconds và _nanoseconds 
          else if (productData.createdAt._seconds) {
            const date = new Date(productData.createdAt._seconds * 1000);
            metadata.createdAt = date.toISOString();
          }
          // Nếu là chuỗi
          else if (typeof productData.createdAt === 'string') {
            metadata.createdAt = productData.createdAt;
          }
          // Mặc định
          else {
            metadata.createdAt = new Date().toISOString();
          }
        } catch (timeError) {
          console.error('Lỗi xử lý timestamp:', timeError);
          metadata.createdAt = new Date().toISOString();
        }
      } else {
        metadata.createdAt = new Date().toISOString();
      }
      
      // Log metadata để debug
      console.log('Metadata đã chuẩn bị:', JSON.stringify(metadata));
      
      // Upsert vào Pinecone với namespace
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
  
  if (!embeddingModel) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Google Generative AI embeddingModel chưa được khởi tạo'
    );
  }
  
  // Kiểm tra tham số đầu vào
  if (!data) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Dữ liệu đầu vào không được cung cấp'
    );
  }
  
  // Hỗ trợ cả hai chế độ tìm kiếm: theo productId hoặc theo query text
  if (!data.productId && !data.query) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Cần có ID sản phẩm hoặc từ khóa tìm kiếm'
    );
  }
  
  const { productId, query, limit = 5 } = data;
  
  try {
    let embedding;
    
    if (productId) {
      // Tìm theo sản phẩm
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
      embedding = await createEmbedding(description);
    } else {
      // Tìm theo từ khóa
      embedding = await createEmbedding(query);
    }
    
    // Tìm kiếm các sản phẩm tương tự trong Pinecone
    const queryResult = await index.query({
      vector: embedding,
      topK: limit + 1, // +1 vì có thể kết quả bao gồm chính sản phẩm đó
      includeMetadata: true,
      filter: {
        type: 'product'
      }
    });
    
    // Lọc bỏ chính sản phẩm đó nếu có trong kết quả
    const similarProducts = queryResult.matches
      .filter((match) => match.id !== (productId ? `prod_${productId}` : null))
      .slice(0, limit)
      .map((match) => ({
        id: match.id.startsWith('prod_') ? match.id.substring(5) : match.id,
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
  
  if (!embeddingModel) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Google Generative AI embeddingModel chưa được khởi tạo'
    );
  }
  
  const { query, limit = 10, filter = {}, scoreThreshold = 0.8 } = data;
  
  if (!query || query.trim() === '') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Vui lòng nhập từ khóa tìm kiếm'
    );
  }
  
  try {
    // Tạo embedding từ truy vấn tìm kiếm
    const embedding = await createEmbedding(query);
    
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
    pineconeFilter.status = filter.status || 'available';
    
    // Thực hiện tìm kiếm vector trong Pinecone
    const queryResult = await index.query({
      vector: embedding,
      topK: limit,
      includeMetadata: true,
      // Chỉ áp dụng filter cơ bản nếu có
      filter: Object.keys(pineconeFilter).length > 0 ? pineconeFilter : undefined
    });
    
    // Chuyển đổi kết quả và lọc theo ngưỡng điểm
    const searchResults = queryResult.matches
      .filter(match => match.score >= scoreThreshold)
      .map((match) => ({
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
  
  if (!embeddingModel) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Google Generative AI embeddingModel chưa được khởi tạo'
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
      await index.deleteAll({ filter: { type: { $eq: 'product' } } });  // Thay thế namespace
      console.log('Đã xóa toàn bộ index của sản phẩm');
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
            const embedding = await createEmbedding(description);
            
            // Chuẩn bị metadata đầy đủ
            const metadata = {
              name: productData.title || productData.name || '',
              title: productData.title || '',
              price: productData.price,
              category: productData.category || '',
              status: productData.status || 'active',
              description: productData.description || '',
              sellerId: productData.sellerId,
              sellerName: productData.sellerName || '',
              images: Array.isArray(productData.images) ? productData.images : [],
              tags: Array.isArray(productData.tags) ? productData.tags : [],
              isSold: productData.isSold === true || productData.status === 'sold',
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
    console.error('Lỗi khi đồng bộ lại index:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Đã xảy ra lỗi khi đồng bộ lại index'
    );
  }
});

/**
 * Cloud Function tạo tài khoản hàng loạt
 * Chức năng này chỉ dành cho admin
 */
exports.createBulkAccounts = functions.https.onCall(async (data, context) => {
  console.log('Bắt đầu tạo tài khoản hàng loạt:', {
    requestedBy: context.auth?.uid,
    email: context.auth?.token?.email,
    totalAccounts: data.accounts?.length || 0
  });
  
  // Kiểm tra người dùng đã đăng nhập
  if (!context.auth) {
    console.error('Người dùng chưa đăng nhập');
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Bạn cần đăng nhập để sử dụng chức năng này'
    );
  }
  
  // Có thể thêm kiểm tra bổ sung như kiểm tra email của người dùng
  // thay vì dựa vào custom claims admin
  
  // HOẶC: Kiểm tra người dùng có trong danh sách admin
  const adminEmails = ['admin@nttu.edu.vn', context.auth.token.email]; // Thêm email của bạn vào đây
  if (!adminEmails.includes(context.auth.token.email)) {
    console.error('Người dùng không có quyền admin:', context.auth.token.email);
    throw new functions.https.HttpsError(
      'permission-denied',
      'Chỉ admin mới có thể sử dụng chức năng này'
    );
  }

  // Kiểm tra dữ liệu đầu vào
  if (!data.accounts || !Array.isArray(data.accounts) || data.accounts.length === 0) {
    console.error('Dữ liệu đầu vào không hợp lệ:', data);
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Vui lòng cung cấp danh sách tài khoản hợp lệ'
    );
  }

  const accounts = data.accounts;
  const results = {
    successful: [],
    failed: []
  };

  try {
    console.log(`Bắt đầu xử lý ${accounts.length} tài khoản`);
    
    // Xử lý từng tài khoản một
    for (let i = 0; i < accounts.length; i++) {
      const account = accounts[i];
      console.log(`Đang xử lý tài khoản ${i+1}/${accounts.length}: ${account.email}`);
      
      try {
        // Kiểm tra dữ liệu tài khoản
        if (!account.email || !account.password || !account.displayName) {
          console.warn(`Tài khoản ${i+1}/${accounts.length} thiếu thông tin:`, {
            hasEmail: !!account.email,
            hasPassword: !!account.password,
            hasDisplayName: !!account.displayName
          });
          
          results.failed.push({
            email: account.email || 'Unknown',
            success: false,
            error: 'Thiếu thông tin tài khoản'
          });
          continue;
        }

        // Kiểm tra tài khoản đã tồn tại chưa
        try {
          const userExists = await admin.auth().getUserByEmail(account.email);
          if (userExists) {
            console.warn(`Email ${account.email} đã tồn tại trong hệ thống`);
            results.failed.push({
              email: account.email,
              success: false,
              error: 'Email đã tồn tại trong hệ thống'
            });
            continue;
          }
        } catch (error) {
          // Lỗi USER_NOT_FOUND có nghĩa là email chưa tồn tại, đây là kết quả mong muốn
          if (error.code !== 'auth/user-not-found') {
            console.error(`Lỗi khi kiểm tra email ${account.email}:`, error);
          }
        }

        // Tạo tài khoản trong Firebase Authentication
        console.log(`Tạo tài khoản Authentication cho ${account.email}`);
        const userRecord = await admin.auth().createUser({
          email: account.email,
          password: account.password,
          displayName: account.displayName,
          disabled: false
        });

        // Thêm thông tin vào Firestore
        console.log(`Tạo document Firestore cho ${account.email}`);
        await db.collection('users').doc(userRecord.uid).set({
          email: account.email,
          displayName: account.displayName,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          lastActive: admin.firestore.FieldValue.serverTimestamp(),
          photoURL: '',
          phoneNumber: account.phoneNumber || '',
          address: '',
          preferences: {},
          settings: {},
          favoriteProducts: [],
          followers: [],
          following: [],
          isShipper: false,
          isVerified: false,
          productCount: 0,
          rating: 0.0,
          nttPoint: 0,
          nttCredit: 100,
          isStudent: true,
          studentId: account.studentId || '',
          department: account.department || '',
          studentYear: account.studentYear || null,
          major: account.major || null,
          specialization: account.specialization || null,
          interests: [],
          preferredCategories: [],
          completedSurvey: false,
          isAdmin: account.role === 'admin',
          role: account.role || 'user',
          createdBy: context.auth.uid // ID của admin đã tạo tài khoản
        });

        // Thêm vào danh sách thành công
        console.log(`✅ Đã tạo tài khoản thành công cho ${account.email}`);
        results.successful.push({
          uid: userRecord.uid,
          email: account.email,
          displayName: account.displayName,
          success: true
        });
      } catch (error) {
        console.error(`❌ Lỗi khi tạo tài khoản ${account.email}:`, error);
        // Ghi chi tiết hơn về lỗi
        const errorInfo = {
          code: error.code || 'unknown',
          message: error.message,
          stack: error.stack,
        };
        console.error('Chi tiết lỗi:', JSON.stringify(errorInfo));
        
        results.failed.push({
          email: account.email,
          success: false,
          error: error.message,
          errorCode: error.code || 'unknown'
        });
      }
    }

    const summary = {
      success: true,
      totalProcessed: accounts.length,
      successCount: results.successful.length,
      failedCount: results.failed.length,
      successful: results.successful,
      failed: results.failed,
      completedAt: new Date().toISOString()
    };
    
    console.log(`✅ Hoàn thành tạo tài khoản hàng loạt: ${results.successful.length} thành công, 
      ${results.failed.length} thất bại`);
    
    return summary;
  } catch (error) {
    console.error('❌ Lỗi hệ thống khi tạo tài khoản hàng loạt:', error);
    console.error('Stack trace:', error.stack);
    
    throw new functions.https.HttpsError(
      'internal',
      'Đã xảy ra lỗi khi xử lý tạo tài khoản hàng loạt',
      { errorMessage: error.message }
    );
  }
});

/**
 * Cloud Function để gửi thông báo FCM đến người dùng
 * 
 * Dữ liệu đầu vào:
 * {
 *   targetUserId: string, // ID người dùng nhận thông báo
 *   title: string,       // Tiêu đề thông báo
 *   body: string,        // Nội dung thông báo
 *   data: Object,        // Dữ liệu bổ sung
 *   sender: {            // Thông tin người gửi (tùy chọn)
 *     uid: string,
 *     email: string
 *   }
 * }
 * 
 * Kết quả:
 * {
 *   success: boolean,
 *   successCount: number,
 *   failureCount: number,
 *   message?: string
 * }
 */
exports.sendFCM = functions.https.onCall(async (data, context) => {
  // Kiểm tra xác thực người dùng
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Yêu cầu xác thực để thực hiện chức năng này');
  }

  const { targetUserId, title, body, data: additionalData = {}, sender = {} } = data;
  
  // Kiểm tra dữ liệu đầu vào
  if (!targetUserId || !title || !body) {
    throw new functions.https.HttpsError('invalid-argument', 'Thiếu thông tin targetUserId, title hoặc body');
  }

  try {
    console.log(`Chuẩn bị gửi thông báo đến người dùng: ${targetUserId}`);
    console.log(`Tiêu đề: ${title}, Nội dung: ${body}`);
    
    // Lấy token thiết bị của người dùng từ Firestore
    const userDoc = await admin.firestore().collection('users').doc(targetUserId).get();
    
    if (!userDoc.exists) {
      console.log(`Không tìm thấy người dùng với ID: ${targetUserId}`);
      return { 
        success: false, 
        successCount: 0, 
        failureCount: 0, 
        message: 'Không tìm thấy người dùng' 
      };
    }
    
    const userData = userDoc.data();
    const tokens = userData.fcmTokens || [];
    
    if (tokens.length === 0) {
      console.log(`Người dùng ${targetUserId} không có thiết bị nào đăng ký`);
      return { 
        success: false, 
        successCount: 0, 
        failureCount: 0, 
        message: 'Người dùng không có thiết bị nào đăng ký' 
      };
    }
    
    console.log(`Tìm thấy ${tokens.length} token thiết bị của người dùng`);
    
    // Thêm thông tin sender vào data nếu có
    const messageData = { ...additionalData };
    if (sender.uid) {
      messageData.senderId = sender.uid;
    }
    
    // Chuẩn bị thông báo FCM
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: messageData,
      tokens: tokens, // Gửi đến nhiều thiết bị
      android: {
        priority: 'high',
        notification: {
          channelId: 'high_importance_channel',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    };
    
    // Gửi thông báo sử dụng Admin SDK
    console.log('Bắt đầu gửi thông báo FCM');
    const response = await admin.messaging().sendMulticast(message);
    console.log(`Kết quả: ${response.successCount} thành công, ${response.failureCount} thất bại`);
    
    // Nếu có lỗi với token thiết bị, cập nhật danh sách tokens
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.log(`Lỗi với token: ${tokens[idx]}`);
          console.log(`Lỗi: ${resp.error.code} - ${resp.error.message}`);
          failedTokens.push(tokens[idx]);
        }
      });
      
      // Xóa token không hợp lệ khỏi Firestore
      if (failedTokens.length > 0) {
        console.log(`Xóa ${failedTokens.length} token không hợp lệ`);
        const validTokens = tokens.filter(token => !failedTokens.includes(token));
        
        await admin.firestore().collection('users').doc(targetUserId).update({
          fcmTokens: validTokens
        });
      }
    }
    
    // Lưu thông báo vào Firestore
    try {
      const notificationRef = await admin.firestore().collection('notifications').add({
        userId: targetUserId,
        title: title,
        body: body,
        type: additionalData.type || 'system',
        data: additionalData,
        senderId: context.auth.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      });
      
      console.log(`Đã lưu thông báo với ID: ${notificationRef.id}`);
    } catch (error) {
      console.error('Lỗi khi lưu thông báo vào Firestore:', error);
    }
    
    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error('Lỗi khi gửi FCM:', error);
    throw new functions.https.HttpsError('internal', 'Lỗi khi gửi thông báo', error.message);
  }
});

// Thêm Cloud Function tự động gửi thông báo khi có tin nhắn mới
exports.sendChatNotification = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    try {
      const { chatId, messageId } = context.params;
      const messageData = snapshot.data();
      const senderId = messageData.senderId;
      
      console.log(`Nhận tin nhắn mới trong chat ${chatId} từ người dùng ${senderId}`);
      
      // Lấy thông tin chat để biết người nhận
      const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        console.log(`Không tìm thấy chat với ID: ${chatId}`);
        return null;
      }
      
      const chatData = chatDoc.data();
      const participants = chatData.participants || [];
      
      // Lấy thông tin người gửi
      const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
      if (!senderDoc.exists) {
        console.log(`Không tìm thấy người gửi với ID: ${senderId}`);
        return null;
      }
      
      const senderData = senderDoc.data();
      const senderName = senderData.displayName || senderData.email || 'Người dùng';
      
      // Gửi thông báo cho tất cả người tham gia trò chuyện, trừ người gửi
      for (const participantId of participants) {
        if (participantId !== senderId) {
          try {
            console.log(`Chuẩn bị gửi thông báo cho người dùng ${participantId}`);
            
            // Lấy token thiết bị của người nhận
            const recipientDoc = await admin.firestore().collection('users').doc(participantId).get();
            if (!recipientDoc.exists) {
              console.log(`Bỏ qua: Không tìm thấy người nhận ${participantId}`);
              continue;
            }
            
            const recipientData = recipientDoc.data();
            const tokens = Array.isArray(recipientData.fcmTokens) ? recipientData.fcmTokens : [];
            
            if (tokens.length === 0) {
              console.log(`Bỏ qua: Người nhận ${participantId} không có FCM token`);
              continue;
            }
            
            console.log(`Tìm thấy ${tokens.length} token cho người dùng ${participantId}`);
            
            // Chuẩn bị thông báo
            const title = `Tin nhắn mới từ ${senderName}`;
            const body = messageData.text || 'Đã gửi một tin nhắn';
            
            // Thay vì sendMulticast, gửi thông báo cho từng token riêng lẻ
            for (const token of tokens) {
              try {
                // Chặn token rỗng
                if (!token || token.trim() === '') {
                  console.log('Bỏ qua token rỗng');
                  continue;
                }
                
                const message = {
                  notification: {
                    title: title,
                    body: body,
                  },
                  data: {
                    type: 'chat_message',
                    chatId: chatId,
                    messageId: messageId,
                    senderId: senderId,
                  },
                  token: token, // Gửi cho một thiết bị
                  android: {
                    priority: 'high',
                    notification: {
                      channelId: 'chat_messages_channel',
                      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                    },
                  },
                  apns: {
                    payload: {
                      aps: {
                        contentAvailable: true,
                      },
                    },
                  },
                };
                
                // Gửi thông báo riêng lẻ
                await admin.messaging().send(message);
                console.log(`Đã gửi thông báo tới token: ${token.substring(0, 10)}...`);
              } catch (tokenError) {
                console.error(`Lỗi gửi thông báo đến token ${token.substring(0, 10)}...: ${tokenError.message}`);
                
                // Nếu token không hợp lệ, xóa khỏi danh sách
                if (tokenError.code === 'messaging/invalid-registration-token' || 
                    tokenError.code === 'messaging/registration-token-not-registered') {
                  console.log(`Chuẩn bị xóa token không hợp lệ ${token.substring(0, 10)}...`);
                  const validTokens = tokens.filter(t => t !== token);
                  
                  await admin.firestore().collection('users').doc(participantId).update({
                    fcmTokens: validTokens
                  });
                  console.log('Đã xóa token không hợp lệ');
                }
              }
            }
            
            // Lưu thông báo vào Firestore
            await admin.firestore().collection('notifications').add({
              userId: participantId,
              title: title,
              body: body,
              type: 'chat_message',
              data: {
                chatId: chatId,
                messageId: messageId, 
                senderId: senderId
              },
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              isRead: false,
            });
            
            console.log(`Đã lưu thông báo cho người dùng ${participantId}`);
          } catch (participantError) {
            console.error(`Lỗi xử lý thông báo cho người dùng ${participantId}: ${participantError.message}`);
            // Tiếp tục với người tham gia khác
          }
        }
      }
      
      return null;
    } catch (error) {
      console.error('Lỗi khi gửi thông báo chat:', error);
      return null;
    }
  }); 