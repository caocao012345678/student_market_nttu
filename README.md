# Student Market NTTU

Sàn mua bán hàng dành cho sinh viên Trường Đại học Nguyễn Tất Thành. Ứng dụng được phát triển bằng Flutter, Firebase và các công nghệ hiện đại.

## Tổng Quan

Student Market NTTU là nền tảng thương mại điện tử dành riêng cho cộng đồng sinh viên NTTU, giúp sinh viên có thể mua bán, trao đổi sản phẩm một cách thuận tiện trong khuôn viên trường. Ứng dụng tích hợp hệ thống điểm thưởng NTT Point, chatbot hỗ trợ AI, và nhiều tính năng đặc biệt khác.

## Cấu Hình Môi Trường

Ứng dụng sử dụng biến môi trường để cấu hình các dịch vụ AI và xử lý sản phẩm. Hãy tạo file `.env` trong thư mục gốc với các biến sau:

```
LM_API_LLM_IDENTIFIER=oh-dcft-v3.1-gemini-1.5-pro-i1
LM_API_VLM_IDENTIFIER=moondream2
LM_LOCAL_SERVER=http://your-lm-studio-ip:1234/v1/models
```

**Lưu ý quan trọng:** AI Agent kiểm duyệt sản phẩm yêu cầu kết nối với LM Studio. Nếu không thể kết nối đến LM Studio, tất cả sản phẩm sẽ được đánh dấu để kiểm duyệt thủ công thay vì tự động duyệt. Đây là biện pháp an toàn để tránh việc duyệt sản phẩm không đúng khi không có AI hỗ trợ.

## Chức Năng Chính

### 1. Quản lý người dùng
- **Đăng ký và đăng nhập**:
  - Đăng nhập bằng email/mật khẩu hoặc tài khoản Google
  - Xác thực email người dùng để đảm bảo tài khoản hợp lệ
  - Lưu trữ thông tin đăng nhập với SharedPreferences cho đăng nhập tự động
  - Mã hóa mật khẩu bằng thuật toán BCrypt cùng với Firebase Authentication
  - Phát hiện và ngăn chặn hoạt động đăng nhập bất thường

- **Hồ sơ người dùng**:
  - Hỗ trợ tải lên hình đại diện và lưu trữ trên Firebase Storage
  - Lưu trữ thông tin cá nhân trong Firestore collection 'users'
  - Quản lý quyền truy cập dữ liệu với Firebase Security Rules
  - Đồng bộ hóa thông tin hồ sơ theo thời gian thực

- **Quản lý địa chỉ**:
  - Lưu trữ nhiều địa chỉ giao hàng trong subcollection 'addresses'
  - Đánh dấu địa chỉ mặc định và hiển thị trong quá trình thanh toán
  - Tự động xác định vị trí hiện tại qua GPS (yêu cầu cấp quyền)
  - Xác thực địa chỉ để đảm bảo nằm trong phạm vi khu vực NTTU

- **Bảo mật**:
  - Xác thực hai yếu tố sử dụng SMS (tùy chọn)
  - Khóa tài khoản tạm thời sau nhiều lần đăng nhập thất bại
  - Phiên đăng nhập tự động hết hạn sau 30 ngày
  - Lịch sử đăng nhập có thể xem và quản lý trong phần cài đặt

- **Theo dõi hoạt động**:
  - Lưu trữ nhật ký hoạt động người dùng trong subcollection 'activity_logs'
  - Theo dõi sản phẩm đã xem gần đây (lưu trên thiết bị và đồng bộ khi online)
  - Thống kê hành vi người dùng để cải thiện trải nghiệm
  - Tính năng "tiếp tục xem" giúp quay lại sản phẩm đã xem trước đó

### 2. Quản lý sản phẩm
- **Đăng sản phẩm**:
  - Form đăng sản phẩm với validation dữ liệu đầu vào
  - Tải lên tối đa 10 hình ảnh sản phẩm với khả năng nén và tối ưu hóa
  - Hỗ trợ tải lên video ngắn demo sản phẩm (tối đa 30 giây)
  - Soạn thảo mô tả sản phẩm với trình soạn thảo rich text
  - Gán tự động vị trí bán hàng dựa trên GPS hoặc địa chỉ người dùng
  - Gợi ý danh mục dựa trên nội dung mô tả và tiêu đề

- **Phân loại sản phẩm**:
  - Hệ thống đa cấp với danh mục chính và danh mục con
  - Loại sản phẩm đặc biệt "Đồ tặng" tích hợp với hệ thống NTT Point
  - Các thẻ tag để phân loại chi tiết hơn
  - Khả năng tìm kiếm sản phẩm theo nhiều tiêu chí phân loại
  - Gợi ý sản phẩm tương tự dựa trên phân loại và lịch sử xem

- **Kiểm duyệt nội dung**:
  - Quy trình kiểm duyệt tự động sử dụng Firebase Functions
  - Phân tích hình ảnh để phát hiện nội dung không phù hợp
  - Kiểm tra từ khóa cấm trong tiêu đề và mô tả
  - Hệ thống điểm uy tín ảnh hưởng đến thời gian kiểm duyệt
  - Thông báo kết quả kiểm duyệt qua Firebase Cloud Messaging

- **Trạng thái sản phẩm**:
  - Các trạng thái: đang chờ duyệt, đã duyệt, bị từ chối, đã bán, đã ẩn
  - Tự động cập nhật trạng thái khi hoàn tất đơn hàng
  - Tái đăng sản phẩm đã bán với thông tin được giữ lại
  - Theo dõi lượt xem và tương tác với sản phẩm
  - Tự động ẩn sản phẩm không hoạt động sau 30 ngày

- **Tìm kiếm và lọc**:
  - Tìm kiếm theo từ khóa với độ chính xác cao
  - Tìm kiếm vector sử dụng Pinecone để tìm sản phẩm tương tự
  - Bộ lọc đa tiêu chí: giá, danh mục, trạng thái, khoảng cách
  - Sắp xếp kết quả theo mức độ phù hợp, giá, thời gian đăng
  - Lưu lịch sử tìm kiếm và bộ lọc đã sử dụng

- **Quản lý bán hàng**:
  - Bảng điều khiển người bán với số liệu thống kê
  - Theo dõi hiệu suất từng sản phẩm (lượt xem, tương tác, hỏi mua)
  - Cảnh báo khi sản phẩm sắp hết hạn hiển thị
  - Gợi ý cải thiện thông tin sản phẩm để tăng khả năng bán
  - Tự động đề xuất giá dựa trên sản phẩm tương tự

### 3. Mua sắm
- **Duyệt và tìm kiếm sản phẩm**:
  - Giao diện dạng lưới và danh sách với Flutter StaggeredGridView
  - Duyệt sản phẩm theo danh mục với UI trượt ngang
  - Bộ lọc đa tầng với việc lựa chọn nhiều tiêu chí cùng lúc
  - Tìm kiếm theo từ khóa với highlight kết quả tìm kiếm
  - Tìm kiếm bằng giọng nói sử dụng Flutter SpeechRecognition
  - Gợi ý tìm kiếm dựa trên lịch sử và xu hướng phổ biến

