import 'package:cloud_firestore/cloud_firestore.dart';

class MockKnowledgeData {
  static final List<Map<String, dynamic>> knowledgeDocuments = [
    // =========================================================================
    // DANH MỤC: help (Gộp từ help, account, shopping, payment, reviews, notifications, shipping, support, nttpoint)
    // =========================================================================
    {
      'title': 'Tổng quan về Student Market NTTU',
      'content': '''
Student Market NTTU là sàn thương mại điện tử dành riêng cho sinh viên Trường Đại học Nguyễn Tất Thành. Nền tảng được phát triển để tạo môi trường mua bán, trao đổi đồ dùng học tập, cá nhân... thuận tiện, an toàn và hiệu quả trong khuôn viên trường.

Ứng dụng được xây dựng trên nền tảng **Flutter**, sử dụng **Firebase** (Authentication, Firestore, Storage, Functions, FCM) cho backend và tích hợp các công nghệ **AI** tiên tiến như **Google Gemini AI** và **Pinecone Vector Database** để mang lại trải nghiệm tìm kiếm thông minh và hỗ trợ người dùng tốt nhất.

Các tính năng chính bao gồm:
- Quản lý người dùng (Đăng ký, Đăng nhập, Hồ sơ, Bảo mật)
- Quản lý sản phẩm (Đăng bán/tặng, Kiểm duyệt, Tìm kiếm, Quản lý bán hàng)
- Mua sắm (Duyệt, Tìm kiếm, Giỏ hàng, Thanh toán, Đơn hàng)
- Hệ thống điểm thưởng NTT Point
- Trò chuyện và hỗ trợ (Chat, Chatbot AI, Cơ sở kiến thức, Giải quyết tranh chấp)
- Đánh giá và xếp hạng người dùng/sản phẩm
- Hệ thống thông báo đa dạng
- Dịch vụ vận chuyển nội bộ trường và đối tác

Ứng dụng có cấu trúc rõ ràng với các màn hình chính như Trang chủ, Khám phá, Thông báo, Tin nhắn và Tài khoản, dễ dàng điều hướng qua TabBar ở cuối màn hình.
''',
      'keywords': ['tổng quan', 'giới thiệu', 'student market', 'nttu', 'nền tảng', 'ứng dụng', 'firebase', 'flutter', 'AI'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 0,
    },
    {
      'title': 'Tính năng chatbot trợ lý ảo & AI',
      'content': '''
Student Market NTTU tích hợp trợ lý ảo thông minh sử dụng **Google Gemini AI** và kiến trúc **RAG (Retrieval Augmented Generation)** để hỗ trợ người dùng:

1. Tính năng chính:
    - **Trả lời câu hỏi thường gặp**: Dựa trên Cơ sở kiến thức (Knowledge Base) được lưu trữ và quản lý trong Firestore collection `knowledgeBase`.
    - **Tìm kiếm sản phẩm thông minh**: Phân tích yêu cầu ngôn ngữ tự nhiên, trích xuất thuộc tính và sử dụng **Vector search (Pinecone)** kết hợp tìm kiếm từ khóa để tìm sản phẩm phù hợp nhất.
    - **Gợi ý sản phẩm phù hợp**: Dựa trên ngữ cảnh hội thoại và lịch sử tương tác (`activity_logs`).
    - **Giải thích tính năng/quy trình**: Cung cấp hướng dẫn chi tiết về các bước sử dụng ứng dụng, tương ứng với các luồng trong Sitemap.
    - **Cung cấp thông tin**: Ưu đãi, cập nhật mới, chính sách, quy định.
    - **Phân loại tin nhắn**: Nhận diện ý định của người dùng bằng Gemini AI qua 8 loại chính (chào hỏi, tạm biệt, tìm kiếm sản phẩm, trợ giúp, tài khoản, đơn hàng, đánh giá, trò chuyện).

2. Công nghệ cốt lõi:
    - **Google Gemini AI**: Xử lý ngôn ngữ tự nhiên (NLP), phân loại ý định, tạo nội dung thông minh.
    - **RAG**: Kết hợp truy xuất thông tin từ Cơ sở kiến thức (Firestore collection `knowledgeBase` & Pinecone Vector DB) với khả năng tạo nội dung của Gemini AI.
    - **Pinecone Vector Database**: Lưu trữ vector embedding (kích thước nhúng 768-d) của kiến thức và sản phẩm để tìm kiếm ngữ nghĩa bằng thuật toán cosine similarity.
    - **Firebase Functions**: Xử lý các tác vụ backend cho chatbot (gọi API Gemini, truy vấn Pinecone, xử lý dữ liệu).

3. Cách sử dụng:
    - Truy cập "Trợ lý ảo" từ tab "Tin nhắn" hoặc biểu tượng ở góc dưới màn hình chính.
    - Nhập câu hỏi/yêu cầu bằng tiếng Việt tự nhiên. Chatbot có thể hiểu cả từ lóng, từ viết tắt phổ biến.
    - Lịch sử trò chuyện được lưu trong Firestore subcollection `messages` thuộc `chats` để duy trì ngữ cảnh.
    - Giao diện chatbot hỗ trợ hiển thị rich content như carousel sản phẩm khi tìm kiếm.

4. Cải tiến liên tục:
    - Hệ thống học hỏi và cải thiện dựa trên phản hồi người dùng và dữ liệu tương tác (`activity_logs`, đánh giá hữu ích câu trả lời).
    - Định kỳ cập nhật Cơ sở kiến thức (`knowledgeBase`).

Liên hệ bộ phận hỗ trợ (mục Tài khoản > Cài đặt > Trợ giúp & Hỗ trợ) nếu chatbot không giải quyết được vấn đề của bạn.
''',
      'keywords': ['chatbot', 'trợ lý ảo', 'AI', 'trí tuệ nhân tạo', 'hỏi đáp tự động', 'hỗ trợ', 'Gemini', 'RAG', 'Pinecone', 'tìm kiếm thông minh', 'knowledge base'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 1,
    },
    {
      'title': 'Công nghệ RAG và Tìm kiếm Vector trong ứng dụng',
      'content': '''
Student Market NTTU sử dụng công nghệ **RAG (Retrieval Augmented Generation)** và **Tìm kiếm Vector (Vector Search)** để nâng cao trải nghiệm:

1. RAG là gì?
    - Công nghệ kết hợp Truy xuất (Retrieval) thông tin liên quan từ cơ sở dữ liệu (Knowledge Base, danh sách sản phẩm) và Tạo nội dung (Generation) câu trả lời bởi mô hình ngôn ngữ lớn (Google Gemini AI).
    - Đảm bảo câu trả lời chính xác, dựa trên dữ liệu có sẵn và phù hợp ngữ cảnh.

2. Tìm kiếm Vector (Vector Search):
    - Biểu diễn các mục (sản phẩm, câu hỏi kiến thức) dưới dạng vector số học (embedding) trong không gian đa chiều sử dụng các mô hình nhúng (embedding models).
    - Lưu trữ các vector này trong **Pinecone Vector Database**.
    - Khi người dùng tìm kiếm hoặc đặt câu hỏi, câu hỏi đó cũng được chuyển thành vector.
    - Hệ thống tìm kiếm các vector gần nhất (sử dụng cosine similarity) trong Pinecone.
    - Kết quả tìm kiếm vector giúp hiểu ý định (semantic search) thay vì chỉ dựa trên từ khóa trùng khớp.

3. Ứng dụng trong Student Market NTTU:
    - **Chatbot AI**: Truy xuất các mục kiến thức liên quan từ `knowledgeBase` và sản phẩm từ `products` để trả lời câu hỏi.
    - **Tìm kiếm sản phẩm**: Cho phép tìm kiếm bằng ngôn ngữ tự nhiên ("laptop cũ dưới 5 triệu cho sinh viên") bằng cách chuyển đổi câu hỏi thành vector và tìm sản phẩm có vector tương đồng.
    - **Gợi ý sản phẩm tương tự**: Tìm các sản phẩm khác có vector embedding gần với sản phẩm đang xem.

4. Lợi ích:
    - Kết quả tìm kiếm và câu trả lời chính xác, liên quan và thông minh hơn.
    - Hiểu được ngữ cảnh và ý định phức tạp của người dùng.
    - Khả năng tìm kiếm dựa trên hình ảnh (kết hợp Computer Vision để tạo vector).
    - Cải thiện hiệu quả hỗ trợ người dùng và tăng khả năng tìm thấy sản phẩm mong muốn.
''',
      'keywords': ['RAG', 'retrieval augmented generation', 'tìm kiếm thông minh', 'truy xuất tăng cường', 'AI', 'cơ sở tri thức', 'vector search', 'pinecone', 'embedding', 'tìm kiếm ngữ nghĩa'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 2,
    },
    {
      'title': 'Đăng sản phẩm tặng miễn phí',
      'content': '''
Để đăng một sản phẩm bạn muốn TẶNG MIỄN PHÍ trên Student Market NTTU, bạn thực hiện theo các bước sau:

1. Bắt đầu đăng sản phẩm:
    Đăng nhập vào tài khoản của bạn.
    Tìm nút hoặc mục cho phép bạn tạo bài đăng sản phẩm mới (thường là biểu tượng "+" ở thanh TabBar).
2. Điền thông tin sản phẩm tặng:
    Tải lên ảnh minh họa cho món đồ bạn muốn tặng (tối đa 10 ảnh).
    Nhập tên sản phẩm (ví dụ: "Sách giáo trình giải tích", "Quần áo cũ size M").
    Viết mô tả chi tiết về tình trạng sản phẩm, lý do muốn tặng, hoặc bất kỳ lưu ý nào khác (có thể dùng rich text editor).
    Chọn **Danh mục**: Từ danh sách các danh mục có sẵn (`categories`), hãy chọn danh mục "**Đồ tặng**". Hệ thống cũng có thể gợi ý danh mục dựa trên mô tả của bạn.
    Thiết lập giá: Đối với sản phẩm tặng, bạn sẽ đặt giá là **0 VND** hoặc chọn tùy chọn "**Miễn phí**".
    Điền các thông tin tùy chọn khác (nếu có) như vị trí bán hàng (có thể tự động dựa trên GPS hoặc địa chỉ người dùng).
3. Hoàn tất đăng bài:
    Xem lại toàn bộ thông tin đã nhập.
    Nhấn nút "Đăng sản phẩm" để hoàn thành.

Sản phẩm tặng của bạn sẽ được đưa lên sàn và hiển thị ở mục "Đồ tặng" hoặc khi người dùng tìm kiếm các sản phẩm miễn phí. Sản phẩm sẽ trải qua quy trình **kiểm duyệt** trước khi hiển thị. Khi đăng sản phẩm tặng thành công, bạn sẽ nhận được **+10 NTT Point** vào tài khoản của mình.
''',
      'keywords': ['đăng sản phẩm tặng', 'tặng đồ', 'cho đồ', 'miễn phí', 'đăng bài miễn phí', 'đồ tặng', 'cách đăng tặng đồ', 'cho tặng', 'NTT Point'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 3,
    },
    {
      'title': 'Quy định đăng sản phẩm (Bán & Tặng)',
      'content': '''
Khi đăng sản phẩm trên Student Market NTTU (cả bán và tặng), vui lòng tuân thủ các quy định sau, được kiểm soát bởi hệ thống **kiểm duyệt tự động (Firebase Functions, Google Cloud Vision API)** và **kiểm duyệt thủ công**:

1. Sản phẩm được phép:
    - Sách, tài liệu học tập.
    - Thiết bị điện tử, đồ dùng cá nhân, vật dụng ký túc xá đã qua sử dụng còn tốt.
    - Quần áo, giày dép, đồ thể thao, nhạc cụ.
    - Dịch vụ gia sư, hỗ trợ học tập.
    - Xe đạp, xe điện.
    - Thực phẩm đóng gói chưa mở, chưa hết hạn.

2. Sản phẩm bị cấm:
    - Đồ uống có cồn, thuốc lá, chất gây nghiện.
    - Thuốc, vật phẩm y tế không được phép.
    - Vũ khí, vật liệu nguy hiểm.
    - Hàng giả, hàng nhái, vi phạm bản quyền.
    - Nội dung khiêu dâm, không lành mạnh.
    - Tài khoản số, dịch vụ tài chính phi pháp.
    - Thực phẩm tươi sống, đã chế biến.
    - Động vật hoang dã.
    - Sản phẩm vi phạm pháp luật Việt Nam.
    - Dịch vụ làm bài hộ, viết thuê luận văn.

3. Yêu cầu về hình ảnh (`Firebase Storage`):
    - Tối thiểu 3, tối đa 10 hình ảnh/video ngắn (max 30s).
    - Ảnh thật của sản phẩm, rõ nét, không dùng ảnh mạng.
    - Không chèn watermark cá nhân.
    - Không chứa nội dung cấm. Kích thước tối thiểu 600x600px, dung lượng max 5MB/tệp. Tự động nén và tối ưu.

4. Yêu cầu về mô tả (sử dụng rich text editor):
    - Trung thực, đầy đủ thông tin, nêu rõ khuyết điểm (nếu có).
    - Không quảng cáo sai sự thật.
    - Không chứa thông tin cá nhân (SĐT, địa chỉ cụ thể).
    - Độ dài tối thiểu 100 ký tự.

5. Quy định về giá:
    - Giá hợp lý, phù hợp thị trường.
    - Không đăng giá ảo. Phí phụ phải nêu rõ.
    - Giá tối thiểu 5,000đ, tối đa 50,000,000đ.
    - Sản phẩm tặng đặt giá 0 VND.

6. Quy trình kiểm duyệt (`moderationResults` collection):
    - AI kiểm tra ban đầu (2-6 giờ) dựa trên Vision API và từ khóa cấm.
    - Kiểm duyệt thủ công (đội ngũ admin) xem xét trong 24 giờ làm việc.
    - **Điểm uy tín (NTT Credit)** của người bán ảnh hưởng đến thời gian và mức độ kiểm duyệt.
    - Sản phẩm được duyệt sẽ có trạng thái "Đã duyệt" trong `products` collection.
    - Sản phẩm vi phạm bị từ chối với lý do cụ thể. Tài khoản vi phạm nhiều lần có thể bị hạn chế/khóa.
    - Kết quả kiểm duyệt được lưu trong `moderationResults`.

Lưu ý: Việc tuân thủ quy định giúp bạn tăng **điểm uy tín** và xây dựng shop bán hàng đáng tin cậy.
''',
      'keywords': ['quy định', 'điều kiện', 'cấm', 'chính sách', 'kiểm duyệt', 'không được phép', 'quy tắc', 'hướng dẫn', 'đăng bán', 'đăng tặng', 'moderation'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 4,
    },
    {
      'title': 'Quản lý và chỉnh sửa sản phẩm đã đăng',
      'content': '''
Bạn có thể quản lý và chỉnh sửa sản phẩm đã đăng trên Student Market NTTU thông qua mục **Tài khoản > Sản phẩm đã đăng**. Thông tin sản phẩm được lưu trong Firestore collection `products`.

1. Truy cập quản lý sản phẩm:
    - Đăng nhập > Chọn tab "Tài khoản" > Chọn "Sản phẩm đã đăng".
    - Danh sách sản phẩm của bạn sẽ hiển thị với các trạng thái.

2. Các trạng thái sản phẩm (`products` collection):
    - **Đang xử lý**: Đang chờ kiểm duyệt.
    - **Đã duyệt**: Đã được duyệt và hiển thị công khai.
    - **Bị từ chối**: Không được duyệt (xem lý do trong `moderationResults`).
    - **Đang bán**: Đã duyệt và đang hiển thị.
    - **Đã bán**: Sản phẩm đã được bán thành công qua đơn hàng (`orders`) hoặc bạn tự đánh dấu.
    - **Đã ẩn**: Bạn tạm ẩn sản phẩm.
    - **Hết hạn**: Đã quá thời gian hiển thị (mặc định 30 ngày, tự động gia hạn trừ khi hết hàng).

3. Chỉnh sửa thông tin sản phẩm:
    - Chọn sản phẩm cần sửa > Nhấn "Chỉnh sửa".
    - Cập nhật: Ảnh/video, tiêu đề, mô tả, giá, số lượng, tình trạng, danh mục, tag...
    - Nhấn "Lưu thay đổi".
    - Lưu ý: Một số thay đổi lớn có thể kích hoạt kiểm duyệt lại.

4. Quản lý trạng thái sản phẩm:
    - **Tạm ẩn/Hiển thị lại**: Dừng hoặc tiếp tục hiển thị sản phẩm.
    - **Đánh dấu đã bán**: Cập nhật trạng thái khi bán ngoài ứng dụng.
    - **Xóa sản phẩm**: Xóa vĩnh viễn khỏi `products` (không thể khôi phục).
    - **Gia hạn hiển thị**: Tự động hoặc thủ công gia hạn thêm 30 ngày.

5. Tối ưu hiển thị (Tính phí):
    - **Đẩy tin**: Tăng vị trí trong kết quả tìm kiếm.
    - **Gắn nhãn nổi bật**: Thêm các badge "Hot", "Giảm giá".
    - **Quảng cáo sản phẩm**: Hiển thị ở vị trí đặc biệt.

6. Theo dõi hiệu suất (Dashboard người bán):
    - Xem lượt xem, lượt yêu thích, lượt chat hỏi mua.
    - Theo dõi số liệu thống kê trong mục "Sản phẩm đã đăng".
    - Nhận gợi ý cải thiện từ hệ thống.

7. Giải quyết sản phẩm bị từ chối:
    - Xem lý do trong `moderationResults`.
    - Chỉnh sửa sản phẩm theo gợi ý và gửi lại kiểm duyệt.
    - Liên hệ hỗ trợ nếu có thắc mắc.
''',
      'keywords': ['quản lý sản phẩm', 'chỉnh sửa sản phẩm', 'cập nhật sản phẩm', 'sửa thông tin', 'ẩn sản phẩm', 'xóa sản phẩm', 'trạng thái sản phẩm', 'đã bán', 'kiểm duyệt'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 5,
    },
    {
      'title': 'Cách đăng ký và xác thực tài khoản',
      'content': '''
Để đăng ký tài khoản mới trên Student Market NTTU và xác thực vai trò sinh viên:

1. Đăng ký tài khoản (`users` collection, `Firebase Authentication`):
    - Mở ứng dụng > Nhấn "Đăng ký" (từ màn hình đăng nhập).
    - Điền thông tin: Họ tên, Email (ưu tiên email trường @nttu.edu.vn), Mật khẩu (ít nhất 8 ký tự, có chữ hoa, thường, số - được mã hóa bằng **BCrypt**), Số điện thoại.
    - Chọn vai trò: Sinh viên NTTU hoặc Người dùng thông thường.
    - Chấp nhận Điều khoản & Chính sách.
    - Nhấn "Đăng ký".
    - **Xác thực email**: Kiểm tra hộp thư đến để nhấn vào liên kết xác nhận (bắt buộc để sử dụng tài khoản).

2. Xác thực tài khoản sinh viên (`users` collection):
    - Đăng nhập > Tab "Tài khoản" > Thông tin cá nhân > "Xác thực tài khoản sinh viên".
    - Điền thông tin sinh viên: Mã số SV, Khoa/Ngành, Năm học...
    - Tải lên giấy tờ chứng minh (Thẻ SV, biên lai học phí, bảng điểm, email @nttu.edu.vn - lưu trên `Firebase Storage`).
    - Nhấn "Gửi xác thực".
    - Chờ duyệt (thường 24-48 giờ làm việc). Trạng thái xác thực được lưu trong document người dùng.

3. Quyền lợi khi xác thực sinh viên:
    - Badge "Sinh viên NTTU".
    - Giảm 50% phí giao dịch/vận chuyển đối tác.
    - Ưu đãi đặc biệt cho sinh viên.
    - Ưu tiên hiển thị sản phẩm.
    - 500 NTT Point khởi đầu.
    - Khả năng giao hàng nội bộ trường (Campus Delivery).
    - Tham gia cộng đồng nội bộ.
    - Tỷ lệ quy đổi NTT Point tốt hơn.

4. Quản lý tài khoản:
    - Hoàn thành hồ sơ: ảnh đại diện, sở thích (`users` collection).
    - Quản lý địa chỉ giao hàng (`addresses` subcollection).
    - Cài đặt bảo mật (xác thực 2 yếu tố SMS - tùy chọn).

Lưu ý: Sinh viên đã xác thực có nhiều đặc quyền và lợi ích hơn trên nền tảng.
''',
      'keywords': ['đăng ký', 'tài khoản', 'đăng ký tài khoản', 'tạo tài khoản', 'xác thực sinh viên', 'sinh viên nttu', 'verification', 'firebase authentication', 'email verification', 'quyền lợi sinh viên'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 6, // Adjusted order to maintain sequence within the new combined category
    },
    {
      'title': 'Đăng nhập và khôi phục mật khẩu',
      'content': '''
Hướng dẫn đăng nhập và xử lý các vấn đề liên quan đến mật khẩu trên Student Market NTTU (`Firebase Authentication`):

1. Đăng nhập:
    - Mở ứng dụng > Nhập email và mật khẩu > Nhấn "Đăng nhập".
    - Hoặc sử dụng đăng nhập nhanh: Google (tích hợp Firebase Auth).
    - Tính năng "Ghi nhớ đăng nhập" sử dụng SharedPreferences.
    - Hệ thống phát hiện và ngăn chặn đăng nhập bất thường, có thể khóa tài khoản tạm thời sau nhiều lần thất bại.

2. Khôi phục mật khẩu (`Firebase Authentication`):
    - Trên màn hình đăng nhập > Nhấn "Quên mật khẩu".
    - Nhập email đăng ký.
    - Nhận liên kết khôi phục qua email (kiểm tra cả hộp thư spam).
    - Nhấn vào liên kết, tạo mật khẩu mới (tối thiểu 8 ký tự, bao gồm chữ hoa, số). Mật khẩu được mã hóa bằng BCrypt.

3. Bảo mật tài khoản (`users` collection):
    - Sử dụng mật khẩu mạnh, thay đổi định kỳ.
    - Bật xác thực hai yếu tố (2FA) qua SMS (tùy chọn) trong Cài đặt > Bảo mật.
    - Phiên đăng nhập tự động hết hạn sau 30 ngày.
    - Xem lịch sử đăng nhập và các thiết bị đang hoạt động trong Tài khoản > Cài đặt > Bảo mật.
    - Lưu trữ nhật ký hoạt động người dùng trong `activity_logs` subcollection.

Liên hệ hỗ trợ nếu bạn vẫn gặp vấn đề đăng nhập hoặc nghi ngờ tài khoản bị xâm nhập.
''',
      'keywords': ['đăng nhập', 'quên mật khẩu', 'khôi phục mật khẩu', 'mật khẩu', 'login', 'lấy lại mật khẩu', 'bảo mật', '2FA', 'firebase authentication'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 7, // Adjusted order
    },
    {
      'title': 'Quản lý hồ sơ người dùng và địa chỉ',
      'content': '''
Quản lý thông tin cá nhân và địa chỉ giao hàng của bạn trên Student Market NTTU thông qua mục **Tài khoản > Thông tin cá nhân**. Dữ liệu hồ sơ được lưu trong document người dùng tại Firestore collection `users`.

1. Truy cập hồ sơ:
    - Đăng nhập > Chọn tab "Tài khoản" > Chọn "Thông tin cá nhân".

2. Chỉnh sửa thông tin cá nhân:
    - Nhấn "Chỉnh sửa".
    - Cập nhật: Ảnh đại diện (lưu `Firebase Storage`), Họ tên, Bio, Thông tin liên hệ.
    - Cập nhật sở thích và mối quan tâm để nhận gợi ý sản phẩm tốt hơn.
    - Nhấn "Lưu".

3. Quản lý địa chỉ giao hàng (`addresses` subcollection):
    - Từ màn hình Thông tin cá nhân, chọn "Địa chỉ giao hàng".
    - Xem danh sách địa chỉ đã lưu trong `addresses` subcollection của document người dùng.
    - Thêm địa chỉ mới: Nhấn nút "+", điền thông tin địa chỉ, có thể tự động xác định vị trí qua GPS (cần cấp quyền). Hệ thống xác thực địa chỉ nằm trong phạm vi hỗ trợ.
    - Chỉnh sửa hoặc xóa địa chỉ hiện có.
    - Đặt địa chỉ mặc định để sử dụng trong quy trình thanh toán (`checkout_screen`).

4. Theo dõi hoạt động (`activity_logs` subcollection):
    - Hệ thống lưu trữ nhật ký hoạt động của bạn trong `activity_logs` subcollection.
    - Theo dõi sản phẩm đã xem gần đây (lưu trên thiết bị và đồng bộ khi online).
    - Tính năng "tiếp tục xem" sản phẩm.

Việc giữ thông tin hồ sơ chính xác giúp bạn xây dựng uy tín và nhận được trải nghiệm mua bán tốt nhất.
''',
      'keywords': ['hồ sơ', 'tài khoản', 'thông tin cá nhân', 'profile', 'chỉnh sửa hồ sơ', 'sở thích', 'địa chỉ', 'quản lý địa chỉ', 'activity logs', 'firebase firestore'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 8, // Adjusted order
    },
    {
      'title': 'Cách đăng bán sản phẩm mới',
      'content': '''
Để đăng sản phẩm bán trên Student Market NTTU, bạn thực hiện theo các bước sau:

1. Chuẩn bị: Ảnh/video sản phẩm (tối thiểu 3, tối đa 10 - chụp thật, rõ nét), thông tin chi tiết (tên, mô tả, thông số), giá bán, tình trạng sản phẩm.
2. Bắt đầu đăng: Đăng nhập > Chọn biểu tượng "+" ở thanh TabBar.
3. Điền thông tin (`products` collection, `Firebase Storage`):
    - Tải lên ảnh/video (hỗ trợ nén và tối ưu).
    - Nhập Tên sản phẩm (ngắn gọn, chứa từ khóa).
    - Chọn Danh mục (`categories` collection - đa cấp), hệ thống có thể gợi ý.
    - Nhập Giá bán (giá gốc và giá khuyến mãi nếu có).
    - Nhập Số lượng tồn kho.
    - Chọn Tình trạng (mới/đã qua sử dụng/còn bảo hành).
    - Điền Mô tả chi tiết (rich text editor, trung thực, nêu rõ khuyết điểm).
    - Thêm Thông số kỹ thuật (tùy chọn).
    - Thêm từ khóa/tag để tăng khả năng tìm kiếm.
    - Chọn Phương thức giao hàng (Campus Delivery, Trực tiếp, Đối tác...).
    - Chọn Phương thức thanh toán chấp nhận (COD, Chuyển khoản, Ví điện tử...).
    - Vị trí bán hàng có thể tự động dựa trên GPS hoặc địa chỉ mặc định.
4. Xem trước và đăng: Kiểm tra lại thông tin > Nhấn "Đăng sản phẩm".

Sau khi đăng, sản phẩm sẽ trải qua quy trình **kiểm duyệt** (`moderationResults`) trước khi hiển thị công khai trong `products` collection với trạng thái "Đã duyệt". Theo dõi trạng thái và hiệu suất sản phẩm trong mục Tài khoản > Sản phẩm đã đăng. Đảm bảo tuân thủ **Quy định đăng sản phẩm** để bài đăng được duyệt nhanh chóng.
''',
      'keywords': ['đăng bán', 'đăng sản phẩm', 'bán hàng', 'tạo sản phẩm', 'đăng tin', 'đăng bài', 'bán đồ', 'product listing', 'firebase storage', 'firebase firestore'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 9, // Adjusted order
    },
    {
      'title': 'Giỏ hàng thông minh',
      'content': '''
Giỏ hàng thông minh trên Student Market NTTU giúp bạn quản lý các sản phẩm muốn mua trước khi tiến hành thanh toán (`cart_screen`):

1. Cách hoạt động:
    - Nhấn "**Thêm vào giỏ hàng**" từ trang chi tiết sản phẩm.
    - Sản phẩm được lưu trữ tạm thời (local với SQLite) và đồng bộ với Firestore khi có mạng.
    - Tự động cập nhật giá và trạng thái tồn kho của sản phẩm trong giỏ hàng.
    - Kiểm tra tồn kho trước khi thêm sản phẩm vào giỏ.
    - Nếu bạn chưa đăng nhập, giỏ hàng sẽ được lưu tạm và khôi phục sau khi đăng nhập.

2. Quản lý giỏ hàng:
    - Truy cập Giỏ hàng từ tab "Tài khoản" hoặc biểu tượng giỏ hàng.
    - Xem danh sách các sản phẩm đã thêm.
    - Điều chỉnh số lượng sản phẩm.
    - Xóa sản phẩm khỏi giỏ hàng.
    - Chọn/bỏ chọn sản phẩm muốn thanh toán.
    - Tính toán tổng tiền các sản phẩm đã chọn.

3. Tính năng thông minh:
    - **Áp dụng NTT Point**: Xem số NTT Point khả dụng và ước tính số tiền giảm giá có thể áp dụng ngay trong giỏ hàng.
    - **Đề xuất sản phẩm bổ sung**: Gợi ý các sản phẩm liên quan hoặc phù hợp với các mặt hàng đã có trong giỏ.

4. Tiến hành thanh toán:
    - Chọn các sản phẩm muốn mua trong giỏ hàng.
    - Nhấn nút "**Thanh toán**" để chuyển đến màn hình thanh toán (`checkout_screen`).
''',
      'keywords': ['giỏ hàng', 'cart', 'thêm vào giỏ', 'quản lý giỏ hàng', 'ntt point', 'mua sắm'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 10, // Adjusted order
    },
    {
      'title': 'Quy trình thanh toán và đặt hàng',
      'content': '''
Quy trình thanh toán trên Student Market NTTU được thực hiện trên màn hình thanh toán một trang (`checkout_screen`), và thông tin đơn hàng được lưu trong Firestore collection `orders`:

1. Chuẩn bị: Đảm bảo các sản phẩm cần mua đã có trong giỏ hàng và được chọn để thanh toán.
2. Truy cập màn hình thanh toán: Nhấn nút "Thanh toán" từ Giỏ hàng hoặc "Mua ngay" từ chi tiết sản phẩm.
3. Điền thông tin đặt hàng:
    - **Địa chỉ giao hàng**: Chọn địa chỉ đã lưu từ `addresses` subcollection hoặc thêm địa chỉ mới.
    - **Phương thức vận chuyển**: Chọn phương thức phù hợp (Campus Delivery, Trực tiếp, Đối tác...). Hệ thống tính phí giao hàng dựa trên khoảng cách và phương thức.
    - **Phương thức thanh toán**: Chọn từ các phương thức hỗ trợ (COD, Chuyển khoản, Ví điện tử, NTT Credit...).
    - **Áp dụng NTT Point**: Sử dụng thanh trượt để chọn số NTT Point muốn quy đổi giảm giá (10 điểm = 10.000 VNĐ, tối đa 50% giá trị đơn hàng). Hệ thống sẽ tự động tính toán số tiền được giảm.
    - **Ghi chú**: Thêm ghi chú cho người bán hoặc shipper (nếu có).
4. Xem lại đơn hàng: Kiểm tra lại thông tin sản phẩm, địa chỉ, phí vận chuyển, số tiền giảm giá từ NTT Point và tổng thanh toán.
5. Xác nhận đơn hàng: Nhấn nút "**Xác nhận đơn hàng**" hoặc "**Đặt hàng**".
    - Hệ thống tạo một document đơn hàng mới trong collection `orders` với mã đơn hàng duy nhất (ví dụ: OM-YYMMDD-XXXXX).
    - Kiểm tra tồn kho sản phẩm và khóa sản phẩm lại.
    - Xử lý thanh toán theo phương thức đã chọn.

6. Theo dõi đơn hàng (`order_history_screen`, `orders` collection):
    - Sau khi đặt hàng thành công, bạn sẽ được chuyển đến màn hình chi tiết đơn hàng hoặc có thể xem trong mục **Tài khoản > Đơn hàng của tôi**.
    - Theo dõi trạng thái đơn hàng theo thời gian thực (Đang xử lý, Đã xác nhận, Đang giao...).
    - Nhận thông báo đẩy (`notifications`) về các cập nhật trạng thái quan trọng.
    - Có thể theo dõi vị trí shipper trên bản đồ nếu sử dụng dịch vụ giao hàng đối tác hoặc nội bộ trường (yêu cầu shipper đồng ý chia sẻ vị trí).
    - Lịch sử thay đổi trạng thái đơn hàng được lưu trong `status_updates` subcollection của đơn hàng.

Lưu ý: Mọi thông tin đơn hàng được lưu lại để bạn dễ dàng theo dõi và quản lý.
''',
      'keywords': ['thanh toán', 'đặt hàng', 'quy trình mua', 'checkout', 'giỏ hàng', 'địa chỉ giao hàng', 'phương thức thanh toán', 'ntt point', 'xác nhận đơn hàng', 'theo dõi đơn hàng', 'orders', 'shipping'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 11, // Adjusted order
    },
    {
      'title': 'Quản lý Đơn hàng của tôi',
      'content': '''
Bạn có thể quản lý tất cả các đơn hàng đã đặt trên Student Market NTTU tại mục **Tài khoản > Đơn hàng của tôi** (`order_history_screen`). Thông tin đơn hàng được lưu trữ trong Firestore collection `orders`.

1. Xem danh sách đơn hàng:
    - Truy cập Tài khoản > Đơn hàng của tôi.
    - Danh sách các đơn hàng bạn đã đặt sẽ hiển thị.
    - Có thể lọc đơn hàng theo trạng thái (Đang xử lý, Đang giao, Đã nhận, Đã hủy...) và khoảng thời gian.

2. Chi tiết đơn hàng:
    - Nhấn vào một đơn hàng bất kỳ để xem chi tiết.
    - Thông tin chi tiết bao gồm: Mã đơn hàng (ví dụ: OM-YYMMDD-XXXXX), danh sách sản phẩm, giá, phí vận chuyển, số tiền giảm từ NTT Point, tổng thanh toán, địa chỉ nhận hàng, phương thức thanh toán.
    - **Timeline trạng thái**: Hiển thị lịch sử thay đổi trạng thái của đơn hàng một cách trực quan (lấy từ `status_updates` subcollection).

3. Các hành động với đơn hàng:
    - **Theo dõi giao hàng**: Nếu đơn hàng đang được giao, bạn có thể xem thông tin shipper và vị trí (nếu có).
    - **Xác nhận đã nhận hàng**: Khi bạn đã nhận được sản phẩm và kiểm tra kỹ, hãy nhấn nút "Đã nhận hàng" trong ứng dụng. Thao tác này xác nhận giao dịch thành công và giải ngân tiền cho người bán (trừ COD).
    - **Hủy đơn hàng**: Bạn có thể hủy đơn hàng trong một khoảng thời gian giới hạn (thường trước khi người bán bàn giao cho shipper). Xem thêm về **Chính sách hủy đơn**.
    - **Báo cáo vấn đề**: Nếu sản phẩm có vấn đề (lỗi, không đúng mô tả...), bạn cần báo cáo trong thời gian quy định để yêu cầu hỗ trợ giải quyết tranh chấp hoặc đổi trả/hoàn tiền.
    - **Đặt lại đơn hàng**: Có thể nhanh chóng tạo một đơn hàng mới với các sản phẩm tương tự đơn hàng cũ.
    - **Xem hóa đơn**: Tải hóa đơn điện tử định dạng PDF cho đơn hàng đã hoàn thành.

4. Hoàn thành đơn hàng:
    - Sau khi nhấn "Đã nhận hàng", đơn hàng sẽ chuyển sang trạng thái "Hoàn thành".
    - Bạn sẽ được nhắc **đánh giá sản phẩm và người bán**. Việc đánh giá giúp cộng đồng và nhận thêm **NTT Point**.

Việc theo dõi đơn hàng giúp bạn luôn nắm bắt được quá trình giao dịch của mình.
''',
      'keywords': ['đơn hàng', 'quản lý đơn hàng', 'lịch sử đơn hàng', 'theo dõi đơn hàng', 'trạng thái đơn hàng', 'hủy đơn', 'xác nhận đơn hàng', 'đã nhận hàng', 'order history', 'orders', 'firebase firestore'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 12, // Adjusted order
    },
    {
      'title': 'Phương thức thanh toán được hỗ trợ',
      'content': '''
Student Market NTTU hỗ trợ nhiều phương thức thanh toán linh hoạt trong quy trình thanh toán (`checkout_screen`):

1. Thanh toán khi nhận hàng (COD):
    - Trả tiền mặt khi nhận hàng.
    - Áp dụng cho các đơn hàng đủ điều kiện (giá trị, điểm uy tín người bán...).
    - Cần xác nhận giao hàng bằng **mã OTP** hoặc **quét mã QR** khi nhận hàng.
    - Tiền được giữ trong hệ thống đảm bảo cho đến khi giao dịch hoàn tất.

2. Chuyển khoản ngân hàng:
    - Chuyển khoản đến tài khoản trung gian của Student Market NTTU.
    - An toàn với hệ thống đảm bảo giao dịch.

3. Ví điện tử:
    - Thanh toán nhanh chóng qua các ví phổ biến: MoMo, VNPay, ZaloPay, ShopeePay... (tích hợp API).

4. Thanh toán bằng NTT Point:
    - Sử dụng điểm thưởng tích lũy để giảm giá trực tiếp trên đơn hàng.
    - **10 NTT Point = 1.000 VNĐ**.
    - Có thể dùng tối đa **50% giá trị đơn hàng** bằng điểm.
    - Hệ thống ưu tiên sử dụng điểm sắp hết hạn.
    - Áp dụng điểm bằng thanh trượt trên màn hình thanh toán.

Quy trình thanh toán an toàn:
- Tiền (trừ COD) được giữ trong tài khoản đảm bảo của Student Market NTTU.
- Chỉ giải ngân cho người bán sau khi bạn nhấn "**Đã nhận hàng**" hoặc sau thời gian chờ quy định nếu không có khiếu nại.
- Thời gian đảm bảo: 24 giờ sau khi người mua xác nhận đã nhận hàng.
- Nếu có tranh chấp, tiền được giữ lại cho đến khi giải quyết xong.
- Hệ thống tự động hoàn tiền nếu đơn hàng bị hủy.

Bảo mật thanh toán: Mã hóa dữ liệu, xác thực hai yếu tố, giám sát giao dịch bất thường. Chỉ thanh toán trong ứng dụng, không chuyển khoản trực tiếp cho người bán.
''',
      'keywords': ['thanh toán', 'payment', 'phương thức thanh toán', 'COD', 'chuyển khoản', 'ví điện tử', 'ntt point', 'đảm bảo thanh toán', 'quy trình thanh toán'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 13, // Adjusted order
    },
    {
      'title': 'NTT Point - Điểm thưởng và quy đổi',
      'content': '''
NTT Point là hệ thống điểm thưởng dành cho người dùng Student Market NTTU, giúp bạn tiết kiệm khi mua sắm. Thông tin điểm và giao dịch được quản lý trong Firestore collection `nttPointTransactions` và document người dùng (`users`).

1. Cơ chế hoạt động:
    - Mỗi điểm có thời hạn sử dụng **6 tháng** kể từ ngày nhận.
    - Lịch sử giao dịch điểm được lưu chi tiết trong `nttPointTransactions`.

2. Cách kiếm NTT Point:
    - **Đăng sản phẩm "Đồ tặng"**: +10 NTT Point/sản phẩm.
    - **Hoàn thành đơn hàng thành công**: Thưởng điểm dựa trên giá trị đơn hàng (ví dụ: 10,000đ chi tiêu = 1 NTT Point).
    - **Giới thiệu bạn bè**: +5 điểm cho mỗi người dùng mới đăng ký thành công qua link giới thiệu.
    - **Hoàn thành khảo sát/đánh giá**: Tham gia các hoạt động trong ứng dụng.
    - **Người dùng tích cực**: Thưởng điểm hàng tháng cho những người dùng có hoạt động sôi nổi (đăng bài, tương tác, mua bán...).
    - **Chương trình khuyến mãi**: Các sự kiện đặc biệt có thưởng NTT Point.

3. Sử dụng NTT Point:
    - **Giảm giá khi mua hàng**: Sử dụng điểm trên màn hình thanh toán (`checkout_screen`).
    - Tỷ lệ quy đổi: **10 NTT Point = 1.000 VNĐ**.
    - Có thể dùng tối đa **50% giá trị đơn hàng** để thanh toán bằng điểm.
    - Hệ thống tự động ưu tiên sử dụng các điểm sắp hết hạn trước.

4. Quản lý điểm hết hạn:
    - Hệ thống theo dõi và thông báo cho bạn khi có điểm sắp hết hạn (trước 15 ngày).
    - Điểm hết hạn sẽ tự động bị trừ khỏi số dư.

5. Xem lịch sử giao dịch điểm (`ntt_point_history_screen`, `nttPointTransactions`):
    - Truy cập Tài khoản > NTT Point.
    - Xem số dư điểm hiện tại và các điểm sắp hết hạn.
    - Xem chi tiết lịch sử giao dịch: kiếm được, đã dùng, bị trừ, hoàn lại, hết hạn.
    - Có thể lọc lịch sử theo loại giao dịch hoặc thời gian.

Lưu ý: Tích cực hoạt động trên Student Market NTTU để tích lũy NTT Point và tiết kiệm chi phí mua sắm nhé!
''',
      'keywords': ['ntt point', 'điểm thưởng', 'kiếm điểm', 'sử dụng điểm', 'quy đổi điểm', 'điểm hết hạn', 'lịch sử điểm', 'nttpointtransactions'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 14, // Adjusted order
    },
    {
      'title': 'Giải quyết vấn đề thanh toán',
      'content': '''
Khi gặp các vấn đề liên quan đến thanh toán trên Student Market NTTU, bạn có thể xử lý theo các bước sau:

1. Thanh toán không thành công:
    - Kiểm tra lại thông tin thanh toán đã nhập (số thẻ, ngày hết hạn, mã CVV...).
    - Kiểm tra số dư tài khoản ngân hàng/ví điện tử.
    - Kiểm tra hạn mức giao dịch.
    - Đảm bảo kết nối mạng ổn định.
    - Thử lại sau ít phút hoặc sử dụng phương thức thanh toán khác.
    - Liên hệ ngân hàng/ví điện tử nếu vấn đề tiếp diễn.

2. Tiền đã trừ nhưng đơn hàng chưa xác nhận:
    - Đừng lo lắng, đôi khi có độ trễ trong việc cập nhật trạng thái.
    - Kiểm tra email và thông báo ứng dụng (`notifications`) trong vòng vài phút đến 24 giờ.
    - Kiểm tra lịch sử giao dịch trong tài khoản ngân hàng/ví điện tử để xác nhận tiền đã bị trừ.
    - Chụp lại biên lai hoặc thông báo giao dịch thành công.
    - **Liên hệ bộ phận hỗ trợ thanh toán**: Cung cấp mã đơn hàng (nếu có), thời gian giao dịch, số tiền, phương thức thanh toán và ảnh chụp biên lai. Yêu cầu hỗ trợ qua mục Tài khoản > Cài đặt > Trợ giúp & Hỗ trợ.

3. Hoàn tiền:
    - Thời gian hoàn tiền tùy thuộc vào phương thức thanh toán ban đầu và ngân hàng/ví điện tử (ví dụ: Ví điện tử 1-3 ngày, Thẻ 7-14 ngày, Chuyển khoản 3-5 ngày). NTT Point được hoàn lại ngay lập tức.
    - Kiểm tra trạng thái hoàn tiền trong mục Lịch sử giao dịch thanh toán hoặc Lịch sử đơn hàng.
    - Nếu quá thời gian quy định mà chưa nhận được tiền, liên hệ hỗ trợ thanh toán với mã giao dịch hoàn tiền.

4. Vấn đề với NTT Point:
    - **Không được cộng điểm**: Điểm thường cập nhật sau 24 giờ hoàn thành đơn hàng. Kiểm tra lịch sử điểm (`nttPointTransactions`). Nếu chưa nhận được, liên hệ hỗ trợ.
    - **Không sử dụng được điểm**: Kiểm tra số dư điểm, đảm bảo đủ điểm và đơn hàng đủ điều kiện áp dụng điểm.
    - **Điểm hết hạn sớm**: Kiểm tra thời hạn điểm trong mục NTT Point.

5. Phòng tránh lừa đảo:
    - **Chỉ thanh toán trong ứng dụng**: TUYỆT ĐỐI không chuyển khoản trực tiếp cho người bán hoặc thực hiện giao dịch ngoài nền tảng Student Market NTTU.
    - Không chia sẻ thông tin đăng nhập, mã OTP cho bất kỳ ai.
    - Cảnh giác với các liên kết thanh toán lạ qua SMS/email.
    - Báo cáo ngay yêu cầu thanh toán đáng ngờ cho đội ngũ hỗ trợ.

Liên hệ bộ phận hỗ trợ qua các kênh được liệt kê trong mục "Cách liên hệ bộ phận hỗ trợ" nếu bạn cần trợ giúp về thanh toán.
''',
      'keywords': ['lỗi thanh toán', 'hoàn tiền', 'tiền bị trừ', 'thanh toán thất bại', 'sự cố thanh toán', 'xử lý thanh toán', 'lừa đảo thanh toán', 'ntt point', 'hỗ trợ thanh toán'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 15, // Adjusted order
    },
    {
      'title': 'Hệ thống Đánh giá sản phẩm và Người bán',
      'content': '''
Student Market NTTU có hệ thống đánh giá để người mua chia sẻ trải nghiệm và người bán xây dựng uy tín. Dữ liệu đánh giá được lưu trong `reviews` subcollection của sản phẩm và ảnh hưởng đến điểm uy tín của người bán trong collection `users`.

1. Đánh giá sản phẩm (`reviews` subcollection):
    - Sau khi hoàn thành đơn hàng (nhấn "Đã nhận hàng"), bạn có thể đánh giá sản phẩm.
    - Đánh giá bao gồm: Số sao (từ 1 đến 5), nhận xét văn bản, và có thể đính kèm hình ảnh (tối đa 3 ảnh, lưu `Firebase Storage`).
    - Nội dung đánh giá được kiểm duyệt tự động.
    - Đánh giá này hiển thị trên trang chi tiết sản phẩm và ảnh hưởng đến điểm sao trung bình của sản phẩm.

2. Xếp hạng người bán (NTT Credit):
    - Người bán được xếp hạng dựa trên điểm uy tín (NTT Credit) tích lũy qua các giao dịch và đánh giá.
    - Điểm uy tín được tính tự động dựa trên: Hoàn thành đơn hàng, giao đúng hẹn, nhận đánh giá tốt, phản hồi tin nhắn nhanh, tuân thủ quy định... (cộng điểm) và Hủy đơn, giao trễ, sản phẩm không đúng mô tả, nhận đánh giá xấu, vi phạm quy định... (trừ điểm).
    - Hệ thống cấp bậc người dùng (Mới, Đồng, Bạc, Vàng, Kim cương) dựa trên điểm uy tín.
    - Điểm uy tín và cấp bậc hiển thị trên hồ sơ người bán và trong trang chi tiết sản phẩm.
    - Điểm uy tín cao giúp người bán được ưu tiên hiển thị sản phẩm và có các đặc quyền khác.

3. Hiển thị đánh giá:
    - Trên trang chi tiết sản phẩm (`product_detail_screen`).
    - Trên hồ sơ người bán (thống kê đánh giá và điểm uy tín).
    - Có thể lọc đánh giá theo số sao, có ảnh...

4. Trả lời đánh giá:
    - Người bán có thể trả lời các đánh giá về sản phẩm của mình. Phản hồi hiển thị ngay dưới đánh giá gốc.

5. Nhắc nhở đánh giá:
    - Hệ thống gửi thông báo tự động (qua app và email) sau khi bạn nhận hàng để nhắc đánh giá.
    - Đánh giá sản phẩm giúp bạn nhận thêm **NTT Point**.

Lưu ý: Đánh giá trung thực giúp cộng đồng mua sắm an toàn hơn.
''',
      'keywords': ['đánh giá', 'xếp hạng', 'review', 'rating', 'ntt credit', 'điểm uy tín', 'đánh giá sản phẩm', 'đánh giá người bán', 'firebase firestore', 'reviews'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 16, // Adjusted order
    },
    {
      'title': 'Quản lý Thông báo trong ứng dụng',
      'content': '''
Hệ thống thông báo giúp bạn cập nhật các hoạt động quan trọng trên Student Market NTTU. Thông báo được gửi qua **Firebase Cloud Messaging (FCM)** và lưu trữ trong Firestore collection `notifications`.

1. Kiến trúc thông báo:
    - Sử dụng FCM để gửi thông báo đẩy (push notification) đa nền tảng (Android, iOS).
    - Lưu trữ token thiết bị của bạn trong `deviceTokens` collection.
    - Thông báo được lưu lại trong `notifications` collection.
    - Hỗ trợ thông báo cục bộ (local notification) cho các sự kiện trong ứng dụng.

2. Các loại thông báo chính:
    - **Đơn hàng**: Cập nhật trạng thái đơn hàng (`orders` collection) - Đã đặt, Đã xác nhận, Đang giao, Đã nhận, Đã hủy...
    - **Tin nhắn**: Thông báo khi có tin nhắn mới trong cuộc trò chuyện (`chats` collection).
    - **Sản phẩm**: Trạng thái kiểm duyệt sản phẩm (`moderationResults`), sản phẩm yêu thích thay đổi giá (`favorites_screen`), sản phẩm sắp hết hạn hiển thị (`products`).
    - **NTT Point**: Điểm mới được cộng (`nttPointTransactions`), điểm sắp hết hạn.
    - **Hệ thống**: Cập nhật ứng dụng, bảo trì, thông báo bảo mật.
    - **Khuyến mãi**: Thông tin về các chương trình khuyến mãi, flash sale.

3. Giao diện thông báo (`notifications_screen` - Tab Thông báo):
    - Truy cập từ tab "Thông báo" trên màn hình chính.
    - Hiển thị danh sách thông báo với trạng thái đọc/chưa đọc.
    - Có thể phân tab thông báo theo loại để dễ quản lý.
    - Badge counter trên icon thông báo hiển thị số lượng chưa đọc.
    - Mỗi thông báo đẩy có thể chứa **deep link** dẫn trực tiếp đến màn hình liên quan trong ứng dụng.

4. Tùy chỉnh thông báo:
    - Vào Tài khoản > Cài đặt > Thông báo.
    - Bật/tắt nhận thông báo đẩy cho từng loại thông báo riêng biệt.
    - Thiết lập lịch trình "không làm phiền".
    - Tùy chỉnh âm thanh thông báo (trên Android 8.0+ sử dụng notification channels).
    - Các tùy chọn được lưu trên server để đồng bộ giữa các thiết bị.

Lưu ý: Nên bật thông báo cho các loại quan trọng (Đơn hàng, Tin nhắn) để không bỏ lỡ thông tin.
''',
      'keywords': ['thông báo', 'notification', 'push notification', 'fcm', 'firebase cloud messaging', 'quản lý thông báo', 'cài đặt thông báo', 'loại thông báo'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 17, // Adjusted order
    },
    {
      'title': 'Các phương thức giao hàng và phí vận chuyển',
      'content': '''
Student Market NTTU hỗ trợ các phương thức giao hàng linh hoạt để bạn nhận/gửi hàng thuận tiện:

1. Giao hàng nội bộ trường (Campus Delivery):
    - Áp dụng cho giao dịch giữa các **sinh viên NTTU đã xác thực**.
    - Trong khuôn viên trường.
    - Thời gian giao hàng: 1-24 giờ.
    - Phí: **Miễn phí**.
    - Sử dụng đội ngũ shipper nội bộ trường (`shippers` collection).

2. Giao hàng trực tiếp (Face-to-face):
    - Người mua và người bán tự hẹn gặp để trao đổi sản phẩm.
    - Nên chọn địa điểm công cộng, đông người trong hoặc gần trường.
    - Phí: Không có.
    - **Lưu ý an toàn**: Cần cẩn trọng khi giao dịch trực tiếp, đặc biệt với các mặt hàng giá trị cao.

3. Giao hàng qua dịch vụ đối tác (Partner Delivery):
    - Sử dụng các đơn vị vận chuyển đối tác như Grab Express, Ahamove, Giao Hàng Nhanh... (tích hợp API).
    - Áp dụng cho giao dịch trong thành phố hoặc liên tỉnh.
    - Thời gian giao hàng: Tùy thuộc đối tác (1-3 ngày nội thành, 3-7 ngày liên tỉnh).
    - Phí: Theo tính toán của đối tác (khoảng cách, trọng lượng...). **Sinh viên đã xác thực được giảm 50% phí vận chuyển đối tác**.

4. Giao hàng tiêu chuẩn (Standard Shipping):
    - Sử dụng các đơn vị vận chuyển truyền thống như Vietnam Post, VNPost, J&T Express...
    - Phí: Theo bảng giá chung.
    - Thời gian giao hàng: 3-7 ngày. Phù hợp cho các mặt hàng không quá khẩn cấp.

Quy trình giao nhận hàng:
- Người bán chuẩn bị hàng và đóng gói cẩn thận.
- Chọn phương thức vận chuyển khi đăng sản phẩm hoặc tạo đơn hàng.
- Theo dõi trạng thái giao hàng trong mục Đơn hàng của tôi (`orders` collection).
- **Xác nhận giao hàng**: Khi nhận hàng, cần xác nhận trong ứng dụng bằng **mã OTP** hoặc **quét mã QR** để đảm bảo giao dịch được ghi nhận và bảo vệ quyền lợi (đặc biệt quan trọng với COD).

Lưu ý: Đóng gói cẩn thận và kiểm tra thông tin người nhận giúp tránh sự cố khi vận chuyển. Có thể mua bảo hiểm cho hàng hóa giá trị cao.
''',
      'keywords': ['giao hàng', 'vận chuyển', 'shipping', 'delivery', 'đối tác giao hàng', 'phí vận chuyển', 'campus delivery', 'giao hàng trực tiếp', 'phương thức giao hàng'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 18, // Adjusted order
    },
    {
      'title': 'Đăng ký và Quản lý Shipper nội bộ trường',
      'content': '''
Nếu bạn là sinh viên NTTU và muốn kiếm thêm thu nhập, bạn có thể đăng ký trở thành Shipper nội bộ trường (`shippers` collection):

1. Đăng ký làm shipper (`register_shipper_screen`):
    - Truy cập Tài khoản > Đăng ký làm shipper.
    - Điền thông tin cá nhân và tải lên giấy tờ xác minh (CMND/CCCD, Thẻ sinh viên).
    - Yêu cầu xác minh số điện thoại qua SMS.
    - Đơn đăng ký sẽ trải qua quy trình phê duyệt 2 bước (tự động và thủ công).
    - Thông báo kết quả phê duyệt qua push notification (`notifications`).
    - Thiết lập khu vực hoạt động và thời gian có thể nhận đơn.

2. Quản lý đơn hàng cần giao (Dành cho Shipper):
    - Shipper có giao diện riêng (hoặc chức năng hiển thị khi tài khoản có vai trò shipper).
    - Xem danh sách các đơn hàng chờ giao trong khu vực đã thiết lập.
    - Bản đồ hiển thị vị trí người gửi và người nhận.
    - Có thể lọc và sắp xếp đơn hàng theo khoảng cách, giá trị.
    - Nhận/Từ chối đơn hàng phù hợp.
    - Theo dõi thu nhập và lịch sử giao hàng đã hoàn thành.
    - Tính năng báo cáo sự cố nếu gặp vấn đề trong quá trình giao hàng.

3. Hệ thống phân phối đơn hàng:
    - Thuật toán tự động (`Firebase Functions`) sẽ kết nối đơn hàng với shipper phù hợp dựa trên vị trí, đánh giá, tỷ lệ hoàn thành đơn, thời gian hoạt động.
    - Thông báo tự động được gửi đến shipper khi có đơn hàng mới trong khu vực.
    - Hệ thống tính toán phí giao hàng (nếu có, ví dụ giao ngoài khuôn viên).

4. Theo dõi đơn hàng (từ phía Shipper):
    - Cập nhật trạng thái đơn hàng theo thời gian thực trong collection `orders`.
    - Chia sẻ vị trí hiện tại với người mua (cần sự đồng ý của shipper).
    - Ghi nhận thời gian và vị trí khi nhận và giao hàng.

5. Xác nhận giao hàng (`Firebase Functions`, `orders` collection):
    - Tại điểm giao hàng, yêu cầu người nhận cung cấp **mã xác nhận OTP** hoặc **quét mã QR** từ ứng dụng người mua để hoàn thành giao dịch.
    - Có thể yêu cầu chụp ảnh bằng chứng giao hàng.
    - Người nhận có thể ký tên trực tiếp trên thiết bị của shipper.

6. Hệ thống đánh giá Shipper:
    - Người mua có thể đánh giá shipper sau khi nhận hàng.
    - Đánh giá ảnh hưởng đến xếp hạng shipper và ưu tiên nhận đơn hàng trong tương lai.
    - Hệ thống khen thưởng cho shipper hoạt động hiệu quả.

Lưu ý: Trở thành shipper nội bộ trường là cơ hội tốt để tăng thu nhập và hỗ trợ cộng đồng sinh viên.
''',
      'keywords': ['shipper', 'đăng ký shipper', 'giao hàng nội bộ', 'quản lý shipper', 'tìm shipper', 'vận chuyển trong trường', 'shippers', 'xác nhận giao hàng', 'otp', 'qr code'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 19, // Adjusted order
    },
    {
      'title': 'Cách liên hệ bộ phận hỗ trợ',
      'content': '''
Khi cần hỗ trợ từ Student Market NTTU, bạn có thể sử dụng các phương thức liên hệ sau, truy cập qua mục **Tài khoản > Cài đặt > Trợ giúp & Hỗ trợ**:

1. Trợ lý ảo trong ứng dụng:
    - Truy cập từ tab "Tin nhắn" hoặc biểu tượng chatbot.
    - Hoạt động 24/7, trả lời tự động các câu hỏi thường gặp dựa trên **Cơ sở kiến thức (Knowledge Base)** và **AI (Google Gemini)**.
    - Có thể giải quyết các vấn đề cơ bản về sử dụng ứng dụng, chính sách, đơn hàng...
    - Tự động chuyển tiếp đến nhân viên hỗ trợ nếu không thể giải quyết.

2. Chat trực tiếp với nhân viên hỗ trợ:
    - Truy cập "Trợ giúp & Hỗ trợ" > "Chat với nhân viên".
    - Thời gian phục vụ: 8:00 - 22:00 hàng ngày.
    - Thời gian phản hồi nhanh (2-5 phút trong giờ làm việc). Phù hợp vấn đề cần giải quyết nhanh.
    - Có thể gửi ảnh chụp màn hình vấn đề.

3. Gửi yêu cầu hỗ trợ:
    - Truy cập "Trợ giúp & Hỗ trợ" > "Gửi yêu cầu".
    - Chọn loại vấn đề, mô tả chi tiết, đính kèm ảnh chụp màn hình.
    - Phản hồi qua email hoặc tin nhắn trong 24-48 giờ làm việc. Phù hợp vấn đề phức tạp. Yêu cầu được lưu và theo dõi trạng thái.

4. Email hỗ trợ (theo bộ phận):
    - Hỗ trợ chung: support@studentmarket.nttu.edu.vn
    - Vấn đề thanh toán: payment@studentmarket.nttu.edu.vn
    - Khiếu nại, tranh chấp: dispute@studentmarket.nttu.edu.vn
    - Báo cáo vi phạm: report@studentmarket.nttu.edu.vn
    - Ghi rõ tiêu đề, mã đơn hàng/giao dịch (nếu có).

5. Hotline hỗ trợ:
    - Số điện thoại chung: 028.3456.7890 (8:00 - 20:00 hàng ngày).
    - Hỗ trợ thanh toán: 028.3456.7891.
    - Hỗ trợ vận chuyển: 028.3456.7892.
    - Phù hợp các vấn đề khẩn cấp.

6. Văn phòng hỗ trợ tại trường:
    - Địa điểm: Phòng 103, Tòa nhà A, Trường Đại học NTTU.
    - Thời gian làm việc hành chính. Hỗ trợ trực tiếp các vấn đề phức tạp, đào tạo sử dụng.

7. Hỗ trợ qua mạng xã hội:
    - Facebook: fb.com/StudentMarketNTTU, Instagram: instagram.com/studentmarket_nttu.
    - Chỉ dùng cho thông tin chung, không chia sẻ thông tin cá nhân.

Khi liên hệ, cung cấp thông tin đầy đủ (tên tài khoản, mã đơn hàng/yêu cầu, ảnh chụp lỗi...) để được hỗ trợ nhanh nhất.
''',
      'keywords': ['hỗ trợ', 'liên hệ', 'support', 'trợ giúp', 'hotline', 'email', 'giúp đỡ', 'chat', 'liên hệ hỗ trợ', 'cskh'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 20, // Adjusted order
    },
    {
      'title': 'Cách giải quyết tranh chấp giao dịch',
      'content': '''
Khi gặp tranh chấp trong giao dịch trên Student Market NTTU (liên quan đến đơn hàng trong `orders` collection), bạn cần tuân theo quy trình sau để được hỗ trợ giải quyết:

1. Các loại tranh chấp được hỗ trợ:
    - Sản phẩm không đúng mô tả (khác hình ảnh, thông tin).
    - Sản phẩm bị lỗi/hư hỏng khi nhận.
    - Không nhận được hàng.
    - Người bán/người mua không hợp tác.
    - Vấn đề về thanh toán (tiền bị trừ nhưng đơn hàng sai...).
    - Phí không rõ ràng.

2. Thời hạn báo cáo vấn đề:
    - Sản phẩm đã nhận: trong vòng **48 giờ** sau khi nhấn "Đã nhận hàng".
    - Sản phẩm không nhận được: trong vòng **7 ngày** sau ngày giao dự kiến.
    - Vấn đề thanh toán: trong vòng **30 ngày** kể từ ngày thanh toán.

3. Bước 1: Liên hệ trực tiếp với bên còn lại (Người bán/Người mua):
    - Sử dụng tính năng **chat trong ứng dụng** (`chats` collection).
    - Mô tả rõ vấn đề, cung cấp bằng chứng (ảnh sản phẩm, tin nhắn...).
    - Thảo luận tìm giải pháp (đổi/trả, hoàn tiền...).
    - Lưu giữ toàn bộ tin nhắn.
    - Thời gian khuyến nghị: 1-3 ngày.

4. Bước 2: Nộp đơn yêu cầu hỗ trợ giải quyết tranh chấp (`dispute@studentmarket.nttu.edu.vn` hoặc qua ứng dụng):
    - Nếu không thể tự giải quyết với bên kia.
    - Truy cập Đơn hàng của tôi (`order_history_screen`) > Chọn đơn hàng có vấn đề > "Báo cáo vấn đề".
    - Điền thông tin chi tiết vấn đề, các bước đã làm, giải pháp mong muốn.
    - Cung cấp bằng chứng đầy đủ (ảnh sản phẩm, video mở hộp, tin nhắn chat, biên lai...). Bằng chứng được lưu liên quan đến đơn hàng.
    - Bạn sẽ nhận được mã số tranh chấp để theo dõi.

5. Bước 3: Đội ngũ hỗ trợ xem xét tranh chấp:
    - Đội ngũ hỗ trợ sẽ xem xét thông tin từ cả hai bên và bằng chứng.
    - Có thể liên hệ yêu cầu thêm thông tin.
    - Phân tích dựa trên chính sách Student Market, mô tả sản phẩm, bằng chứng.
    - Đưa ra quyết định giải quyết cuối cùng (trong 3-7 ngày làm việc).

6. Bước 4: Thực hiện quyết định giải quyết:
    - **Hoàn tiền**: Tiền được hoàn về phương thức thanh toán ban đầu (xem **Giải quyết vấn đề thanh toán** về thời gian hoàn tiền). NTT Point được hoàn lại ngay lập tức.
    - **Đổi hàng**: Yêu cầu người bán gửi sản phẩm thay thế.
    - **Bồi thường một phần**.
    - Đóng tranh chấp.

7. Biện pháp phòng tránh tranh chấp:
    - Người bán: Mô tả chính xác, ảnh rõ ràng, đóng gói cẩn thận, giao hàng đúng hẹn.
    - Người mua: Đọc kỹ mô tả, xem đánh giá người bán, hỏi rõ trước khi mua, quay video mở hàng, kiểm tra kỹ trước khi xác nhận "Đã nhận hàng".
    - Luôn giao dịch và thanh toán trong ứng dụng.

Quyết định từ đội ngũ hỗ trợ là cuối cùng. Các trường hợp gian lận sẽ bị xử lý nghiêm.
''',
      'keywords': ['tranh chấp', 'khiếu nại', 'hoàn tiền', 'đổi trả', 'bồi thường', 'báo cáo', 'vấn đề', 'dispute', 'giải quyết tranh chấp', 'chính sách tranh chấp'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 21, // Adjusted order
    },
    {
      'title': 'Chính sách đổi trả và hoàn tiền',
      'content': '''
Chính sách đổi trả và hoàn tiền của Student Market NTTU nhằm bảo vệ quyền lợi người mua. Quy trình này thường liên quan đến việc giải quyết tranh chấp và trạng thái đơn hàng (`orders` collection).

1. Điều kiện được đổi trả/hoàn tiền:
    - Sản phẩm không đúng mô tả hoặc khác biệt đáng kể so với thông tin trên ứng dụng (`products` collection).
    - Sản phẩm bị lỗi hoặc hư hỏng khi nhận hàng (không phải do người mua).
    - Sản phẩm giả, nhái, vi phạm bản quyền.
    - Sản phẩm thiếu phụ kiện theo cam kết.
    - Người bán gửi sai sản phẩm.
    - Không nhận được hàng.

2. Thời hạn yêu cầu đổi trả:
    - Sản phẩm thông thường: **48 giờ** sau khi nhận hàng.
    - Sản phẩm điện tử: **7 ngày** sau khi nhận hàng.
    - Sản phẩm có bảo hành: theo chính sách bảo hành cụ thể.
    - Không nhận được hàng: **7 ngày** sau ngày giao dự kiến.

3. Các trường hợp không được đổi trả:
    - Sản phẩm đã qua sử dụng (trừ khi phát hiện lỗi trong quá trình sử dụng).
    - Sản phẩm bị hư hỏng do lỗi người mua.
    - Khác biệt nhỏ không đáng kể so với mô tả.
    - Sản phẩm được đánh dấu "Không đổi trả" và người mua đã đồng ý.
    - Yêu cầu sau thời hạn quy định.
    - Thiếu bao bì, nhãn mác, phụ kiện (trừ khi do người bán cung cấp thiếu).
    - Các sản phẩm đặc biệt (thực phẩm đã mở, đồ lót...).

4. Quy trình đổi trả/hoàn tiền:
    - **Bước 1**: Liên hệ người bán qua chat (`chats`). Cung cấp bằng chứng (ảnh, video).
    - **Bước 2**: Nếu người bán đồng ý, làm theo hướng dẫn của họ.
    - **Bước 3**: Nếu người bán từ chối hoặc không phản hồi trong 48 giờ, **báo cáo vấn đề** qua mục Đơn hàng của tôi (`order_history_screen`) để yêu cầu hỗ trợ giải quyết tranh chấp (xem **Cách giải quyết tranh chấp giao dịch**).

5. Phương thức hoàn tiền:
    - Hoàn tiền về phương thức thanh toán ban đầu (Ví điện tử, Thẻ, Ngân hàng). Thời gian hoàn tiền khác nhau (xem **Giải quyết vấn đề thanh toán**).
    - Hoàn tiền vào số dư tài khoản Student Market (thường nhanh hơn).
    - Hoàn tiền dưới dạng **NTT Point** (có thể có giá trị cao hơn).
    - Hoàn tiền toàn bộ (giá SP + phí vận chuyển) hoặc một phần.

6. Chi phí đổi trả:
    - Lỗi từ người bán: người bán chịu phí vận chuyển.
    - Lỗi từ người mua (đổi ý, đặt sai...): người mua chịu phí vận chuyển.
    - Tranh chấp: theo quyết định của đội ngũ hỗ trợ.

**Quan trọng**: Quay video khi mở gói hàng và kiểm tra kỹ sản phẩm trước khi nhấn "Đã nhận hàng" để bảo vệ quyền lợi của bạn.
''',
      'keywords': ['đổi trả', 'hoàn tiền', 'refund', 'return', 'đổi hàng', 'trả lại', 'bảo hành', 'lỗi sản phẩm', 'chính sách đổi trả', 'chính sách hoàn tiền'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 22, // Adjusted order
    },
    {
      'title': 'Tổng quan và Lợi ích của NTT Point',
      'content': '''
NTT Point là hệ thống điểm thưởng độc quyền dành cho cộng đồng Student Market NTTU, được triển khai dưới dạng ChangeNotifier và quản lý giao dịch trong collection `nttPointTransactions`.

1. NTT Point là gì?
    - Là điểm thưởng bạn tích lũy được thông qua các hoạt động trên nền tảng (mua bán, tặng đồ, giới thiệu...).
    - Có thể sử dụng để giảm giá trực tiếp khi mua hàng.
    - Mỗi điểm có thời hạn sử dụng **6 tháng**.

2. Lợi ích khi sử dụng NTT Point:
    - **Tiết kiệm chi phí mua sắm**: Quy đổi điểm thành tiền mặt để giảm giá đơn hàng.
    - **Đặc quyền cho người dùng thân thiết**: Thể hiện sự ghi nhận đóng góp của bạn cho cộng đồng.
    - **Khuyến khích hoạt động**: Tạo động lực để bạn tham gia mua bán, tặng đồ và tương tác trên ứng dụng.

3. Tỷ lệ quy đổi và giới hạn sử dụng:
    - **10 NTT Point = 1.000 VNĐ**.
    - Có thể áp dụng tối đa **50% giá trị đơn hàng** bằng điểm.
    - Hệ thống tự động tính toán số tiền giảm giá khi bạn áp dụng điểm trên màn hình thanh toán (`checkout_screen`).

4. Quản lý điểm:
    - Xem số dư điểm hiện tại và điểm sắp hết hạn trong mục Tài khoản > NTT Point.
    - Theo dõi chi tiết lịch sử kiếm và sử dụng điểm trong `nttPointTransactions`.
    - Nhận thông báo khi điểm sắp hết hạn.

Xem thêm các mục khác trong danh mục NTT Point để biết chi tiết cách kiếm điểm và quản lý điểm hết hạn.
''',
      'keywords': ['ntt point', 'điểm thưởng', 'lợi ích ntt point', 'quy đổi điểm', 'tiết kiệm', 'discount'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 23, // Adjusted order
    },
    {
      'title': 'Cách kiếm thêm NTT Point',
      'content': '''
Bạn có thể tích lũy NTT Point thông qua các hoạt động sau trên Student Market NTTU. Điểm kiếm được sẽ được ghi lại trong collection `nttPointTransactions`.

1. **Đăng sản phẩm "Đồ tặng"**:
    - Mỗi sản phẩm được đăng trong danh mục "Đồ tặng" và được duyệt thành công sẽ cộng **+10 NTT Point**.

2. **Hoàn thành giao dịch mua bán thành công**:
    - Khi bạn hoàn thành vai trò người mua hoặc người bán trong một đơn hàng (`orders`) và giao dịch được đánh dấu là "Hoàn thành" (sau khi người mua xác nhận đã nhận hàng), bạn sẽ nhận được điểm thưởng dựa trên giá trị đơn hàng. Công thức cụ thể có thể thay đổi (ví dụ: 10.000đ chi tiêu = 1 NTT Point).

3. **Giới thiệu bạn bè**:
    - Sử dụng tính năng giới thiệu bạn bè để mời người dùng mới tham gia Student Market NTTU.
    - Bạn và người bạn giới thiệu sẽ nhận được **+5 NTT Point** khi người được giới thiệu đăng ký thành công và hoàn thành giao dịch đầu tiên.

4. **Hoàn thành khảo sát và đánh giá**:
    - Tham gia các khảo sát nhanh hoặc viết đánh giá (`reviews`) cho sản phẩm đã mua.
    - Mỗi lần hoàn thành khảo sát hoặc đánh giá chất lượng, bạn sẽ nhận được một lượng NTT Point nhất định.

5. **Người dùng tích cực hàng tháng**:
    - Hệ thống có thể tự động thưởng điểm cho những người dùng có hoạt động tích cực nhất trong tháng (đăng bài mới, tương tác chat, tham gia giao dịch...).

6. **Tham gia các chương trình khuyến mãi và sự kiện**:
    - Theo dõi mục Thông báo (`notifications`) và các kênh truyền thông chính thức của Student Market NTTU để cập nhật các sự kiện đặc biệt có thưởng NTT Point.

Lưu ý: Điểm thưởng thường được cộng vào tài khoản của bạn trong vòng 24 giờ sau khi hoàn thành hoạt động tương ứng. Kiểm tra Lịch sử giao dịch điểm để theo dõi chi tiết.
''',
      'keywords': ['kiếm điểm', 'tích điểm', 'ntt point', 'cách kiếm điểm', 'điểm thưởng'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 24, // Adjusted order
    },
    {
      'title': 'Lịch sử giao dịch và Quản lý điểm hết hạn NTT Point',
      'content': '''
Bạn có thể theo dõi chi tiết lịch sử NTT Point và quản lý điểm sắp hết hạn tại mục **Tài khoản > NTT Point** (`ntt_point_history_screen`). Mọi giao dịch điểm đều được ghi lại trong collection `nttPointTransactions`.

1. Xem lịch sử giao dịch điểm (`nttPointTransactions`):
    - Truy cập Tài khoản > NTT Point.
    - Nhấn vào mục "Lịch sử giao dịch".
    - Xem danh sách tất cả các giao dịch điểm của bạn, bao gồm:
      - **Loại giao dịch**: Kiếm được, Đã dùng, Bị trừ, Hoàn lại, Hết hạn.
      - **Mô tả chi tiết**: Nguồn điểm (ví dụ: "Thưởng đơn hàng OM-XXXXX", "Đăng sản phẩm tặng", "Sử dụng giảm giá đơn hàng #YYYYY", "Điểm hết hạn").
      - **Số điểm** được cộng (+) hoặc trừ (-).
      - **Thời gian** diễn ra giao dịch.
    - Có thể lọc lịch sử theo loại giao dịch hoặc khoảng thời gian.

2. Quản lý điểm sắp hết hạn:
    - Mỗi NTT Point có thời hạn sử dụng là **6 tháng** kể từ ngày bạn nhận được.
    - Hệ thống sẽ tự động kiểm tra và thông báo cho bạn (qua ứng dụng và email) khi có điểm sắp hết hạn, thường là **trước 15 ngày**.
    - Bạn có thể xem tổng số điểm sắp hết hạn và chi tiết các đợt điểm sẽ hết hạn trong mục NTT Point.
    - **Cách sử dụng điểm sắp hết hạn**: Ưu tiên dùng điểm này khi thanh toán đơn hàng. Hệ thống tự động ưu tiên sử dụng điểm có thời hạn hết sớm nhất.

3. Điểm hết hạn:
    - Nếu điểm không được sử dụng trước thời hạn, hệ thống sẽ tự động tạo một giao dịch "Hết hạn" trong `nttPointTransactions` và trừ số điểm đó khỏi số dư của bạn.

Việc thường xuyên kiểm tra mục NTT Point giúp bạn nắm rõ số dư, lịch sử giao dịch và kịp thời sử dụng các điểm sắp hết hạn.
''',
      'keywords': ['lịch sử điểm', 'ntt point', 'điểm hết hạn', 'quản lý điểm', 'giao dịch điểm', 'kiểm tra điểm', 'nttpointtransactions'],
      'category': 'help', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 25, // Adjusted order
    },
{
      'title': 'Mẹo tạo danh sách sản phẩm hiệu quả',
      'content': '''
Để sản phẩm của bạn thu hút người mua nhanh hơn, hãy áp dụng các mẹo sau khi tạo danh sách sản phẩm:

1. **Chụp ảnh sản phẩm chất lượng cao**:
    - Sử dụng ánh sáng tự nhiên tốt.
    - Chụp từ nhiều góc độ khác nhau.
    - Chụp rõ các chi tiết quan trọng và cả khuyết điểm (nếu có).
    - Nền đơn giản, làm nổi bật sản phẩm.
    - Tải lên tối đa 10 ảnh để người mua có cái nhìn đầy đủ nhất. Video ngắn (dưới 30s) cũng rất hiệu quả.

2. **Viết tiêu đề hấp dẫn và rõ ràng**:
    - Ngắn gọn, dễ hiểu, chứa từ khóa chính.
    - Ví dụ: "Laptop Dell Inspiron 15 inch cũ (Core i5)", "Giáo trình Toán cao cấp A1 mới 99%", "Áo thun đồng phục NTTU size M".

3. **Mô tả sản phẩm chi tiết và trung thực**:
    - Cung cấp đầy đủ thông tin: tình trạng (mới, đã sử dụng, còn bảo hành), thương hiệu, model, thông số kỹ thuật quan trọng.
    - Nêu rõ các khuyết điểm nhỏ (trầy xước, mất phụ kiện...).
    - Viết mô tả bằng ngôn ngữ tự nhiên, dễ đọc.
    - Sử dụng tính năng rich text để định dạng văn bản (in đậm, gạch đầu dòng...).

4. **Đặt giá hợp lý**:
    - Tham khảo giá các sản phẩm tương tự trên thị trường hoặc trên Student Market NTTU.
    - Cân nhắc tình trạng sản phẩm và nhu cầu thị trường.
    - Có thể để giá linh hoạt (cho phép trả giá) hoặc giá cố định.

5. **Sử dụng từ khóa (Tags)**:
    - Thêm các từ khóa liên quan giúp sản phẩm dễ được tìm thấy hơn khi người dùng tìm kiếm.
    - Ví dụ: "laptop cu", "dell i5", "giao trinh nttu", "ao thun nttu", "thanh ly".

Áp dụng các mẹo này giúp tăng lượt xem và khả năng bán được hàng của bạn.
''',
      'keywords': ['mẹo đăng bán', 'tối ưu sản phẩm', 'ảnh sản phẩm', 'mô tả sản phẩm', 'định giá', 'tiêu đề sản phẩm', 'từ khóa sản phẩm', 'đăng bài bán hàng'],
      'category': 'help',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 26, // Tiếp theo sau các mục cũ
    },
    {
      'title': 'Quản lý tin nhắn và tương tác với người mua',
      'content': '''
Giao tiếp hiệu quả với người mua qua tính năng chat là chìa khóa để giao dịch thành công trên Student Market NTTU. Tin nhắn được lưu trong collection `chats` và subcollection `messages`.

1. **Truy cập tin nhắn**:
    - Nhấn vào tab "Tin nhắn" trên màn hình chính.
    - Danh sách các cuộc trò chuyện (chat) sẽ hiển thị.
    - Chatbot "Trợ lý ảo" cũng nằm trong danh sách này.

2. **Trả lời tin nhắn nhanh chóng**:
    - Cố gắng phản hồi các câu hỏi của người mua trong thời gian sớm nhất có thể. Trả lời nhanh giúp tăng tỷ lệ chuyển đổi và cải thiện **điểm uy tín (NTT Credit)** của bạn.
    - Hệ thống có thể hiển thị "Tỷ lệ phản hồi" và "Thời gian phản hồi trung bình" trên hồ sơ của bạn.

3. **Cung cấp thông tin chính xác**:
    - Trả lời đúng và đầy đủ các câu hỏi về sản phẩm, tình trạng, cách sử dụng...
    - Nếu có thể, gửi thêm ảnh hoặc video chi tiết qua chat.

4. **Thương lượng giá (nếu có)**:
    - Nếu bạn cho phép trả giá, hãy lịch sự thương lượng với người mua.
    - Có thể sử dụng tính năng "Gửi đề nghị giá" trong chat (nếu có).

5. **Xác nhận đơn hàng**:
    - Sau khi người mua đặt hàng, bạn sẽ nhận được thông báo. Kiểm tra chi tiết đơn hàng trong mục "Đơn hàng của tôi" (dành cho người bán).
    - Trao đổi với người mua về thời gian và địa điểm giao nhận nếu là giao hàng trực tiếp.

6. **Lưu ý an toàn khi chat**:
    - **Không chia sẻ thông tin cá nhân nhạy cảm** (số tài khoản ngân hàng đầy đủ, mật khẩu...).
    - **Luôn giao dịch trong ứng dụng**: Không đồng ý chuyển khoản hoặc thanh toán bên ngoài nền tảng. Điều này giúp Student Market NTTU có thể hỗ trợ bạn khi có tranh chấp.
    - Báo cáo ngay cho bộ phận hỗ trợ nếu nhận thấy hành vi lừa đảo hoặc quấy rối.

Việc tương tác tốt qua chat giúp xây dựng lòng tin với người mua và hoàn thành giao dịch suôn sẻ.
''',
      'keywords': ['chat', 'tin nhắn', 'liên hệ người mua', 'tương tác khách hàng', 'quản lý chat', 'trả lời tin nhắn', 'thương lượng giá', 'an toàn khi chat'],
      'category': 'help',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 27, // Tiếp theo
    },
     {
      'title': 'Chuẩn bị đơn hàng để giao',
      'content': '''
Sau khi đơn hàng được xác nhận, việc chuẩn bị hàng cẩn thận là rất quan trọng để đảm bảo sản phẩm đến tay người mua an toàn.

1. **Kiểm tra lại sản phẩm**:
    - Đảm bảo sản phẩm đúng như mô tả và hình ảnh đã đăng.
    - Kiểm tra tình trạng hoạt động (đối với đồ điện tử) hoặc các chi tiết quan trọng khác.
    - Chuẩn bị đầy đủ phụ kiện đi kèm (sạc, cáp, sách hướng dẫn...).

2. **Vệ sinh sản phẩm**:
    - Lau chùi sạch sẽ sản phẩm trước khi đóng gói để tạo ấn tượng tốt.

3. **Đóng gói cẩn thận**:
    - Sử dụng vật liệu đóng gói phù hợp (hộp carton, xốp chống sốc, túi bóng khí...).
    - Đảm bảo sản phẩm được cố định chắc chắn bên trong, không bị xê dịch.
    - Đối với hàng dễ vỡ, dán nhãn "Hàng dễ vỡ" bên ngoài.
    - Sử dụng băng keo niêm phong chắc chắn.

4. **In và dán nhãn vận chuyển**:
    - Nếu sử dụng dịch vụ giao hàng đối tác, hệ thống sẽ tạo nhãn vận chuyển với thông tin người gửi, người nhận và mã đơn hàng.
    - In nhãn rõ ràng và dán chắc chắn lên gói hàng.
    - Nếu là giao hàng trực tiếp hoặc nội bộ, bạn chỉ cần đảm bảo thông tin người nhận chính xác.

5. **Bàn giao cho đơn vị vận chuyển**:
    - Nếu sử dụng dịch vụ đối tác hoặc shipper nội bộ, bàn giao gói hàng cho họ đúng hẹn và địa điểm đã thỏa thuận.
    - Giữ lại biên nhận hoặc xác nhận bàn giao từ shipper.

6. **Cập nhật trạng thái đơn hàng**:
    - Trong mục "Đơn hàng của tôi" (dành cho người bán), cập nhật trạng thái đơn hàng sang "Đã bàn giao cho ĐVVC" hoặc tương tự.

Việc chuẩn bị và bàn giao đơn hàng đúng quy trình giúp tránh hư hỏng trong quá trình vận chuyển và đảm bảo người mua hài lòng.
''',
      'keywords': ['chuẩn bị đơn hàng', 'đóng gói sản phẩm', 'giao hàng', 'vận chuyển', 'bàn giao hàng', 'đóng gói', 'vệ sinh sản phẩm'],
      'category': 'help',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 28, // Tiếp theo
    },
    {
      'title': 'Nhận tiền bán hàng và Rút tiền',
      'content': '''
Sau khi giao dịch bán hàng trên Student Market NTTU hoàn tất, bạn sẽ nhận được tiền vào ví người bán của mình.

1. **Quy trình nhận tiền**:
    - Khi người mua nhấn "**Đã nhận hàng**" trong ứng dụng, trạng thái đơn hàng chuyển sang "Hoàn thành".
    - Tiền bán hàng (sau khi trừ phí nền tảng, nếu có) sẽ được giữ trong hệ thống đảm bảo của Student Market NTTU trong khoảng thời gian quy định (thường 24 giờ) để đề phòng tranh chấp.
    - Sau thời gian đảm bảo và không có khiếu nại, tiền sẽ được giải ngân vào ví người bán của bạn trong ứng dụng.
    - Bạn sẽ nhận được thông báo khi tiền được cập nhật vào ví.

2. **Ví người bán trong ứng dụng**:
    - Truy cập Tài khoản > Ví người bán (hoặc Doanh thu).
    - Xem số dư hiện tại.
    - Xem lịch sử các giao dịch nhận tiền từ các đơn hàng đã hoàn thành (`orders`).
    - Xem lịch sử rút tiền.

3. **Rút tiền về tài khoản ngân hàng/ví điện tử**:
    - Trong mục Ví người bán, chọn "Rút tiền".
    - Liên kết tài khoản ngân hàng hoặc ví điện tử của bạn (cần xác minh thông tin).
    - Nhập số tiền muốn rút (phải lớn hơn số tiền tối thiểu).
    - Xác nhận yêu cầu rút tiền (có thể yêu cầu mã OTP để bảo mật).
    - Yêu cầu rút tiền sẽ được xử lý bởi hệ thống. Thời gian xử lý có thể khác nhau tùy phương thức và ngân hàng (thường 1-3 ngày làm việc).

4. **Phí rút tiền**:
    - Student Market NTTU có thể áp dụng phí nhỏ cho mỗi lần rút tiền hoặc miễn phí nếu rút trên một ngưỡng nhất định (tham khảo mục Cài đặt > Phí & Thanh toán).

5. **Kiểm tra trạng thái rút tiền**:
    - Theo dõi trạng thái yêu cầu rút tiền trong lịch sử giao dịch ví người bán.
    - Nhận thông báo khi yêu cầu được xử lý thành công.

Lưu ý: Đảm bảo thông tin tài khoản ngân hàng/ví điện tử liên kết là chính xác để quá trình rút tiền diễn ra thuận lợi.
''',
      'keywords': ['nhận tiền bán hàng', 'rút tiền', 'ví người bán', 'thanh toán cho người bán', 'giải ngân tiền', 'phí rút tiền', 'quản lý doanh thu'],
      'category': 'help',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 29, // Tiếp theo
    },     
     {
      'title': 'Các cấp bậc người dùng và Điểm uy tín (NTT Credit)',
      'content': '''
Student Market NTTU có hệ thống cấp bậc người dùng và Điểm uy tín (NTT Credit) để xây dựng cộng đồng đáng tin cậy và công bằng.

1. **Điểm uy tín (NTT Credit)**:
    - Là chỉ số đánh giá mức độ đáng tin cậy của người dùng (đặc biệt là người bán).
    - Điểm được tính tự động dựa trên lịch sử hoạt động của bạn trên nền tảng, bao gồm:
        - **Tăng điểm**: Hoàn thành đơn hàng thành công, nhận đánh giá 5 sao, phản hồi tin nhắn nhanh, tuân thủ quy định, tham gia xác thực sinh viên, hoạt động tích cực...
        - **Giảm điểm**: Hủy đơn hàng (do lỗi của bạn), giao hàng trễ, sản phẩm không đúng mô tả, nhận đánh giá xấu, vi phạm quy định, bị báo cáo vi phạm chính xác...
    - Điểm uy tín hiển thị trên hồ sơ người dùng và trang chi tiết sản phẩm.

2. **Hệ thống cấp bậc người dùng**:
    - Dựa trên Điểm uy tín tích lũy, người dùng sẽ được xếp vào các cấp bậc: Mới, Đồng, Bạc, Vàng, Kim cương.
    - Mỗi cấp bậc có thể có biểu tượng (badge) riêng.
    - Cấp bậc càng cao, thể hiện mức độ tin cậy càng lớn.

3. **Lợi ích của Điểm uy tín và Cấp bậc cao**:
    - **Tăng lòng tin người mua**: Người mua có xu hướng tin tưởng và mua hàng từ những người bán có điểm uy tín cao.
    - **Ưu tiên hiển thị sản phẩm**: Sản phẩm từ người bán có điểm uy tín cao có thể được ưu tiên hiển thị trong kết quả tìm kiếm hoặc trên trang chủ.
    - **Giảm thời gian kiểm duyệt sản phẩm**: Sản phẩm mới đăng của người bán uy tín có thể được duyệt nhanh hơn.
    - **Tiếp cận các chương trình đặc biệt**: Có thể có các ưu đãi hoặc tính năng đặc biệt dành riêng cho các cấp bậc cao.
    - **Tỷ lệ quy đổi NTT Point tốt hơn** (đối với cấp bậc Vàng/Kim cương).

4. **Cách cải thiện Điểm uy tín**:
    - Luôn giao dịch trung thực, mô tả sản phẩm chính xác.
    - Phản hồi tin nhắn và xử lý đơn hàng nhanh chóng.
    - Đóng gói và giao hàng cẩn thận, đúng hẹn.
    - Giải quyết thỏa đáng các vấn đề phát sinh (đổi trả, hoàn tiền).
    - Tuân thủ nghiêm ngặt Quy định đăng sản phẩm và Chính sách cộng đồng.
    - Khuyến khích người mua đánh giá tốt sau khi hoàn thành đơn hàng.

Theo dõi Điểm uy tín và Cấp bậc của bạn trong mục Tài khoản để biết bạn đang ở đâu và làm thế nào để cải thiện.
''',
      'keywords': ['điểm uy tín', 'ntt credit', 'cấp bậc người dùng', 'uy tín người bán', 'xếp hạng người bán', 'cải thiện uy tín', 'lợi ích ntt credit'],
      'category': 'help',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 30, // Tiếp theo
    },
    // =========================================================================
    // DANH MỤC: product_search (Gộp từ product liên quan đến tìm kiếm/xem SP)
    // =========================================================================
    {
      'title': 'Tìm kiếm và lọc sản phẩm hiệu quả',
      'content': '''
Để tìm kiếm sản phẩm hiệu quả trên Student Market NTTU, bạn có thể sử dụng thanh tìm kiếm hoặc mục **Khám phá** (tab Khám phá):

1. Tìm kiếm cơ bản:
    - Nhấn biểu tượng kính lúp (tab Khám phá).
    - Nhập từ khóa (tên SP, thương hiệu). Hệ thống gợi ý từ khóa phổ biến.
    - Xem kết quả trong `products` collection.

2. Tìm kiếm nâng cao (Bộ lọc - Filter):
    - Từ trang kết quả tìm kiếm, nhấn biểu tượng lọc.
    - Sử dụng các bộ lọc đa tiêu chí:
      - Danh mục (`categories` collection): chọn danh mục/danh mục phụ (đa cấp).
      - Khoảng giá, Tình trạng (Mới, Đã sử dụng...).
      - Vị trí: lọc theo khoảng cách (sử dụng dữ liệu vị trí trong `users` và `products`).
      - Xếp hạng người bán, Điểm uy tín người bán (dựa trên dữ liệu đánh giá `reviews` và điểm uy tín trong `users`).
      - Thời gian đăng, Sắp xếp kết quả (Liên quan nhất, Giá, Mới nhất, Phổ biến, Đánh giá cao nhất, Gần nhất).

3. Tìm kiếm thông minh với AI (`Google Gemini AI`, `Pinecone`):
    - Sử dụng ngôn ngữ tự nhiên trong ô tìm kiếm ("laptop cũ dưới 5 triệu", "sách giải tích gần ký túc xá B").
    - AI phân tích ý định và sử dụng **Vector search** trên `products` để tìm sản phẩm phù hợp ngữ nghĩa.
    - Có thể kết hợp tìm kiếm bằng hình ảnh (sử dụng Computer Vision để tạo vector).

4. Tìm kiếm theo danh mục (`categories` collection):
    - Từ Trang chủ hoặc tab Khám phá, duyệt các danh mục sản phẩm (cây đa cấp).
    - Xem tất cả sản phẩm trong danh mục đã chọn.

5. Tính năng khác:
    - Lưu lịch sử tìm kiếm và bộ lọc đã sử dụng.
    - Tính năng "Thông báo khi có hàng" khi không tìm thấy kết quả phù hợp.

Lưu ý: Hệ thống tìm kiếm (được hỗ trợ bởi AI và Vector Search) liên tục cải thiện để mang lại kết quả chính xác và liên quan nhất.
''',
      'keywords': ['tìm kiếm', 'search', 'tìm sản phẩm', 'bộ lọc', 'filter', 'lọc sản phẩm', 'tìm theo hình ảnh', 'tìm kiếm thông minh', 'vector search', 'khám phá'],
      'category': 'product_search', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 0, // Reset order within new category
    },
    {
      'title': 'Xem chi tiết sản phẩm và liên hệ người bán',
      'content': '''
Khi bạn tìm thấy một sản phẩm quan tâm, hãy xem chi tiết để đưa ra quyết định mua sắm:

1. Trang chi tiết sản phẩm (`product_detail_screen`):
    - **Hình ảnh/video**: Carousel hiển thị ảnh/video sản phẩm (`Firebase Storage`), hỗ trợ zoom.
    - **Thông tin sản phẩm**: Tên, giá, mô tả (rich text), thông số kỹ thuật, tình trạng (lấy từ document sản phẩm trong `products` collection).
    - **Thông tin người bán**: Tên người bán, ảnh đại diện, điểm uy tín (NTT Credit) và xếp hạng trung bình (dựa trên dữ liệu trong `users` và `reviews`).
    - **Đánh giá sản phẩm**: Xem các đánh giá từ người mua trước đó (từ `reviews` subcollection của sản phẩm), bao gồm sao, nhận xét, hình ảnh. Có thể lọc và sắp xếp đánh giá.
    - **Sản phẩm tương tự**: Hiển thị các sản phẩm khác có thuộc tính hoặc vector embedding tương đồng.

2. Liên hệ người bán:
    - Nhấn nút "**Chat với người bán**" trên trang chi tiết sản phẩm.
    - Hệ thống sẽ tạo một cuộc trò chuyện mới hoặc mở cuộc trò chuyện hiện có trong collection `chats`.
    - Bạn có thể trao đổi trực tiếp với người bán qua tin nhắn văn bản, hình ảnh hoặc chia sẻ lại liên kết sản phẩm.
    - Nội dung tin nhắn được lưu trong `messages` subcollection của cuộc trò chuyện.
    - **Lưu ý**: Luôn chat trong ứng dụng để được hỗ trợ giải quyết tranh chấp nếu có. Không giao dịch bên ngoài ứng dụng.

3. Hành động khác:
    - Nhấn biểu tượng trái tim để **Thêm vào danh sách yêu thích** (`favorite_products_screen`).
    - Nhấn "**Thêm vào giỏ hàng**" (lưu vào giỏ hàng thông minh).
    - Nhấn "**Mua ngay**" để tiến hành thanh toán trực tiếp.
''',
      'keywords': ['chi tiết sản phẩm', 'xem sản phẩm', 'product detail', 'liên hệ người bán', 'chat', 'nhắn tin', 'firebase firestore', 'firebase storage', 'đánh giá sản phẩm', 'reviews', 'sản phẩm tương tự'],
      'category': 'product_search', // Re-categorized
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 1, // Adjusted order within new category
    },
  ];

  static Future<void> seedDatabase() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // Optional: Xóa dữ liệu cũ nếu cần
    // final existingDocs = await firestore.collection('knowledge_documents').get();
    // for (var doc in existingDocs.docs) {
    //    batch.delete(doc.reference);
    // }

    // Thêm dữ liệu mới
    for (var docData in knowledgeDocuments) {
      // Sử dụng Map.from để tạo bản sao, tránh modify list gốc nếu Timestamp.now() thay đổi
      final docRef = firestore.collection('knowledge_documents').doc();
      batch.set(docRef, Map.from(docData));
    }

    // Commit batch
    await batch.commit();
    print('Đã seed ${knowledgeDocuments.length} tài liệu vào cơ sở tri thức mẫu');
  }
}