- **Trang chi tiết sản phẩm**:
  - Carousel hình ảnh sản phẩm với hiệu ứng zoom và vuốt
  - Phát video demo tự động với tùy chọn tắt/bật
  - Hiển thị thông tin người bán với đánh giá và nút liên hệ trực tiếp
  - Nút "Thêm vào giỏ hàng" và "Mua ngay" với hiệu ứng ripple
  - Phần mô tả sản phẩm với định dạng rich text và mở rộng/thu gọn
  - Sản phẩm tương tự hiển thị dưới dạng carousel ngang
  - Phần đánh giá sản phẩm với khả năng lọc theo số sao

- **Danh sách yêu thích**:
  - Thêm/xóa sản phẩm khỏi danh sách yêu thích với animation trái tim
  - Đồng bộ danh sách yêu thích giữa các thiết bị
  - Thông báo khi sản phẩm yêu thích thay đổi giá hoặc trạng thái
  - Sắp xếp danh sách yêu thích theo nhiều tiêu chí
  - Chức năng so sánh sản phẩm yêu thích trước khi quyết định

- **Giỏ hàng thông minh**:
  - Lưu trữ local với SQLite và đồng bộ với Firestore
  - Tự động cập nhật giá và trạng thái sản phẩm trong giỏ hàng
  - Tính toán tổng tiền và áp dụng NTT Point ngay trong giỏ hàng
  - Kiểm tra tồn kho trước khi thêm vào giỏ
  - Lưu giỏ hàng khi chưa đăng nhập và khôi phục sau khi đăng nhập
  - Đề xuất các sản phẩm bổ sung dựa trên nội dung giỏ hàng

- **Quy trình thanh toán**:
  - Giao diện thanh toán một trang với tất cả thông tin cần thiết
  - Chọn địa chỉ giao hàng từ danh sách hoặc thêm địa chỉ mới
  - Tính phí giao hàng dựa trên khoảng cách
  - Áp dụng NTT Point với thanh trượt tùy chỉnh số điểm sử dụng
  - Xác nhận đơn hàng với tổng quan chi tiết
  - Theo dõi trạng thái đơn hàng theo thời gian thực
  - Tạo mã QR cho việc xác nhận giao hàng

### 4. NTT Point
- **Cơ chế hoạt động**:
  - Triển khai dưới dạng ChangeNotifier trong NTTPointService
  - Lưu trữ giao dịch điểm trong collection 'nttPointTransactions'
  - Mỗi điểm có thời hạn 6 tháng tính từ ngày nhận
  - Các loại giao dịch: kiếm được (earned), đã dùng (spent), bị trừ (deducted), hoàn lại (refunded), hết hạn (expired)
  - Thiết kế database tối ưu cho truy vấn lịch sử điểm và tính toán số dư

- **Kiếm điểm**:
  - Đăng sản phẩm "Đồ tặng" được cộng +10 NTT Point/sản phẩm
  - Điểm thưởng mỗi khi hoàn thành đơn hàng thành công
  - Chương trình giới thiệu bạn: +5 điểm cho mỗi người dùng mới
  - Hoàn thành khảo sát và đánh giá trong ứng dụng
  - Điểm thưởng cho người dùng tích cực hàng tháng

- **Sử dụng điểm**:
  - Giảm giá khi mua hàng (10 điểm = 10.000 VNĐ)
  - Tối đa 50% giá trị đơn hàng có thể thanh toán bằng điểm
  - Ưu tiên sử dụng điểm sắp hết hạn trước
  - Tự động tính toán số điểm tối ưu để sử dụng
  - Hiển thị số tiền tiết kiệm khi sử dụng điểm

- **Quản lý điểm hết hạn**:
  - Thuật toán kiểm tra tự động điểm sắp hết hạn
  - Thông báo trước 15 ngày khi điểm sắp hết hạn
  - Tạo giao dịch điểm hết hạn tự động khi quá thời hạn
  - Hiển thị biểu đồ phân tích điểm theo thời gian
  - Đề xuất cách sử dụng điểm sắp hết hạn

- **Lịch sử giao dịch**:
  - Hiển thị đầy đủ lịch sử giao dịch với mô tả chi tiết
  - Lọc theo loại giao dịch và khoảng thời gian
  - Biểu đồ thống kê xu hướng sử dụng điểm
  - Xuất báo cáo giao dịch dưới dạng PDF
  - Tìm kiếm giao dịch theo mô tả hoặc số điểm

- **Tích hợp hệ thống**:
  - Đồng bộ số dư điểm với document 'users' trong Firestore
  - Xử lý transaction để đảm bảo tính nhất quán dữ liệu
  - Cache số dư điểm cục bộ để giảm truy vấn database
  - Hook vào các dịch vụ khác (OrderService, ProductService) thông qua Provider
  - Kiểm tra số dư điểm khi thực hiện giao dịch thanh toán

### 5. Trò chuyện và hỗ trợ
- **Hệ thống tin nhắn**:
  - Kiến trúc real-time chat sử dụng Firestore collection 'chats' và 'chatMessages'
  - Mô hình dữ liệu tối ưu: message fan-out pattern để hiển thị nhanh
  - Hỗ trợ tin nhắn văn bản, hình ảnh, và liên kết sản phẩm
  - Thông báo đã đọc và đang gõ với người dùng trực tuyến
  - Tự động tạo cuộc trò chuyện khi liên hệ về sản phẩm
  - Tính năng blocking người dùng không mong muốn
  - Lưu trữ và tải lịch sử tin nhắn theo trang (pagination)

- **Chatbot AI**:
  - Phân loại tin nhắn bằng Google Gemini AI qua 8 loại: chào hỏi, tạm biệt, tìm kiếm sản phẩm, trợ giúp, tài khoản, đơn hàng, đánh giá, trò chuyện
  - Kiến trúc RAG (Retrieval-Augmented Generation) cho câu trả lời chính xác
  - Vector database Pinecone lưu trữ kiến thức với kích thước nhúng 768-d
  - Custom prompt template tùy chỉnh theo từng loại câu hỏi
  - Xử lý ngôn ngữ tự nhiên tiếng Việt đặc thù cho môi trường NTTU
  - Lưu trữ lịch sử trò chuyện trong Firebase để duy trì ngữ cảnh
  - Cache câu trả lời phổ biến để giảm độ trễ và chi phí API

- **Tìm kiếm sản phẩm qua chatbot**:
  - Phân tích mô tả sản phẩm người dùng cần tìm
  - Trích xuất thuộc tính (attributes extraction) từ văn bản đầu vào
  - Tạo vector embedding cho câu hỏi tìm kiếm
  - Tìm kiếm sản phẩm tương tự bằng thuật toán cosine similarity
  - Hiển thị kết quả dưới dạng carousel có thể nhấp để xem chi tiết
  - Cải thiện kết quả tìm kiếm dựa trên phản hồi người dùng
  - Kết hợp kết quả từ cả vector search và từ khóa truyền thống

- **Knowledge Base (Cơ sở kiến thức)**:
  - Cấu trúc dữ liệu kiến thức phân cấp trong Firestore collection 'knowledgeBase'
  - Tự động cập nhật cơ sở kiến thức từ trang admin
  - Quản lý phiên bản để theo dõi thay đổi nội dung
  - Phân loại kiến thức theo danh mục và thẻ tag
  - Chức năng tìm kiếm nội bộ trong cơ sở kiến thức
  - Đánh giá mức độ hữu ích của câu trả lời từ cơ sở kiến thức
  - Cơ chế đề xuất nội dung liên quan tự động

- **Giao diện người dùng chatbot**:
  - Thiết kế bubble chat với animation typing when loading
  - Hỗ trợ hiển thị rich content (hình ảnh, carousel, button)
  - Giao diện đáp ứng (responsive) trên cả điện thoại và máy tính bảng
  - Chủ đề tối/sáng theo cài đặt hệ thống
  - Chức năng tìm kiếm trong lịch sử trò chuyện
  - Tích hợp emoji picker và attachment options
  - Thanh công cụ gợi ý câu hỏi phổ biến

- **Hệ thống hỗ trợ**:
  - Kênh hỗ trợ riêng cho từng loại vấn đề
  - Theo dõi trạng thái yêu cầu hỗ trợ
  - Tự động chuyển tiếp vấn đề phức tạp đến admin
  - Đánh giá mức độ hài lòng sau khi nhận hỗ trợ
  - Form báo cáo lỗi với chức năng đính kèm ảnh chụp màn hình
  - Tự động gợi ý giải pháp dựa trên mô tả vấn đề
  - Hệ thống FAQ được cập nhật thường xuyên

### 6. Đánh giá và xếp hạng
- **Hệ thống đánh giá sản phẩm**:
  - Mô hình dữ liệu đánh giá lưu trong collection 'reviews' với tham chiếu đến sản phẩm và đơn hàng
  - Đánh giá từ 1-5 sao kết hợp với nhận xét văn bản
  - Hỗ trợ đính kèm hình ảnh trong đánh giá (tối đa 3 ảnh)
  - Tự động kiểm duyệt nội dung đánh giá bằng RegEx và từ khóa cấm
  - Tính năng "đánh giá có hữu ích" để cộng đồng bình chọn
  - Phân tích sentiment tự động từ nội dung đánh giá
  - Cập nhật điểm trung bình sản phẩm real-time dùng Firebase Functions

- **Xếp hạng người dùng**:
  - Hệ thống điểm uy tín dựa trên hoạt động mua bán
  - Cấp bậc người dùng: Mới, Đồng, Bạc, Vàng, Kim cương
  - Badge hiển thị trên hồ sơ và bên cạnh tên trong các tương tác
  - Tính toán tự động điểm uy tín dựa trên nhiều yếu tố
  - Tác động của điểm uy tín đến khả năng hiển thị sản phẩm
  - Cơ chế chống gian lận trong hệ thống đánh giá
  - Quyền lợi đặc biệt cho người dùng cấp cao

- **Hiển thị đánh giá**:
  - Trang tổng quan đánh giá với biểu đồ phân phối số sao
  - Lọc đánh giá theo số sao, thời gian, có/không có ảnh
  - Sắp xếp theo mức độ hữu ích, mới nhất, điểm đánh giá
  - Hiển thị đánh giá nổi bật (tích cực và tiêu cực) ở đầu
  - Phân trang (pagination) danh sách đánh giá để tối ưu hiệu suất
  - Chức năng báo cáo đánh giá không phù hợp
  - Widget tổng hợp đánh giá nhúng vào trang sản phẩm

- **Trả lời đánh giá**:
  - Người bán có thể trả lời đánh giá của người mua
  - Thông báo cho người mua khi có phản hồi từ người bán
  - Hiển thị phản hồi ngay dưới đánh giá gốc
  - Giới hạn một phản hồi cho mỗi đánh giá
  - Kiểm duyệt nội dung phản hồi tương tự như đánh giá
  - Đánh dấu phản hồi đã giải quyết vấn đề
  - Tác động của phản hồi đến điểm uy tín người bán

- **Nhắc nhở đánh giá**:
  - Gửi thông báo tự động sau 3 ngày hoàn thành đơn hàng
  - Hiển thị banner nhắc nhở trong ứng dụng
  - Email nhắc nhở có chứa liên kết trực tiếp đến form đánh giá
  - Tích hợp với hệ thống NTT Point - thưởng điểm khi đánh giá
  - Nhắc nhở lịch sự với tùy chọn "không hiển thị lại"
  - Theo dõi tỉ lệ hoàn thành đánh giá để cải thiện quy trình
  - A/B testing các phương pháp nhắc nhở khác nhau

### 7. Thông báo
- **Kiến trúc thông báo**:
  - Triển khai Firebase Cloud Messaging (FCM) cho cả nền tảng Android và iOS
  - Lưu token thiết bị trong Firestore collection 'deviceTokens'
  - Phân loại thông báo: giao dịch, tương tác, hệ thống, quảng cáo
  - Quản lý trạng thái đọc/chưa đọc trong collection 'notifications'
  - Background service xử lý thông báo khi ứng dụng đóng
  - Local notifications cho các sự kiện không cần server
  - Kết hợp FCM với Firebase Functions để gửi thông báo tự động

- **Loại thông báo**:
  - **Đơn hàng**: Đặt hàng thành công, xác nhận đơn, chuẩn bị giao, đã giao, hủy đơn
  - **Tin nhắn**: Tin nhắn mới, tin nhắn chưa đọc (gom nhóm)
  - **Sản phẩm**: Kiểm duyệt xong, sản phẩm sắp hết hạn, có người quan tâm
  - **NTT Point**: Điểm mới, điểm sắp hết hạn, điểm đã sử dụng
  - **Hệ thống**: Cập nhật ứng dụng, bảo trì hệ thống, thông báo bảo mật
  - **Khuyến mãi**: Khuyến mãi theo mùa, sự kiện đặc biệt, flash sale

- **Giao diện thông báo**:
  - Màn hình danh sách thông báo với pull-to-refresh
  - Badge counter trên icon thông báo hiển thị số lượng chưa đọc
  - Phân tab thông báo theo loại để dễ theo dõi
  - Hiệu ứng đánh dấu đã đọc tự động khi xem
  - Tùy chọn xóa thông báo riêng lẻ hoặc tất cả
  - Lazy loading danh sách thông báo để tối ưu hiệu suất
  - Thông báo đẩy chứa deep link đến màn hình liên quan

- **Tùy chỉnh thông báo**:
  - Màn hình cài đặt riêng cho từng loại thông báo
  - Tùy chọn tắt/bật thông báo push cho từng loại
  - Lịch trình "không làm phiền" với khung giờ tùy chỉnh
  - Tùy chỉnh âm thanh thông báo theo loại
  - Lưu tùy chọn trên cả local và server để đồng bộ giữa các thiết bị
  - Gợi ý bật thông báo cho các tính năng quan trọng
  - Cài đặt kênh thông báo riêng trên Android 8.0+

- **Xử lý và theo dõi**:
  - Tracking tỷ lệ mở thông báo (open rate) cho từng loại
  - A/B testing nội dung thông báo để tối ưu sự tương tác
  - Phát hiện và xử lý token FCM hết hạn
  - Batch processing để gửi thông báo hàng loạt hiệu quả
  - Rate limiting để tránh gửi quá nhiều thông báo
  - Tự động gom nhóm thông báo cùng loại
  - Analytics về hiệu quả của từng loại thông báo

### 8. Vận chuyển
- **Đăng ký shipper**:
  - Form đăng ký với xác minh danh tính sinh viên NTTU
  - Tải lên CMND/CCCD và thẻ sinh viên để xác thực
  - Quy trình phê duyệt 2 bước: tự động và thủ công
  - Lưu trữ thông tin shipper trong collection 'shippers'
  - Yêu cầu xác minh số điện thoại qua SMS
  - Thông báo kết quả phê duyệt qua push notification
  - Thiết lập khu vực hoạt động và thời gian làm việc

- **Giao diện quản lý shipper**:
  - Bảng điều khiển tổng quan với số liệu thống kê
  - Danh sách đơn hàng chờ giao trong khu vực
  - Bản đồ trực quan hiển thị vị trí đơn hàng
  - Bộ lọc đơn hàng theo khoảng cách, giá trị, loại hàng
  - Chức năng nhận/từ chối đơn hàng
  - Theo dõi thu nhập và lịch sử giao hàng
  - Tính năng báo cáo sự cố trong quá trình giao hàng

- **Hệ thống phân phối đơn hàng**:
  - Thuật toán matching đơn hàng với shipper dựa trên:
    - Khoảng cách đến người gửi/nhận
    - Đánh giá của shipper
    - Tỷ lệ hoàn thành đơn hàng
    - Thời gian hoạt động
  - Tự động thông báo cho shipper khi có đơn hàng phù hợp
  - Hệ thống ưu tiên đơn hàng dựa trên thời gian chờ
  - Tính toán phí giao hàng dựa trên khoảng cách và khối lượng
  - Cơ chế backup khi không có shipper nhận đơn
  - Xử lý đơn hàng đặc biệt (hàng dễ vỡ, giá trị cao)

- **Theo dõi đơn hàng**:
  - Cập nhật trạng thái đơn hàng theo thời gian thực với Firestore
  - Hiển thị vị trí shipper trên bản đồ (với sự đồng ý của shipper)
  - Push notification cho các cột mốc quan trọng
  - Ước tính thời gian giao hàng dựa trên khoảng cách và lịch sử
  - Chức năng liên hệ trực tiếp với shipper qua chat/gọi điện
  - Bảo vệ thông tin cá nhân của cả người mua và shipper
  - Timeline trực quan cho quá trình giao hàng

- **Xác nhận giao hàng**:
  - Mã xác nhận OTP gửi qua SMS để xác minh giao hàng
  - Quét mã QR từ ứng dụng người mua để xác nhận giao dịch
  - Yêu cầu chụp ảnh bằng chứng giao hàng trong trường hợp cần thiết
  - Chữ ký điện tử của người nhận trên màn hình cảm ứng
  - Nhập feedback ngay sau khi nhận hàng
  - Xác nhận tự động sau thời gian chờ nếu người nhận không phản hồi
  - Ghi nhận thời gian và vị trí GPS khi giao hàng

- **Hệ thống đánh giá shipper**:
  - Đánh giá shipper sau khi hoàn tất giao hàng
  - Tiêu chí đánh giá: đúng giờ, thái độ, cẩn thận với hàng hóa
  - Hệ thống xếp hạng shipper dựa trên điểm đánh giá trung bình
  - Cơ chế khen thưởng cho shipper có đánh giá cao
  - Phát hiện đánh giá bất thường để tránh gian lận
  - Ảnh hưởng của đánh giá đến ưu tiên nhận đơn hàng
  - Cảnh báo và biện pháp với shipper có đánh giá thấp liên tục

### 9. Quản lý đơn hàng
- **Tạo đơn hàng**:
  - Quy trình thanh toán một trang với form validation
  - Tự động tạo đơn hàng trong collection 'orders' khi xác nhận
  - Tính toán thuế và phí giao hàng dựa trên địa chỉ và giá trị
  - Áp dụng NTT Point với quy đổi linh hoạt
  - Kiểm tra tồn kho và khóa sản phẩm khi xác nhận đơn
  - Tạo mã đơn hàng duy nhất theo format OM-YYMMDD-XXXXX
  - Lưu toàn bộ snapshot thông tin sản phẩm để tránh thay đổi sau khi đặt hàng

- **Trạng thái đơn hàng**:
  - Máy trạng thái (state machine) đơn hàng với các bước:
    - Đang xử lý (processing)
    - Đã xác nhận (confirmed)
    - Đang chuẩn bị (preparing)
    - Đang giao (shipping)
    - Đã giao (delivered)
    - Đã hủy (cancelled)
    - Hoàn thành (completed)
  - Kiểm tra ràng buộc khi chuyển trạng thái
  - Ghi nhật ký (logging) mỗi khi thay đổi trạng thái
  - Thông báo tự động cho các bên liên quan
  - Thời gian giới hạn cho mỗi trạng thái để tránh treo đơn

- **Quản lý hủy đơn**:
  - Chính sách hủy đơn với các lý do được định nghĩa sẵn
  - Giới hạn thời gian có thể hủy đơn (trước khi shipping)
  - Quy trình hoàn tiền/điểm tự động khi hủy đơn thành công
  - Notification cho cả người mua và người bán
  - Cập nhật trạng thái sản phẩm về "còn hàng" sau khi hủy
  - Phân tích lý do hủy đơn để cải thiện hệ thống
  - Chính sách đặc biệt cho người dùng hủy đơn thường xuyên

- **Lịch sử đơn hàng**:
  - Hiển thị tất cả đơn hàng với bộ lọc theo trạng thái và thời gian
  - Chi tiết đơn hàng với timeline trực quan các sự kiện
  - Khả năng đặt lại đơn hàng với một cú nhấp
  - Xuất hóa đơn PDF cho mục đích kế toán
  - Tìm kiếm đơn hàng theo mã, sản phẩm hoặc người bán
  - Phân trang (pagination) để tải hiệu quả đơn hàng số lượng lớn
  - Đồng bộ lịch sử đơn hàng giữa các thiết bị

- **Hóa đơn và thanh toán**:
  - Tạo hóa đơn điện tử với thông tin chi tiết
  - Hỗ trợ thanh toán COD (tiền mặt khi nhận hàng)
  - Tích hợp quản lý thanh toán qua NTT Point
  - Thiết kế hóa đơn chuyên nghiệp với thông tin đầy đủ
  - Gửi email xác nhận đơn hàng tự động
  - Lưu trữ và truy xuất hóa đơn trong tài khoản người dùng
  - Tuân thủ quy định về hóa đơn điện tử

- **Analytics đơn hàng**:
  - Dashboard thống kê đơn hàng cho người bán
  - Biểu đồ xu hướng đơn hàng theo thời gian
  - Phân tích sản phẩm bán chạy và ít người mua
  - Tỷ lệ hoàn thành đơn hàng và lý do hủy đơn
  - Thống kê thời gian xử lý trung bình của mỗi giai đoạn
  - Phân tích giá trị đơn hàng trung bình (AOV)
  - Tương quan giữa đánh giá sản phẩm và đơn hàng

### 10. Quản trị viên
- **Giao diện quản trị**:
  - Dashboard với thống kê tổng quan hệ thống
  - Giao diện riêng biệt từ ứng dụng chính với xác thực admin
  - Menu điều hướng đa cấp cho quản lý các mục
  - Biểu đồ theo dõi hoạt động theo thời gian thực với Firebase Analytics
  - Responsive design cho cả desktop và thiết bị di động
  - Quản lý nhiều tài khoản admin với phân quyền chi tiết
  - Lịch sử thao tác admin với khả năng rollback

- **Kiểm duyệt sản phẩm**:
  - Hệ thống hàng đợi kiểm duyệt với cơ chế ưu tiên
  - Kiểm duyệt tự động cấp 1 dùng Firebase Functions:
    - Phân tích hình ảnh với Google Cloud Vision API
    - Kiểm tra từ khóa cấm và nội dung không phù hợp
    - Tính điểm rủi ro cho từng sản phẩm
  - Giao diện kiểm duyệt thủ công cho sản phẩm cần xem xét
  - Tùy chọn từ chối với lý do cụ thể và gợi ý sửa đổi
  - Lưu trữ lịch sử kiểm duyệt trong subcollection 'moderationHistory'
  - Thống kê tỷ lệ duyệt/từ chối theo danh mục và người bán
  - Cải thiện độ chính xác kiểm duyệt tự động theo thời gian

- **Quản lý danh mục**:
  - Trình soạn thảo cây danh mục đa cấp (tối đa 3 cấp)
  - Thêm/sửa/xóa/sắp xếp danh mục với giao diện kéo thả
  - Tùy chỉnh icon và hình ảnh cho từng danh mục
  - Đặt quy tắc đặc biệt cho danh mục (ví dụ: "Đồ tặng")
  - Phân tích hiệu suất từng danh mục (lượt xem, tỷ lệ chuyển đổi)
  - Quản lý thuộc tính (attributes) theo danh mục sản phẩm
  - Thiết lập danh mục nổi bật trên trang chủ

- **Báo cáo và thống kê**:
  - Dashboard phân tích chi tiết với các chỉ số quan trọng:
    - Tổng số người dùng và tăng trưởng
    - Số lượng sản phẩm theo danh mục và trạng thái
    - Giá trị giao dịch và tỷ lệ hoàn thành đơn hàng
    - Thời gian trung bình từ đăng tin đến bán được
  - Xuất báo cáo định kỳ dưới dạng PDF/Excel
  - Biểu đồ so sánh hiệu suất theo khoảng thời gian
  - Bản đồ nhiệt các khu vực giao dịch sôi động
  - Phân tích hành vi người dùng với Firebase Analytics
  - Thống kê lỗi và crash report từ người dùng
  - Dự báo xu hướng dựa trên dữ liệu lịch sử

- **Quản lý người dùng**:
  - Xem và tìm kiếm người dùng theo nhiều tiêu chí
  - Kiểm tra và xác minh tài khoản sinh viên
  - Khóa/mở khóa tài khoản người dùng vi phạm
  - Quản lý quyền hạn người dùng (user, seller, shipper, admin)
  - Thiết lập hạn chế cho tài khoản đáng ngờ
  - Xem lịch sử hoạt động của người dùng
  - Gửi thông báo riêng hoặc hàng loạt đến người dùng

- **Cấu hình hệ thống**:
  - Thiết lập tham số hệ thống NTT Point (tỷ lệ quy đổi, thời hạn)
  - Cấu hình giới hạn upload (kích thước file, số lượng ảnh)
  - Quản lý Firebase Remote Config cho các tính năng A/B testing
  - Cài đặt bảo trì hệ thống với thông báo tự động
  - Quản lý các biến môi trường quan trọng
  - Thiết lập luật phân phối đơn hàng cho shipper
  - Cấu hình tham số chatbot và AI

## Công Nghệ Sử Dụng

- **Frontend**: 
  - **Flutter Framework**:
    - Version: 3.1+ với null safety
    - Sử dụng Flutter Widgets cho UI đa nền tảng
    - Custom themes với Material Design 3
    - Tối ưu performance với widget caching và lazy loading
    - Animation system cho trải nghiệm mượt mà
    - Internationalization hỗ trợ tiếng Việt và tiếng Anh
  
  - **State Management**:
    - Provider pattern là giải pháp chính
    - ChangeNotifier cho các service class và model
    - Consumer và Selector widgets để tối ưu re-renders
    - Kiến trúc repository-service rõ ràng
    - Flutter Hooks cho các widget có state phức tạp
    - Đồng bộ state giữa các screen với singleton pattern
  
  - **UI/UX**:
    - Custom widgets độc quyền NTTU
    - Responsive UI sử dụng MediaQuery và LayoutBuilder
    - Adaptive design cho cả iOS và Android
    - Dark mode và light mode với ColorScheme
    - Skeleton loading UI khi fetch dữ liệu
    - Hero animations cho chuyển đổi mượt giữa các màn hình

- **Backend**: 
  - **Firebase Authentication**:
    - Đa phương thức xác thực (email/password, Google)
    - Custom authentication claims cho phân quyền
    - Email verification flow
    - Password reset và account recovery
    - Bảo mật với rate limiting
  
  - **Cloud Firestore**:
    - Schema NoSQL tối ưu cho thời gian thực
    - Composite indexes cho truy vấn phức tạp
    - Firestore Rules với regular expressions và security functions
    - Caching strategy cho collection lớn
    - Transaction và batch operations đảm bảo tính nhất quán
    - Phân trang hiệu quả với cursor pagination
  
  - **Firebase Storage**:
    - Lưu trữ ảnh sản phẩm và avatar người dùng
    - Tự động nén và resize hình ảnh với Firebase Functions
    - Bảo mật với signed URLs
    - Cache-Control headers cho tối ưu performance
    - Lifecycle rules tự động xóa file không sử dụng
  
  - **Firebase Functions**:
    - Serverless architecture đảo đảm khả năng mở rộng
    - Triggers cho Firestore, Auth, và Storage
    - HTTP endpoints cho chatbot và tích hợp bên thứ ba
    - Scheduled functions cho tác vụ định kỳ
    - Kiểm duyệt nội dung tự động
    - Tối ưu hình ảnh và xử lý file
  
  - **Firebase Cloud Messaging**:
    - Multi-platform push notifications
    - Topic-based messaging cho thông báo nhóm
    - Token management cho cross-device sync
    - Notification channels trên Android
    - Silent notifications cho data sync

- **AI & ML**: 
  - **Google Gemini AI**:
    - API tích hợp qua Flutter HTTP client
    - Custom prompt templates theo ngữ cảnh
    - Streaming response khi chat
    - Temperature tuning cho độ sáng tạo/chính xác
    - Rate limiting và error handling
  
  - **Pinecone Vector Database**:
    - Vector embeddings cho sản phẩm và kiến thức
    - Cosine similarity search cho tìm kiếm ngữ nghĩa
    - Index management với Firebase Functions
    - Metadata filtering khi tìm kiếm
    - Hybrid search kết hợp vector và keyword
  
  - **RAG Architecture**:
    - Retrieval components tìm kiếm thông tin liên quan
    - Generation component tổng hợp câu trả lời
    - Context window optimization cho prompt hiệu quả
    - Citation và source tracking
    - Feedback loop để cải thiện chất lượng
  
  - **Computer Vision**:
    - Phân tích hình ảnh sản phẩm
    - Phát hiện nội dung không phù hợp
    - Image similarity search
    - OCR cho xác minh giấy tờ
    - Object detection trong ảnh sản phẩm

- **Thanh Toán**: 
  - **NTT Point System**:
    - Transaction-based architecture đảm bảo tính toàn vẹn
    - Expiry tracking với background jobs
    - Point redemption logic với validation
    - Realtime point balance
    - Point history với filtering
  
  - **COD (Cash on Delivery)**:
    - Order verification với OTP
    - Receipt generation
    - COD handling instructions cho shipper
    - Reconciliation system cho thanh toán
    - Refund workflow cho đơn hàng COD hủy

## Bố Cục Dự Án

### Cấu trúc thư mục

```
lib/
├── main.dart                # Điểm khởi đầu ứng dụng
├── firebase_options.dart    # Cấu hình Firebase tự động tạo
├── models/                  # Các lớp mô hình dữ liệu
│   ├── product.dart         # Mô hình sản phẩm
│   ├── user.dart            # Mô hình người dùng
│   ├── ntt_point_transaction.dart # Giao dịch NTT Point
│   ├── chat_message.dart    # Tin nhắn chat
│   ├── order.dart           # Đơn hàng
│   ├── review.dart          # Đánh giá
│   ├── category.dart        # Danh mục
│   ├── cart_item.dart       # Item trong giỏ hàng
│   ├── knowledge_base.dart  # Cơ sở kiến thức
│   ├── moderation_result.dart # Kết quả kiểm duyệt
│   └── shipper.dart         # Thông tin người giao hàng
├── screens/                 # Các màn hình UI
│   ├── splash_screen.dart       # Màn hình khởi động
│   ├── login_screen.dart        # Đăng nhập
│   ├── register_screen.dart     # Đăng ký
│   ├── home_screen.dart         # Trang chủ
│   ├── product_detail_screen.dart # Chi tiết sản phẩm
│   ├── add_product_screen.dart  # Thêm sản phẩm
│   ├── edit_product_screen.dart # Chỉnh sửa sản phẩm
│   ├── chatbot_screen.dart      # Màn hình chatbot
│   ├── profile_screen.dart      # Hồ sơ người dùng
│   ├── edit_profile_screen.dart # Chỉnh sửa hồ sơ
│   ├── cart_screen.dart         # Giỏ hàng
│   ├── checkout_screen.dart     # Thanh toán
│   ├── order_history_screen.dart # Lịch sử đơn hàng
│   ├── my_products_screen.dart  # Sản phẩm của tôi
│   ├── chat_list_screen.dart    # Danh sách chat
│   ├── chat_detail_screen.dart  # Chi tiết chat
│   ├── ntt_point_history_screen.dart # Lịch sử NTT Point
│   ├── favorite_products_screen.dart # Sản phẩm yêu thích
│   ├── register_shipper_screen.dart # Đăng ký shipper
│   ├── user_locations_screen.dart   # Địa chỉ người dùng
│   └── admin/                   # Màn hình quản trị
│       ├── dashboard_screen.dart      # Tổng quan
│       ├── product_moderation_screen.dart # Kiểm duyệt sản phẩm
│       ├── user_management_screen.dart    # Quản lý người dùng
│       ├── category_management_screen.dart # Quản lý danh mục
│       └── settings_screen.dart           # Cài đặt hệ thống
├── services/                # Các dịch vụ và logic nghiệp vụ
│   ├── auth_service.dart         # Dịch vụ xác thực
│   ├── user_service.dart         # Quản lý người dùng
│   ├── product_service.dart      # Quản lý sản phẩm
│   ├── ntt_point_service.dart    # Quản lý NTT Point
│   ├── chat_service.dart         # Dịch vụ chat
│   ├── chatbot_service.dart      # Dịch vụ chatbot AI
│   ├── cart_service.dart         # Quản lý giỏ hàng
│   ├── order_service.dart        # Quản lý đơn hàng
│   ├── payment_service.dart      # Thanh toán
│   ├── category_service.dart     # Quản lý danh mục
│   ├── review_service.dart       # Đánh giá
│   ├── favorites_service.dart    # Sản phẩm yêu thích
│   ├── shipper_service.dart      # Dịch vụ shipper
│   ├── product_moderation_service.dart # Kiểm duyệt sản phẩm
│   ├── knowledge_base_service.dart    # Cơ sở kiến thức
│   ├── firebase_messaging_service.dart # Dịch vụ thông báo
│   └── theme_service.dart        # Quản lý theme
├── widgets/                 # Các widget tái sử dụng
│   ├── common/                  # Widget dùng chung
│   │   ├── nttu_app_bar.dart       # App bar tùy chỉnh
│   │   ├── nttu_button.dart        # Button tùy chỉnh
│   │   ├── loading_indicator.dart  # Indicator loading
│   │   ├── error_dialog.dart       # Dialog lỗi
│   │   └── empty_state.dart        # Trạng thái trống
│   ├── product/                 # Widget cho sản phẩm
│   │   ├── product_card.dart       # Card sản phẩm
│   │   ├── product_grid.dart       # Grid sản phẩm
│   │   ├── product_filter.dart     # Bộ lọc sản phẩm
│   │   └── image_carousel.dart     # Carousel hình ảnh
│   ├── chat/                    # Widget cho chat
│   │   ├── message_bubble.dart     # Bubble tin nhắn
│   │   ├── chat_input.dart         # Input chat
│   │   └── typing_indicator.dart   # Chỉ báo đang gõ
│   └── checkout/                # Widget cho thanh toán
│       ├── address_selector.dart   # Chọn địa chỉ
│       ├── payment_method.dart     # Phương thức thanh toán
│       └── order_summary.dart      # Tóm tắt đơn hàng
├── utils/                   # Các tiện ích và hàm hỗ trợ
│   ├── constants.dart           # Các hằng số
│   ├── validators.dart          # Hàm kiểm tra đầu vào
│   ├── date_formatter.dart      # Định dạng ngày tháng
│   ├── image_utils.dart         # Xử lý hình ảnh
│   ├── location_utils.dart      # Xử lý vị trí
│   ├── string_utils.dart        # Xử lý chuỗi
│   ├── firebase_utils.dart      # Tiện ích Firebase
│   └── web_utils.dart           # Tiện ích dành cho web
└── data/                    # Dữ liệu tĩnh và constants
    ├── app_themes.dart          # Các theme ứng dụng
    ├── category_data.dart       # Dữ liệu danh mục
    ├── question_categories.dart # Danh mục câu hỏi chatbot
    └── provinces.dart           # Dữ liệu tỉnh thành VN
```

### Mô hình dữ liệu Firestore

**Cấu trúc collections chính:**

```
firestore/
├── users/                   # Thông tin người dùng
│   ├── {userId}/              # Document người dùng
│   │   ├── addresses/         # Subcollection địa chỉ
│   │   └── activity_logs/     # Subcollection nhật ký hoạt động
├── products/                # Sản phẩm
│   └── {productId}/           # Document sản phẩm
│       └── reviews/           # Subcollection đánh giá
├── orders/                  # Đơn hàng
│   └── {orderId}/             # Document đơn hàng
│       └── status_updates/    # Subcollection cập nhật trạng thái
├── categories/              # Danh mục sản phẩm
├── chats/                   # Cuộc trò chuyện
│   └── {chatId}/              # Document cuộc trò chuyện
│       └── messages/          # Subcollection tin nhắn
├── nttPointTransactions/    # Giao dịch NTT Point
├── deviceTokens/            # Token thiết bị cho FCM
├── notifications/           # Thông báo người dùng
├── shippers/                # Thông tin shipper
├── knowledgeBase/           # Cơ sở kiến thức chatbot
└── moderationResults/       # Kết quả kiểm duyệt
```

### Sitemap ứng dụng

```
Student Market NTTU
│
├── Màn hình đăng nhập/đăng ký
│   ├── Đăng nhập
│   ├── Đăng ký tài khoản mới
│   └── Khôi phục mật khẩu
│
├── Trang chính (TabBar)
│   ├── Trang chủ
│   │   ├── Banner quảng cáo
│   │   ├── Danh mục sản phẩm
│   │   ├── Sản phẩm mới đăng
│   │   ├── Sản phẩm khuyến mãi
│   │   └── Sản phẩm phổ biến
│   │
│   ├── Khám phá
│   │   ├── Tìm kiếm sản phẩm
│   │   ├── Lọc sản phẩm
│   │   └── Xem theo danh mục
│   │
│   ├── Thông báo
│   │   ├── Thông báo hệ thống
│   │   ├── Thông báo đơn hàng
│   │   ├── Thông báo tin nhắn
│   │   └── Thông báo khuyến mãi
│   │
│   ├── Tin nhắn
│   │   ├── Danh sách cuộc trò chuyện
│   │   └── Chatbot NTTU
│   │
│   └── Tài khoản
│       ├── Thông tin cá nhân
│       ├── NTT Point
│       ├── Đơn hàng của tôi
│       ├── Sản phẩm đã đăng
│       ├── Sản phẩm yêu thích
│       ├── Địa chỉ giao hàng
│       ├── Đăng ký làm shipper
│       └── Cài đặt
│
├── Luồng sản phẩm
│   ├── Chi tiết sản phẩm
│   │   ├── Thông tin sản phẩm
│   │   ├── Thông tin người bán
│   │   ├── Đánh giá sản phẩm
│   │   ├── Sản phẩm tương tự
│   │   └── Chat với người bán
│   │
│   ├── Đăng sản phẩm mới
│   │   ├── Chụp/chọn ảnh sản phẩm
│   │   ├── Nhập thông tin sản phẩm
│   │   ├── Chọn danh mục
│   │   └── Xác nhận đăng
│   │
│   ├── Quản lý sản phẩm
│   │   ├── Sản phẩm đang bán
│   │   ├── Sản phẩm chờ duyệt
│   │   ├── Sản phẩm đã bán
│   │   ├── Sản phẩm bị từ chối
│   │   └── Chỉnh sửa sản phẩm
│   │
│   └── Đánh giá sản phẩm
│
├── Luồng mua hàng
│   ├── Giỏ hàng
│   │   ├── Danh sách sản phẩm
│   │   ├── Cập nhật số lượng
│   │   └── Chọn sản phẩm thanh toán
│   │
│   ├── Thanh toán
│   │   ├── Chọn địa chỉ giao hàng
│   │   ├── Chọn phương thức thanh toán
│   │   ├── Áp dụng NTT Point
│   │   └── Xác nhận đơn hàng
│   │
│   └── Quản lý đơn hàng
│       ├── Đơn hàng chờ xác nhận
│       ├── Đơn hàng đang giao
│       ├── Đơn hàng đã nhận
│       ├── Đơn hàng đã hủy
│       └── Chi tiết đơn hàng
│
├── Luồng shipper
│   ├── Đăng ký làm shipper
│   ├── Quản lý đơn hàng cần giao
│   ├── Xác nhận giao hàng
│   └── Thống kê thu nhập
│
├── Luồng NTT Point
│   ├── Xem số dư điểm
│   ├── Lịch sử giao dịch điểm
│   ├── Điểm sắp hết hạn
│   └── Cách kiếm thêm điểm
│
└── Quản trị viên (chỉ dành cho admin)
    ├── Dashboard
    ├── Quản lý người dùng
    ├── Kiểm duyệt sản phẩm
    ├── Quản lý danh mục
    ├── Báo cáo thống kê
    └── Cài đặt hệ thống
```

#### Các luồng điều hướng chính

1. **Luồng đăng nhập/đăng ký**:
   - Splash Screen → Màn hình đăng nhập → Màn hình chính (nếu đăng nhập thành công)
   - Splash Screen → Màn hình đăng nhập → Đăng ký → Màn hình chính
   - Splash Screen → Màn hình đăng nhập → Quên mật khẩu → Đặt lại mật khẩu → Đăng nhập

2. **Luồng mua sắm**:
   - Trang chủ → Xem danh mục → Chi tiết sản phẩm → Thêm vào giỏ hàng → Thanh toán → Theo dõi đơn hàng → Đánh giá
   - Trang chủ → Tìm kiếm → Chi tiết sản phẩm → Mua ngay → Thanh toán → Theo dõi đơn hàng → Đánh giá

3. **Luồng bán hàng**:
   - Tài khoản → Sản phẩm đã đăng → Đăng sản phẩm mới → Chờ kiểm duyệt → Quản lý đơn hàng
   - Tài khoản → Sản phẩm đã đăng → Sửa sản phẩm → Chờ kiểm duyệt

4. **Luồng chat**:
   - Chi tiết sản phẩm → Chat với người bán → Danh sách chat
   - Tin nhắn → Danh sách chat → Chi tiết chat
   - Tin nhắn → Chatbot NTTU → Tìm kiếm sản phẩm qua chatbot → Chi tiết sản phẩm

5. **Luồng shipper**:
   - Tài khoản → Đăng ký làm shipper → Xác minh thông tin → Quản lý đơn hàng cần giao
   - Shipper Dashboard → Nhận đơn → Giao hàng → Xác nhận giao hàng

6. **Luồng quản trị**:
   - Đăng nhập tài khoản admin → Dashboard → Kiểm duyệt sản phẩm
   - Đăng nhập tài khoản admin → Dashboard → Quản lý người dùng

Sitemap này mô tả cấu trúc điều hướng chính của ứng dụng, giúp người dùng và nhà phát triển hiểu rõ luồng hoạt động và mối quan hệ giữa các màn hình trong ứng dụng Student Market NTTU.

## Hướng Dẫn Cài Đặt

### Yêu cầu hệ thống

- **Flutter SDK**: Phiên bản 3.1.3 trở lên
- **Dart SDK**: Phiên bản 3.1.3 trở lên
- **Firebase CLI**: Phiên bản mới nhất
- **Git**: Phiên bản mới nhất
- **IDE**: Android Studio hoặc VS Code

### Cài đặt môi trường

1. **Cài đặt Flutter SDK**:
   - Tải từ [flutter.dev](https://flutter.dev/docs/get-started/install)
   - Thêm Flutter vào PATH của hệ thống
   - Chạy `flutter doctor` để kiểm tra và cài đặt các dependencies

2. **Cài đặt Firebase CLI**:
   ```bash
   npm install -g firebase-tools
   ```

3. **Cài đặt IDE**:
   - Android Studio với Flutter và Dart plugins
   - Hoặc VS Code với Flutter và Dart extensions

### Các bước cài đặt dự án

1. **Clone repository**:
   ```bash
   git clone https://github.com/yourusername/student_market_nttu.git
   cd student_market_nttu
   ```

2. **Cài đặt dependencies**:
   ```bash
   flutter pub get
   ```

3. **Cấu hình Firebase**:
   - Đăng nhập Firebase CLI:
     ```bash
     firebase login
     ```
   - Tạo project Firebase mới hoặc sử dụng project hiện có:
     ```bash
     firebase projects:create student-market-nttu
     ```
   - Kích hoạt Firestore, Authentication, Storage, và Functions:
     ```bash
     firebase init firestore
     firebase init auth
     firebase init storage
     firebase init functions
     ```
   - Thêm ứng dụng vào project Firebase:
     ```bash
     flutter pub global activate flutterfire_cli
     flutterfire configure
     ```
   - Tạo Firestore indexes từ file cấu hình:
     ```bash
     firebase deploy --only firestore:indexes
     ```

4. **Cấu hình biến môi trường**:
   - Tạo file `.env` ở thư mục gốc với nội dung:
     ```
     GEMINI_API_KEY=your_gemini_api_key
     GEMINI_API_URL=https://generativelanguage.googleapis.com/v1beta/models
     GEMINI_MODEL=gemini-pro
     PINECONE_API_KEY=your_pinecone_api_key
     PINECONE_HOST=your_pinecone_host
     PINECONE_INDEX_NAME=student-market-knowledge-base
     ```

5. **Setup Pinecone Vector Database**:
   - Đăng ký tài khoản tại [pinecone.io](https://www.pinecone.io/)
   - Tạo index với kích thước vector 768-d và metric cosine
   - Cập nhật thông tin trong file .env

6. **Setup Google Gemini API**:
   - Đăng ký Google AI Studio tại [ai.google.dev](https://ai.google.dev/)
   - Tạo API key và cập nhật vào file .env

7. **Chạy ứng dụng**:
   ```bash
   flutter run
   ```

### Build cho production

1. **Android**:
   ```bash
   flutter build appbundle --release
   ```

2. **iOS**:
   ```bash
   flutter build ipa --release
   ```

3. **Web**:
   ```bash
   flutter build web --release
   ```

### CI/CD với GitHub Actions

- Repository chứa workflow files trong `.github/workflows/`
- Tự động test và build khi push hoặc tạo pull request
- Tự động deploy lên Firebase Hosting cho phiên bản web

## Đóng Góp

### Quy trình đóng góp

1. **Fork repository** và tạo branch mới từ `develop`
2. **Implement** tính năng hoặc sửa lỗi
3. **Push changes** lên fork của bạn
4. **Tạo Pull Request** vào branch `develop`

### Quy ước coding

- **Ngôn ngữ**: 
  - Sử dụng tiếng Việt cho comments và documentation
  - Sử dụng tiếng Anh cho tên biến, hàm và class

- **Định dạng code**:
  - Indentation: 2 spaces
  - Line length: Tối đa 100 ký tự
  - Sử dụng `dart format` để đảm bảo nhất quán
  - Tuân thủ [Effective Dart](https://dart.dev/guides/language/effective-dart)

- **Quy ước đặt tên**:
  - Classes & Widgets: Sử dụng PascalCase (ví dụ: `ProductCard`, `HomeScreen`)
  - Biến & Functions: Sử dụng camelCase (ví dụ: `getUserData`, `productList`)
  - Hằng số: Sử dụng SCREAMING_SNAKE_CASE (ví dụ: `MAX_RETRY_COUNT`)
  - Thuộc tính private: Sử dụng underscore prefix `_` (ví dụ: `_currentUser`)

- **Imports**:
  - Sắp xếp imports theo thứ tự:
    1. Dart packages
    2. Flutter packages
    3. Third-party packages
    4. Relative imports (project files)

- **State Management**:
  - Sử dụng Provider pattern làm giải pháp quản lý state chính
  - Extends `ChangeNotifier` cho tất cả services
  - Phân tách logic phức tạp thành các functions nhỏ
  - Tránh lưu state trong UI widgets

- **Error Handling**:
  - Sử dụng try-catch blocks cho các thao tác Firebase và ngoại lệ có thể xảy ra
  - Trả về thông báo lỗi thân thiện với người dùng cuối
  - Ghi log lỗi chi tiết cho phát triển

- **Testing**:
  - Viết unit tests cho logic nghiệp vụ phức tạp
  - Viết widget tests cho UI components quan trọng
  - Coverage tối thiểu 70% cho code mới

### Báo cáo lỗi

- Sử dụng GitHub Issues để báo cáo lỗi
- Mô tả chi tiết: bước tái tạo, kết quả mong đợi, kết quả thực tế
- Đính kèm screenshots hoặc videos nếu có thể
- Sử dụng template có sẵn cho báo cáo lỗi

## Giấy Phép

Copyright © 2024 Trường Đại học Nguyễn Tất Thành. Đã đăng ký bản quyền.

Phần mềm này được bảo vệ bởi luật bản quyền và chỉ được sử dụng trong phạm vi Trường Đại học Nguyễn Tất Thành. Nghiêm cấm sao chép, phân phối hoặc sửa đổi mà không có sự cho phép bằng văn bản.

## Hệ Thống Khuyến Nghị

### Hệ Thống Khuyến Nghị Nâng Cao Trong Student Market NTTU

Ứng dụng Student Market NTTU sử dụng hệ thống khuyến nghị sản phẩm thông minh được cá nhân hóa cho từng người dùng. Hệ thống này kết hợp các phương pháp lọc cộng tác (collaborative filtering) và lọc dựa trên nội dung (content-based filtering) với các yếu tố vị trí địa lý và giá cả.

#### Các yếu tố trong hệ thống khuyến nghị:

1. **Vị trí địa lý**
   - Tính toán khoảng cách giữa người dùng và người bán
   - Ưu tiên đề xuất sản phẩm từ người bán gần hơn

2. **Giá cả**
   - Phân tích giá trung bình của các sản phẩm đã xem
   - Đề xuất sản phẩm có mức giá tương tự

3. **Lịch sử xem**
   - Theo dõi các sản phẩm người dùng đã xem gần đây
   - Đề xuất các sản phẩm tương tự về danh mục và đặc điểm

4. **Danh mục ưa thích**
   - Người dùng có thể chọn các danh mục quan tâm trong hồ sơ
   - Hệ thống ưu tiên đề xuất từ các danh mục này

5. **Mức độ phổ biến**
   - Kết hợp lượt xem và lượt thích để đo lường mức độ phổ biến
   - Sử dụng như một yếu tố bổ sung khi cần

#### Thuật toán đề xuất:

Hệ thống sử dụng thuật toán tính điểm đa yếu tố (multi-factor scoring):

1. **Thu thập dữ liệu**: Lấy lịch sử xem, sở thích và vị trí của người dùng
2. **Tạo tập ứng viên**: Thu thập sản phẩm từ các danh mục tương tự, người bán đã xem và sản phẩm phổ biến
3. **Tính điểm**: Mỗi sản phẩm được tính điểm dựa trên 6 yếu tố:
   - Điểm danh mục (30%)
   - Điểm vị trí (30%)
   - Điểm mức giá (20%)
   - Điểm mới (15%)
   - Điểm người bán (10%)
   - Điểm phổ biến (10%)
4. **So sánh khoảng cách**: Khi các sản phẩm có điểm gần bằng nhau, hệ thống ưu tiên sản phẩm gần người dùng hơn
5. **Cá nhân hóa đề xuất**: Kết quả cuối cùng được sắp xếp theo điểm và giới hạn theo số lượng yêu cầu

#### Hiệu suất và đảm bảo:

- **Dự phòng**: Hệ thống luôn có cơ chế fallback để đảm bảo người dùng nhận được đề xuất kể cả khi gặp lỗi
- **Cập nhật liên tục**: Các đề xuất được cập nhật mỗi khi người dùng xem sản phẩm mới
- **Tối ưu truy vấn**: Các truy vấn được thiết kế để tối ưu hiệu suất Firestore
