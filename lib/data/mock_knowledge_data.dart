// Dữ liệu mẫu cho cơ sở tri thức của chatbot

import 'package:cloud_firestore/cloud_firestore.dart';

class MockKnowledgeData {
  static final List<Map<String, dynamic>> knowledgeDocuments = [
    // DANH MỤC: HELP - TRỢ GIÚP CHUNG
    {
      'title': 'Tính năng chatbot trợ lý ảo',
      'content': '''
Student Market NTTU tích hợp trợ lý ảo thông minh để hỗ trợ người dùng:

1. Tính năng chính của trợ lý ảo:
   - Trả lời các câu hỏi thường gặp về ứng dụng
   - Hỗ trợ tìm kiếm sản phẩm bằng ngôn ngữ tự nhiên
   - Gợi ý các sản phẩm phù hợp dựa trên nhu cầu được mô tả
   - Giải thích các tính năng và quy trình trong ứng dụng
   - Cung cấp thông tin về ưu đãi và cập nhật mới

2. Cách sử dụng trợ lý ảo:
   - Truy cập "Trợ lý ảo" từ menu chính hoặc biểu tượng ở góc phải dưới
   - Nhập câu hỏi hoặc yêu cầu bằng tiếng Việt tự nhiên
   - Đợi phản hồi từ hệ thống (thường trong vòng 1-3 giây)
   - Có thể tiếp tục hội thoại dựa trên phản hồi trước đó

3. Tính năng nâng cao:
   - Ghi nhớ ngữ cảnh hội thoại để cung cấp phản hồi nhất quán
   - Tích hợp tìm kiếm thông tin từ cơ sở tri thức
   - Khả năng hiểu và xử lý ngôn ngữ tự nhiên tiếng Việt
   - Liên tục học hỏi và cải thiện dựa trên tương tác người dùng

Lưu ý: Trợ lý ảo đang được phát triển liên tục. Nếu bạn gặp vấn đề hoặc có góp ý, vui lòng gửi phản hồi qua mục "Cài đặt" > "Góp ý phát triển".
''',
      'keywords': ['chatbot', 'trợ lý ảo', 'AI', 'trí tuệ nhân tạo', 'hỏi đáp tự động', 'hỗ trợ'],
      'category': 'help',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 1,
    },
    {
      'title': 'Công nghệ RAG trong tìm kiếm và hỗ trợ',
      'content': '''
Student Market NTTU sử dụng công nghệ RAG (Retrieval Augmented Generation) để nâng cao trải nghiệm người dùng:

1. RAG là gì?
   - Công nghệ kết hợp giữa truy xuất thông tin và tạo nội dung
   - Hệ thống tìm kiếm thông tin liên quan từ cơ sở dữ liệu
   - Sử dụng thông tin này để tăng cường chất lượng câu trả lời cho người dùng
   - Cung cấp thông tin chính xác, cập nhật và phù hợp với ngữ cảnh

2. Ứng dụng của RAG trong Student Market NTTU:
   - Tìm kiếm sản phẩm thông minh hơn, hiểu được ngữ cảnh và ý định người dùng
   - Hỗ trợ chatbot trả lời câu hỏi dựa trên cơ sở tri thức
   - Gợi ý sản phẩm tương tự dựa trên mô tả bằng ngôn ngữ tự nhiên
   - Hỗ trợ giải quyết vấn đề và câu hỏi kỹ thuật

3. Lợi ích của công nghệ RAG:
   - Kết quả tìm kiếm chính xác và phù hợp hơn
   - Trả lời hữu ích ngay cả với câu hỏi chưa từng gặp
   - Giảm thời gian tìm kiếm thông tin
   - Cập nhật liên tục với thông tin mới nhất từ hệ thống

Lưu ý: Công nghệ RAG đang được cải thiện liên tục. Chất lượng kết quả sẽ ngày càng tốt hơn theo thời gian khi cơ sở tri thức được mở rộng.
''',
      'keywords': ['RAG', 'retrieval augmented generation', 'tìm kiếm thông minh', 'truy xuất tăng cường', 'AI', 'cơ sở tri thức'],
      'category': 'help',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 2,
    },
    {
      'title': 'Gợi ý sản phẩm thông minh',
      'content': '''
Tính năng gợi ý sản phẩm thông minh trên Student Market NTTU:

1. Cách hoạt động:
   - Phân tích hành vi duyệt web và lịch sử mua sắm
   - Học từ sở thích cá nhân được khai báo trong hồ sơ
   - Kết hợp xu hướng thị trường và sản phẩm phổ biến
   - Sử dụng AI để xác định sản phẩm phù hợp với nhu cầu hiện tại

2. Các loại gợi ý:
   - Gợi ý cá nhân hóa: Dựa trên lịch sử và sở thích cá nhân
   - Gợi ý theo danh mục: Sản phẩm tương tự trong cùng danh mục
   - Gợi ý theo xu hướng: Sản phẩm đang được quan tâm nhiều
   - Gợi ý theo ngữ cảnh: Phụ thuộc vào thời điểm, địa điểm và hoạt động hiện tại

3. Nơi hiển thị gợi ý:
   - Trên trang chủ trong mục "Dành cho bạn"
   - Trong trang chi tiết sản phẩm ở phần "Có thể bạn cũng thích"
   - Thông qua thông báo cá nhân hóa (nếu đã bật)
   - Trong email định kỳ (nếu đã đăng ký)

4. Cài đặt gợi ý:
   - Điều chỉnh mức độ cá nhân hóa trong "Cài đặt" > "Quyền riêng tư"
   - Tắt/bật các loại gợi ý khác nhau
   - Cập nhật sở thích tại "Tài khoản" > "Sở thích & Mối quan tâm"
   - Đánh giá gợi ý để cải thiện chất lượng

Lưu ý: Hệ thống gợi ý hoạt động hiệu quả hơn khi bạn tương tác nhiều với ứng dụng và cập nhật sở thích thường xuyên.
''',
      'keywords': ['gợi ý', 'đề xuất', 'sản phẩm gợi ý', 'AI', 'cá nhân hóa', 'recommendation', 'product_search'],
      'category': 'product_search',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 3,
    },
    
    // DANH MỤC: ACCOUNT - TÀI KHOẢN
    {
      'title': 'Cách đăng ký tài khoản',
      'content': '''
Để đăng ký tài khoản mới trên Student Market NTTU, vui lòng làm theo các bước sau:

1. Mở ứng dụng Student Market NTTU
2. Nhấn vào nút "Đăng ký" ở màn hình đăng nhập
3. Điền đầy đủ thông tin cá nhân, bao gồm:
   - Họ và tên
   - Email (ưu tiên sử dụng email của trường để được xác thực nhanh chóng)
   - Mật khẩu (ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường và số)
   - Số điện thoại
   - Chọn vai trò: Sinh viên NTTU hoặc Người dùng thông thường
4. Đọc và chấp nhận Điều khoản sử dụng và Chính sách quyền riêng tư
5. Nhấn nút "Đăng ký"
6. Xác nhận email thông qua liên kết được gửi đến địa chỉ email của bạn
7. Sau khi xác nhận email, hoàn thành hồ sơ bằng cách:
   - Tải lên ảnh đại diện
   - Chọn danh mục sản phẩm yêu thích
   - Khai báo sở thích cá nhân để nhận gợi ý phù hợp hơn
8. Tài khoản của bạn đã sẵn sàng sử dụng

Lưu ý: Sinh viên NTTU sẽ cần hoàn thành quy trình xác thực sinh viên để được hưởng các đặc quyền dành riêng cho sinh viên trường.
''',
      'keywords': ['đăng ký', 'tài khoản', 'đăng ký tài khoản', 'tạo tài khoản', 'đăng nhập lần đầu', 'account', 'signup'],
      'category': 'account',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 1,
    },
    {
      'title': 'Cách đăng nhập và khôi phục mật khẩu',
      'content': '''
Đăng nhập vào tài khoản:
1. Mở ứng dụng Student Market NTTU
2. Nhập địa chỉ email và mật khẩu của bạn
3. Nhấn nút "Đăng nhập"
4. Hoặc sử dụng các phương thức đăng nhập nhanh:
   - Đăng nhập bằng Google
   - Đăng nhập bằng Facebook
   - Đăng nhập với Touch ID/Face ID (nếu đã cài đặt)
5. Chọn "Ghi nhớ đăng nhập" để duy trì phiên đăng nhập trên thiết bị này

Khôi phục mật khẩu:
1. Trên màn hình đăng nhập, nhấn vào "Quên mật khẩu"
2. Nhập email đăng ký tài khoản của bạn
3. Chọn phương thức xác thực:
   - Email: Nhận link khôi phục qua email
   - SMS: Nhận mã xác nhận qua tin nhắn (nếu đã đăng ký số điện thoại)
4. Nếu chọn Email, hãy kiểm tra hộp thư (bao gồm thư mục spam)
5. Nhấn vào liên kết khôi phục mật khẩu trong email
6. Tạo mật khẩu mới theo yêu cầu (ít nhất 8 ký tự, bao gồm chữ hoa, số và ký tự đặc biệt)
7. Xác nhận mật khẩu mới
8. Đăng nhập lại với mật khẩu mới

Bảo mật tài khoản:
1. Sử dụng mật khẩu mạnh và độc đáo
2. Thay đổi mật khẩu định kỳ trong mục "Tài khoản" > "Bảo mật"
3. Bật xác thực hai yếu tố (2FA) để tăng cường bảo mật
4. Kiểm tra các thiết bị đang đăng nhập trong "Tài khoản" > "Quản lý thiết bị"
5. Đăng xuất khỏi thiết bị công cộng sau khi sử dụng

Lưu ý: Liên kết khôi phục mật khẩu chỉ có hiệu lực trong 24 giờ. Nếu bạn vẫn gặp vấn đề, vui lòng liên hệ hỗ trợ qua email support@studentmarket.nttu.edu.vn hoặc hotline 028.3456.7890.
''',
      'keywords': ['đăng nhập', 'quên mật khẩu', 'khôi phục mật khẩu', 'mật khẩu', 'login', 'lấy lại mật khẩu', 'bảo mật'],
      'category': 'account',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 2,
    },
    {
      'title': 'Xác thực tài khoản sinh viên',
      'content': '''
Để xác thực tài khoản sinh viên NTTU và nhận các đặc quyền dành riêng cho sinh viên:

1. Đăng nhập vào tài khoản Student Market NTTU
2. Vào phần "Tài khoản" > "Hồ sơ của tôi"
3. Nhấn vào "Xác thực tài khoản sinh viên"
4. Điền các thông tin sinh viên:
   - Mã số sinh viên
   - Khoa/Ngành học (chọn từ danh sách có sẵn)
   - Năm học hiện tại
   - Cấp độ học tập (Đại học/Cao đẳng/Sau đại học)
5. Tải lên một trong các giấy tờ sau:
   - Thẻ sinh viên có hiệu lực
   - Biên lai đóng học phí học kỳ gần nhất
   - Bảng điểm có xác nhận của trường
   - Email được cấp bởi NTTU (@nttu.edu.vn)
6. Nhấn "Gửi xác thực"
7. Chờ duyệt (thường trong vòng 24-48 giờ làm việc)
8. Kiểm tra trạng thái xác thực trong mục "Tài khoản" > "Xác thực sinh viên"

Sau khi được xác thực, bạn sẽ nhận được:
- Badge "Sinh viên NTTU" trên trang cá nhân
- Giảm phí giao dịch 50%
- Khả năng tiếp cận các chương trình ưu đãi dành cho sinh viên
- Ưu tiên hiển thị trong kết quả tìm kiếm
- 500 NTT Point khởi đầu
- Khả năng tham gia vào cộng đồng nội bộ NTTU
- Ưu đãi vận chuyển đặc biệt trong khuôn viên trường

Gia hạn xác thực:
- Xác thực sinh viên có hiệu lực 1 năm học
- Trước khi hết hạn, bạn sẽ nhận được thông báo gia hạn
- Quy trình gia hạn đơn giản hơn, chỉ cần xác nhận bạn vẫn đang là sinh viên NTTU

Lưu ý: Nếu quá 48 giờ chưa nhận được phản hồi, vui lòng liên hệ bộ phận hỗ trợ qua mục "Trợ giúp" > "Liên hệ hỗ trợ" hoặc đến trực tiếp văn phòng hỗ trợ tại trường.
''',
      'keywords': ['xác thực', 'sinh viên', 'tài khoản sinh viên', 'verification', 'xác minh', 'đặc quyền sinh viên'],
      'category': 'account',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 3,
    },
    {
      'title': 'Quản lý hồ sơ người dùng',
      'content': '''
Hướng dẫn quản lý hồ sơ cá nhân trên Student Market NTTU:

1. Truy cập hồ sơ:
   - Đăng nhập vào tài khoản
   - Nhấn vào biểu tượng tài khoản ở góc dưới bên phải
   - Chọn "Hồ sơ của tôi"

2. Chỉnh sửa thông tin cá nhân:
   - Nhấn vào nút "Chỉnh sửa" ở góc trên bên phải
   - Cập nhật các thông tin:
     + Ảnh đại diện (nhấn vào hình tròn để thay đổi)
     + Họ và tên
     + Bio/Giới thiệu ngắn
     + Thông tin liên hệ (email, số điện thoại)
     + Địa chỉ mặc định
   - Nhấn "Lưu" để hoàn tất

3. Thiết lập sở thích:
   - Trong hồ sơ, chọn "Sở thích & Mối quan tâm"
   - Chọn các danh mục sản phẩm bạn quan tâm
   - Thêm từ khóa tìm kiếm thường dùng
   - Điều chỉnh các cài đặt về gợi ý sản phẩm

4. Quản lý địa chỉ:
   - Chọn "Địa chỉ của tôi"
   - Xem danh sách các địa chỉ đã lưu
   - Thêm địa chỉ mới bằng cách nhấn nút "+"
   - Chỉnh sửa hoặc xóa địa chỉ hiện có
   - Đặt địa chỉ mặc định cho giao hàng

5. Cài đặt thông báo:
   - Vào "Cài đặt" > "Thông báo"
   - Bật/tắt các loại thông báo:
     + Thông báo ứng dụng
     + Email
     + SMS
   - Tùy chỉnh thông báo theo danh mục: đơn hàng, tin nhắn, ưu đãi

6. Quản lý quyền riêng tư:
   - Vào "Cài đặt" > "Quyền riêng tư"
   - Tùy chỉnh ai có thể xem hồ sơ của bạn
   - Kiểm soát dữ liệu được chia sẻ với AI và gợi ý sản phẩm
   - Quản lý lịch sử tìm kiếm và duyệt web

7. Thiết lập shop bán hàng (nếu muốn bán sản phẩm):
   - Nhấn vào "Thiết lập shop"
   - Đặt tên shop
   - Thêm mô tả và thông tin giới thiệu shop
   - Chọn danh mục sản phẩm chuyên bán
   - Thiết lập chính sách vận chuyển và trả hàng

Lưu ý: Thông tin hồ sơ đầy đủ và chính xác giúp nâng cao uy tín và trải nghiệm mua bán trên Student Market NTTU.
''',
      'keywords': ['hồ sơ', 'tài khoản', 'thông tin cá nhân', 'profile', 'chỉnh sửa hồ sơ', 'sở thích', 'thông báo'],
      'category': 'account',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 4,
    },

    // DANH MỤC: PRODUCT - SẢN PHẨM
    {
      'title': 'Cách đăng bán sản phẩm',
      'content': '''
Để đăng sản phẩm bán trên Student Market NTTU, thực hiện theo các bước sau:

1. Chuẩn bị trước khi đăng bán:
   - Chụp ít nhất 3-5 ảnh sản phẩm ở các góc khác nhau, với ánh sáng tốt
   - Chuẩn bị thông tin chi tiết về sản phẩm (tên, mô tả, thông số kỹ thuật)
   - Xác định giá bán hợp lý (có thể tham khảo giá sản phẩm tương tự)
   - Biết rõ tình trạng, khuyết điểm của sản phẩm (nếu có)

2. Đăng sản phẩm:
   - Đăng nhập vào tài khoản của bạn
   - Nhấn vào nút "+" ở góc dưới màn hình hoặc vào "Tài khoản" > "Sản phẩm của tôi" > "Đăng sản phẩm mới"
   - Tải lên ảnh sản phẩm (kéo thả để sắp xếp ảnh, ảnh đầu tiên sẽ là ảnh chính)
   - Điền các thông tin bắt buộc:
     + Tên sản phẩm: ngắn gọn, rõ ràng và chứa từ khóa chính
     + Danh mục: chọn đúng danh mục và danh mục phụ (nếu có)
     + Giá bán: nhập giá gốc và giá khuyến mãi (nếu có)
     + Số lượng: số lượng sẵn có để bán
     + Tình trạng: mới/đã qua sử dụng/có bảo hành
   - Điền mô tả chi tiết:
     + Thông tin về sản phẩm: đặc điểm, kích thước, màu sắc
     + Tình trạng sử dụng: thời gian sử dụng, khuyết điểm (nếu có)
     + Lý do bán: nêu rõ lý do để tăng độ tin cậy
   - Thêm thông số kỹ thuật (tùy loại sản phẩm)
   - Thêm các từ khóa/tag để tăng khả năng tìm kiếm
   - Chọn phương thức giao hàng và thanh toán được chấp nhận
   - Nhấn "Xem trước" để kiểm tra lại thông tin
   - Nhấn "Đăng sản phẩm" để hoàn tất

3. Sau khi đăng sản phẩm:
   - Sản phẩm sẽ được gửi để kiểm duyệt (thường trong vòng 6-24 giờ)
   - Bạn sẽ nhận được thông báo khi sản phẩm được duyệt
   - Quản lý sản phẩm của bạn trong mục "Tài khoản" > "Sản phẩm của tôi"
   - Thêm khuyến mãi hoặc giảm giá qua mục "Tùy chỉnh giá"
   - Theo dõi hiệu suất hiển thị và số lượt xem trong "Thống kê sản phẩm"

4. Mẹo đăng bán hiệu quả:
   - Đặt tiêu đề thu hút, chứa các từ khóa quan trọng
   - Sử dụng ảnh chất lượng cao, rõ ràng
   - Mô tả chi tiết và trung thực về tình trạng sản phẩm
   - Đặt giá hợp lý, tham khảo giá thị trường
   - Phản hồi nhanh chóng các câu hỏi của người mua
   - Cập nhật trạng thái sản phẩm thường xuyên

Lưu ý:
- Sản phẩm sẽ được kiểm duyệt tự động bằng AI và kiểm duyệt thủ công trước khi hiển thị
- Không đăng sản phẩm vi phạm quy định của Student Market NTTU
- Đảm bảo mô tả trung thực để tránh khiếu nại và đánh giá tiêu cực
- Sản phẩm được đăng tải sẽ hiển thị công khai trong 30 ngày và tự động gia hạn trừ khi hết hàng
''',
      'keywords': ['đăng bán', 'đăng sản phẩm', 'bán hàng', 'tạo sản phẩm', 'đăng tin', 'đăng bài', 'bán đồ', 'help'],
      'category': 'help',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 1,
    },
    {
      'title': 'Quy định đăng sản phẩm',
      'content': '''
Khi đăng sản phẩm trên Student Market NTTU, vui lòng tuân thủ các quy định sau:

1. Sản phẩm được phép:
   - Sách, tài liệu học tập, giáo trình
   - Thiết bị điện tử, đồ dùng cá nhân đã qua sử dụng
   - Dụng cụ học tập, vật dụng trong ký túc xá
   - Quần áo, giày dép còn sử dụng tốt
   - Đồ thể thao, nhạc cụ, dụng cụ nghệ thuật
   - Dịch vụ gia sư, hỗ trợ học tập
   - Xe đạp, xe điện, phương tiện di chuyển cá nhân
   - Thiết bị điện tử gia dụng (máy pha cà phê, nồi cơm điện...)
   - Nội thất, vật dụng trang trí phòng ký túc xá
   - Thực phẩm đóng gói chưa mở, chưa hết hạn

2. Sản phẩm bị cấm:
   - Đồ uống có cồn, thuốc lá và các chất gây nghiện
   - Thuốc không kê đơn và vật phẩm y tế không được phép
   - Vũ khí, công cụ hỗ trợ, vật liệu nguy hiểm
   - Hàng giả, hàng nhái, hàng vi phạm bản quyền
   - Sản phẩm khiêu dâm, không lành mạnh
   - Thẻ tín dụng, tài khoản số hoặc các dịch vụ tài chính phi pháp
   - Thực phẩm tươi sống, thực phẩm đã qua chế biến
   - Động vật hoang dã, bộ phận của động vật
   - Sản phẩm vi phạm pháp luật Việt Nam
   - Dịch vụ làm bài hộ, viết thuê luận văn

3. Yêu cầu về hình ảnh:
   - Tối thiểu 3 hình ảnh cho mỗi sản phẩm
   - Hình ảnh phải là của chính sản phẩm, không sử dụng hình ảnh từ internet
   - Hình ảnh rõ nét, chụp đủ góc cạnh và chi tiết sản phẩm
   - Không chèn logo, watermark cá nhân lên hình ảnh
   - Không sử dụng hình ảnh khiêu dâm, bạo lực
   - Kích thước ảnh tối thiểu 600x600 pixels
   - Dung lượng tối đa 5MB cho mỗi ảnh
   - Định dạng hỗ trợ: JPG, PNG, HEIC

4. Yêu cầu về mô tả:
   - Mô tả trung thực, đầy đủ về sản phẩm
   - Nêu rõ khuyết điểm, hư hỏng (nếu có)
   - Không quảng cáo quá mức, sai sự thật
   - Không chứa thông tin cá nhân như số điện thoại, địa chỉ cụ thể
   - Độ dài tối thiểu 100 ký tự, tối đa 2000 ký tự
   - Cấu trúc rõ ràng, dễ đọc, có thể sử dụng đánh dấu (bullet points)
   - Nêu rõ chính sách đổi trả (nếu có)

5. Quy định về giá:
   - Giá phải hợp lý, phù hợp với giá thị trường
   - Không đăng giá quá thấp để thu hút sau đó thay đổi
   - Các chi phí phụ (vận chuyển, bảo hành) phải được nêu rõ
   - Giá tối thiểu: 5,000đ
   - Giá tối đa: 50,000,000đ (với sản phẩm giá trị cao cần xác thực đặc biệt)

Quy trình kiểm duyệt:
- Hệ thống AI sẽ kiểm tra sản phẩm trong vòng 2-6 giờ
- Đội ngũ kiểm duyệt viên xem xét trong 24 giờ làm việc
- Sản phẩm được duyệt sẽ hiển thị công khai
- Sản phẩm vi phạm sẽ bị từ chối với lý do cụ thể
- Tài khoản vi phạm nhiều lần sẽ bị hạn chế hoặc khóa

Lưu ý: Student Market NTTU đánh giá cao sự trung thực và minh bạch. Việc tuân thủ quy định giúp nâng cao trải nghiệm mua bán và xây dựng cộng đồng lành mạnh.
''',
      'keywords': ['quy định', 'điều kiện', 'cấm', 'chính sách', 'kiểm duyệt', 'không được phép', 'quy tắc', 'hướng dẫn', 'help'],
      'category': 'help',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 2,
    },
    {
      'title': 'Quản lý và chỉnh sửa sản phẩm',
      'content': '''
Hướng dẫn quản lý và chỉnh sửa sản phẩm đã đăng trên Student Market NTTU:

1. Truy cập quản lý sản phẩm:
   - Đăng nhập vào tài khoản của bạn
   - Vào mục "Tài khoản" > "Sản phẩm của tôi"
   - Tại đây bạn sẽ thấy danh sách tất cả sản phẩm đã đăng với trạng thái tương ứng

2. Các trạng thái sản phẩm:
   - Đang xử lý: Sản phẩm đang chờ kiểm duyệt
   - Đang bán: Sản phẩm đã được duyệt và đang hiển thị
   - Tạm ẩn: Sản phẩm đang bị ẩn theo yêu cầu của bạn
   - Hết hàng: Sản phẩm đã bán hết
   - Từ chối: Sản phẩm không được duyệt
   - Hết hạn: Sản phẩm đã quá thời gian hiển thị (30 ngày)

3. Chỉnh sửa thông tin sản phẩm:
   - Chọn sản phẩm cần chỉnh sửa
   - Nhấn vào nút "Chỉnh sửa" hoặc biểu tượng bút
   - Thực hiện các thay đổi cần thiết:
     + Cập nhật hình ảnh (thêm/xóa/sắp xếp lại)
     + Chỉnh sửa tiêu đề, mô tả
     + Điều chỉnh giá, số lượng
     + Cập nhật thông số kỹ thuật
   - Nhấn "Lưu thay đổi"
   - Lưu ý: Một số thay đổi lớn có thể khiến sản phẩm cần được kiểm duyệt lại

4. Quản lý trạng thái sản phẩm:
   - Tạm ẩn sản phẩm: Nhấn vào "Tạm ẩn" để ngừng hiển thị sản phẩm tạm thời
   - Hiển thị lại: Chọn sản phẩm đang ẩn và nhấn "Hiển thị lại"
   - Đánh dấu đã bán: Nhấn "Đánh dấu đã bán" khi sản phẩm đã được bán ngoài ứng dụng
   - Xóa sản phẩm: Nhấn "Xóa" để xóa vĩnh viễn sản phẩm (không thể khôi phục)
   - Gia hạn hiển thị: Nhấn "Gia hạn" để gia hạn thêm 30 ngày hiển thị

5. Tối ưu hiển thị sản phẩm:
   - Đẩy tin: Nâng vị trí sản phẩm lên đầu danh sách tìm kiếm (tính phí)
   - Gắn nhãn nổi bật: Thêm nhãn "Hot", "Giảm giá", "Mới" (tính phí)
   - Quảng cáo sản phẩm: Hiển thị sản phẩm ở vị trí đặc biệt (tính phí)
   - Cập nhật thường xuyên: Hệ thống ưu tiên sản phẩm được cập nhật gần đây

6. Theo dõi hiệu suất sản phẩm:
   - Xem số lượt xem chi tiết
   - Theo dõi số lượt "Thích" và "Lưu"
   - Kiểm tra số lượt liên hệ mua
   - Phân tích thời gian xem sản phẩm cao điểm
   - Nhận gợi ý cải thiện từ hệ thống

7. Giải quyết vấn đề sản phẩm bị từ chối:
   - Xem lý do từ chối được cung cấp
   - Chỉnh sửa theo gợi ý của hệ thống
   - Gửi lại để kiểm duyệt sau khi sửa
   - Liên hệ hỗ trợ nếu cần giải thích thêm

Lưu ý: Việc cập nhật thông tin sản phẩm thường xuyên và chính xác sẽ giúp tăng cơ hội bán hàng và cải thiện độ uy tín của người bán.
''',
      'keywords': ['quản lý sản phẩm', 'chỉnh sửa sản phẩm', 'cập nhật sản phẩm', 'sửa thông tin', 'ẩn sản phẩm', 'xóa sản phẩm', 'help'],
      'category': 'help',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 3,
    },

    // DANH MỤC: PAYMENT - THANH TOÁN
    {
      'title': 'Phương thức thanh toán được hỗ trợ',
      'content': '''
Student Market NTTU hỗ trợ các phương thức thanh toán sau:

1. Thanh toán khi nhận hàng (COD)
   - Người mua trả tiền mặt khi nhận sản phẩm
   - Áp dụng cho giao dịch dưới 2 triệu đồng
   - Không áp dụng cho người bán mới (dưới 1 tháng)
   - Ưu điểm: An toàn, kiểm tra hàng trước khi thanh toán
   - Nhược điểm: Cần có người nhận hàng, tỷ lệ hủy đơn cao hơn

2. Chuyển khoản ngân hàng
   - Chuyển khoản trực tiếp đến tài khoản trung gian của Student Market
   - Hỗ trợ tất cả ngân hàng nội địa và liên ngân hàng
   - Quy trình an toàn với hệ thống đảm bảo tự động
   - Ưu điểm: Phí thấp, xử lý nhanh
   - Nhược điểm: Cần xác nhận giao dịch thành công

3. Ví điện tử và thanh toán di động
   - MoMo: Liên kết trực tiếp và thanh toán nhanh chóng
   - VNPay: Thanh toán qua QR code hoặc ứng dụng
   - ZaloPay: Tích hợp trong ứng dụng Zalo
   - ShopeePay: Tích hợp cho người dùng quen Shopee
   - Ưu điểm: Nhanh chóng, có khuyến mãi thường xuyên
   - Nhược điểm: Cần cài đặt ứng dụng liên quan

4. Thanh toán bằng NTT Credit
   - Sử dụng điểm uy tín tích lũy trong hệ thống
   - Quy đổi: 1000 NTT Point = giảm 1% giá trị đơn hàng (tối đa 50%)
   - Sinh viên đã xác thực nhận thêm 20% giá trị quy đổi
   - Ưu điểm: Tiết kiệm, đặc quyền cho người dùng thân thiết
   - Nhược điểm: Cần tích lũy điểm qua các giao dịch trước

Quy trình thanh toán an toàn:
1. Tiền được giữ trong tài khoản đảm bảo của Student Market NTTU
2. Chỉ giải ngân cho người bán sau khi người mua xác nhận đã nhận hàng
3. Thời gian đảm bảo: 24 giờ sau khi người mua xác nhận đã nhận hàng
4. Nếu có tranh chấp, tiền được giữ lại cho đến khi giải quyết xong
5. Hệ thống tự động hoàn tiền nếu đơn hàng bị hủy

Bảo mật thanh toán:
- Mã hóa đầu cuối cho thông tin thẻ và tài khoản
- Xác thực hai yếu tố cho mọi giao dịch
- Giám sát giao dịch bất thường 24/7
- Chứng chỉ bảo mật PCI DSS Cấp độ 1

Lưu ý: Báo cáo ngay nếu bạn gặp vấn đề với thanh toán qua mục "Hỗ trợ" > "Báo cáo vấn đề thanh toán".
''',
      'keywords': ['thanh toán', 'payment', 'phương thức thanh toán', 'COD', 'chuyển khoản', 'ví điện tử', 'trả góp', 'order'],
      'category': 'order',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 1,
    },
    {
      'title': 'Cách sử dụng NTT Credit và điểm uy tín',
      'content': '''
NTT Credit là hệ thống điểm uy tín và ưu đãi dành cho người dùng Student Market NTTU:

1. NTT Point (Điểm thưởng):
   - Được nhận khi hoàn thành giao dịch thành công
   - Mỗi 10,000đ chi tiêu = 1 NTT Point
   - Mỗi đánh giá 5 sao từ người mua/bán = 5 NTT Point
   - Mỗi sản phẩm được bán thành công = 10 NTT Point
   - Mỗi chia sẻ ứng dụng thành công = 20 NTT Point

2. NTT Credit (Điểm uy tín):
   - Mọi người dùng bắt đầu với 100 điểm
   - Tăng khi:
     + Hoàn thành giao dịch thành công (+2 điểm)
     + Giao hàng đúng hẹn (+1 điểm)
     + Nhận đánh giá tốt (+1-3 điểm)
     + Phản hồi tin nhắn nhanh (+0.5 điểm)
   - Giảm khi:
     + Hủy đơn hàng không lý do (-5 điểm)
     + Giao hàng trễ (-2 điểm)
     + Sản phẩm không đúng mô tả (-10 điểm)
     + Nhận đánh giá 1 sao (-3 điểm)

3. Đặc quyền theo điểm uy tín (NTT Credit):
   - 80-99 điểm: Mức tiêu chuẩn cho giao dịch
   - 100-119 điểm: Mức cơ bản, đủ điều kiện bán hàng
   - 120-159 điểm: Ưu tiên hiển thị sản phẩm trong tìm kiếm
   - 160-179 điểm: Được giao dịch không cần đặt cọc
   - 180-199 điểm: Được ưu tiên hỗ trợ khi có tranh chấp
   - 200+ điểm: Được mời vào chương trình Người bán ưu tú

4. Cấp độ thành viên:
   - Standard: Người dùng mới đăng ký
   - Silver: NTT Credit từ 120-159 điểm
   - Gold: NTT Credit từ 160-199 điểm
   - Platinum: NTT Credit từ 200+ điểm
   - Campus Ambassador: Đại diện chính thức của Student Market tại trường

5. Kiểm tra và nâng cao điểm:
   - Kiểm tra điểm hiện tại tại: "Tài khoản" > "NTT Credit & Point"
   - Xem lịch sử thay đổi điểm và lý do
   - Tham khảo gợi ý cải thiện điểm từ hệ thống
   - Hoàn thành các nhiệm vụ hàng ngày/tuần để tăng điểm
   - Tham gia các chương trình khuyến mãi đặc biệt

Lưu ý: Điểm uy tín dưới 60 sẽ bị hạn chế quyền bán hàng và yêu cầu đặt cọc cho mọi giao dịch. Tài khoản có thể bị khóa tạm thời nếu điểm uy tín dưới 40.
''',
      'keywords': ['ntt credit', 'điểm uy tín', 'điểm thưởng', 'credit', 'ưu đãi', 'giảm giá', 'tích điểm', 'quy đổi điểm', 'order'],
      'category': 'order',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 2,
    },
    {
      'title': 'Quy trình mua hàng và thanh toán',
      'content': '''
Quy trình mua hàng và thanh toán trên Student Market NTTU:

1. Tìm kiếm và chọn sản phẩm:
   - Tìm kiếm sản phẩm qua thanh tìm kiếm hoặc danh mục
   - Lọc kết quả theo giá, tình trạng, địa điểm, v.v.
   - Xem thông tin chi tiết sản phẩm và đánh giá người bán
   - Kiểm tra kỹ hình ảnh và mô tả sản phẩm

2. Liên hệ người bán (tùy chọn):
   - Nhấn nút "Chat với người bán" để trao đổi thông tin
   - Đặt câu hỏi về sản phẩm, thương lượng giá (nếu có)
   - Yêu cầu hình ảnh hoặc video chi tiết (nếu cần)
   - Thống nhất về phương thức giao hàng và thanh toán

3. Thêm vào giỏ hàng:
   - Nhấn nút "Thêm vào giỏ hàng" nếu muốn tiếp tục mua sắm
   - Hoặc nhấn "Mua ngay" để chuyển đến trang thanh toán
   - Trong giỏ hàng, kiểm tra và điều chỉnh số lượng
   - Áp dụng mã giảm giá (nếu có)

4. Tiến hành đặt hàng:
   - Nhấn "Thanh toán" từ giỏ hàng
   - Chọn địa chỉ giao hàng hoặc thêm địa chỉ mới
   - Chọn phương thức vận chuyển và thời gian giao hàng
   - Xem phí vận chuyển và tổng thanh toán
   - Thêm ghi chú cho người bán (nếu cần)

5. Thanh toán:
   - Chọn phương thức thanh toán:
     + Thanh toán khi nhận hàng (COD)
     + Chuyển khoản ngân hàng
     + Ví điện tử (MoMo, VNPay, ZaloPay, ShopeePay)
     + NTT Credit (sử dụng điểm thưởng)
     + Trả góp (nếu đủ điều kiện)
   - Nếu sử dụng NTT Point, chọn số điểm muốn quy đổi
   - Xác nhận thanh toán bằng cách nhấn "Đặt hàng"
   - Hoàn tất các bước xác minh (nếu có) theo phương thức thanh toán đã chọn
   - Nhận mã xác nhận đơn hàng qua email hoặc SMS

6. Theo dõi đơn hàng:
   - Kiểm tra trạng thái đơn hàng trong mục "Đơn hàng của tôi"
   - Nhận thông báo cập nhật trạng thái đơn hàng
   - Liên hệ người bán hoặc hỗ trợ nếu có vấn đề
   - Theo dõi hành trình giao hàng (nếu có mã vận đơn)

7. Nhận hàng và hoàn tất:
   - Kiểm tra hàng kỹ khi nhận
   - Nếu chọn COD, thanh toán cho người giao hàng
   - Nhấn "Đã nhận hàng" trong ứng dụng
   - Đánh giá sản phẩm và người bán
   - Nhận NTT Point cho giao dịch thành công

8. Hỗ trợ sau mua hàng:
   - Báo cáo vấn đề trong vòng 48 giờ sau khi nhận hàng
   - Yêu cầu hoàn tiền/đổi trả nếu sản phẩm không đạt yêu cầu
   - Liên hệ hỗ trợ giải quyết tranh chấp nếu cần

Các mẹo khi mua hàng:
- Kiểm tra kỹ thông tin và đánh giá người bán trước khi mua
- Nên sử dụng chat trong ứng dụng để trao đổi, tránh liên lạc bên ngoài
- Không giao dịch bên ngoài ứng dụng để được bảo vệ bởi chính sách đảm bảo
- Chụp ảnh/quay video quá trình mở hàng để làm bằng chứng nếu có vấn đề
- Ưu tiên giao dịch với người bán có điểm uy tín (NTT Credit) cao

Lưu ý: Mỗi giao dịch thành công sẽ tăng điểm uy tín và tích lũy NTT Point để sử dụng cho các giao dịch sau.
''',
      'keywords': ['mua hàng', 'thanh toán', 'đặt hàng', 'giỏ hàng', 'quy trình mua', 'đặt mua', 'checkout', 'order'],
      'category': 'order',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 3,
    },
    {
      'title': 'Giải quyết vấn đề thanh toán',
      'content': '''
Hướng dẫn giải quyết các vấn đề thanh toán phổ biến trên Student Market NTTU:

1. Thanh toán không thành công:
   - Nguyên nhân có thể:
     + Số dư tài khoản không đủ
     + Thông tin thẻ/tài khoản không chính xác
     + Vấn đề kết nối mạng
     + Hạn mức thanh toán bị vượt quá
     + Tài khoản chưa kích hoạt thanh toán trực tuyến
   - Cách khắc phục:
     + Kiểm tra số dư và giới hạn chi tiêu của tài khoản
     + Xác nhận thông tin thẻ/tài khoản đã nhập chính xác
     + Thử lại sau 5-10 phút hoặc sử dụng mạng khác
     + Liên hệ ngân hàng/ví điện tử để tăng hạn mức
     + Kích hoạt tính năng thanh toán trực tuyến (nếu cần)

2. Tiền đã trừ nhưng đơn hàng chưa được xác nhận:
   - Thời gian xác nhận giao dịch có thể từ 5 phút đến 24 giờ
   - Kiểm tra email và thông báo trong ứng dụng
   - Kiểm tra lịch sử giao dịch trong tài khoản ngân hàng/ví điện tử
   - Chụp màn hình biên lai hoặc thông báo thanh toán
   - Liên hệ hỗ trợ qua Tài khoản > Trợ giúp > Vấn đề thanh toán với:
     + Mã đơn hàng hoặc mã giao dịch
     + Thời gian thực hiện giao dịch
     + Ảnh chụp biên lai/thông báo thanh toán
     + Phương thức thanh toán đã sử dụng

3. Hoàn tiền:
   - Thời gian hoàn tiền tùy thuộc vào phương thức thanh toán:
     + Ví điện tử: 1-3 ngày làm việc
     + Thẻ tín dụng/ghi nợ: 7-14 ngày làm việc
     + Chuyển khoản ngân hàng: 5-10 ngày làm việc
     + NTT Point: hoàn trả ngay lập tức
   - Kiểm tra trạng thái hoàn tiền trong mục "Tài khoản" > "Lịch sử giao dịch"
   - Nếu quá thời hạn trên vẫn chưa nhận được tiền, hãy liên hệ hỗ trợ

4. Vấn đề với NTT Point:
   - Điểm không được cộng sau giao dịch:
     + Điểm thường được cập nhật trong vòng 24 giờ sau giao dịch thành công
     + Kiểm tra mục "Tài khoản" > "NTT Credit & Point" > "Lịch sử điểm"
     + Nếu sau 24 giờ vẫn chưa cập nhật, hãy liên hệ hỗ trợ
   - Không thể sử dụng điểm:
     + Kiểm tra xem bạn có đủ điểm không
     + Xác nhận sản phẩm/người bán có hỗ trợ thanh toán bằng điểm
     + Đảm bảo tài khoản không bị hạn chế

5. Vấn đề với thanh toán trả góp:
   - Đơn hàng bị từ chối:
     + Điểm tín dụng không đủ (yêu cầu tối thiểu 80 điểm)
     + Thiếu thông tin xác thực
     + Lịch sử giao dịch chưa đủ
   - Cách khắc phục:
     + Tăng điểm uy tín qua các giao dịch nhỏ hơn
     + Hoàn thiện thông tin xác thực tài khoản
     + Liên hệ hỗ trợ để biết chính xác yêu cầu còn thiếu

6. Liên hệ hỗ trợ thanh toán:
   - Chat trực tiếp: Nhấn "Hỗ trợ" > "Chat với nhân viên hỗ trợ"
   - Email: payment@studentmarket.nttu.edu.vn
   - Hotline thanh toán: 028.3456.7891 (8:00 - 20:00 hàng ngày)
   - Hỗ trợ trực tiếp: Văn phòng Student Market NTTU, Phòng 103, Tòa nhà A, NTTU

7. Phòng tránh lừa đảo thanh toán:
   - Chỉ thanh toán trong ứng dụng, không chuyển khoản trực tiếp cho người bán
   - Không chia sẻ thông tin đăng nhập, mã OTP với bất kỳ ai
   - Cảnh giác với các liên kết thanh toán gửi qua tin nhắn/email
   - Báo cáo ngay các yêu cầu thanh toán đáng ngờ cho đội ngũ hỗ trợ

Lưu ý: Mọi vấn đề thanh toán sẽ được ưu tiên xử lý trong vòng 24 giờ làm việc. Trong trường hợp khẩn cấp, hãy sử dụng hotline hỗ trợ.
''',
      'keywords': ['lỗi thanh toán', 'hoàn tiền', 'tiền bị trừ', 'thanh toán thất bại', 'sự cố thanh toán', 'xử lý thanh toán'],
      'category': 'payment',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 4,
    },

    // DANH MỤC: SEARCH - TÌM KIẾM
    {
      'title': 'Cách tìm kiếm sản phẩm hiệu quả',
      'content': '''
Để tìm kiếm sản phẩm hiệu quả trên Student Market NTTU, hãy thực hiện các bước sau:

1. Tìm kiếm cơ bản:
   - Nhấn vào biểu tượng kính lúp ở thanh công cụ
   - Nhập từ khóa cần tìm (tên sản phẩm, thương hiệu, loại sản phẩm)
   - Hệ thống sẽ gợi ý các từ khóa phổ biến khi bạn nhập
   - Nhấn Enter hoặc nút Tìm kiếm
   - Xem kết quả và tinh chỉnh bằng các bộ lọc nếu cần

2. Tìm kiếm nâng cao (bộ lọc):
   - Từ trang kết quả tìm kiếm, nhấn "Bộ lọc" hoặc biểu tượng lọc
   - Sử dụng các bộ lọc có sẵn:
     + Danh mục: Chọn danh mục và danh mục phụ
     + Khoảng giá: Thiết lập giá thấp nhất và cao nhất
     + Tình trạng: Mới, Đã qua sử dụng, Còn bảo hành, Preorder
     + Vị trí: Chọn khu vực cụ thể (khoảng cách 1-50km)
     + Xếp hạng người bán: Từ 1-5 sao
     + Điểm uy tín người bán: Chọn mức tối thiểu
     + Thời gian đăng: Hôm nay, 3 ngày, 1 tuần, 2 tuần, 1 tháng
   - Sắp xếp kết quả theo:
     + Liên quan nhất (mặc định)
     + Giá thấp đến cao
     + Giá cao đến thấp
     + Mới nhất
     + Phổ biến nhất
     + Đánh giá cao nhất
     + Gần nhất

3. Tìm kiếm bằng ngôn ngữ tự nhiên (AI-powered):
   - Sử dụng câu lệnh tự nhiên trong ô tìm kiếm, ví dụ:
     + "Laptop cũ dưới 5 triệu còn bảo hành"
     + "Sách chuyên ngành CNTT đã qua sử dụng ít"
     + "Áo khoác nam size L gần ký túc xá B"
   - Hệ thống AI sẽ phân tích yêu cầu và hiển thị kết quả phù hợp
   - Tính năng này được cải thiện liên tục dựa trên phản hồi người dùng

4. Tìm kiếm bằng hình ảnh:
   - Nhấn vào biểu tượng camera bên cạnh thanh tìm kiếm
   - Chọn một trong các tùy chọn:
     + Chụp ảnh: Sử dụng camera để chụp sản phẩm
     + Thư viện: Chọn ảnh có sẵn từ thiết bị
     + URL: Nhập đường dẫn hình ảnh từ internet
   - Tải lên hình ảnh sản phẩm cần tìm
   - Hệ thống AI nhận diện và hiển thị các sản phẩm tương tự
   - Tinh chỉnh kết quả bằng cách thêm từ khóa hoặc bộ lọc

5. Tìm kiếm theo danh mục:
   - Từ trang chủ, nhấn vào mục "Danh mục"
   - Chọn danh mục chính (Điện tử, Thời trang, Sách vở...)
   - Duyệt qua các danh mục phụ
   - Xem tất cả sản phẩm trong danh mục đã chọn
   - Sử dụng bộ lọc để tinh chỉnh kết quả

6. Tính năng "Thông báo khi có hàng":
   - Tìm kiếm sản phẩm bạn muốn
   - Nếu không có kết quả phù hợp, nhấn "Thông báo khi có hàng" 
   - Thiết lập các tiêu chí chi tiết:
     + Tên/loại sản phẩm
     + Khoảng giá mong muốn
     + Tình trạng (Mới/Cũ)
     + Vị trí ưu tiên
   - Nhận thông báo qua app hoặc email khi có sản phẩm phù hợp

7. Lưu và theo dõi tìm kiếm:
   - Lưu tìm kiếm bằng cách nhấn biểu tượng "Lưu" bên cạnh kết quả
   - Đặt tên cho tìm kiếm đã lưu để dễ nhận biết
   - Truy cập tìm kiếm đã lưu trong "Tài khoản" > "Tìm kiếm đã lưu"
   - Nhận thông báo khi có sản phẩm mới phù hợp với tìm kiếm đã lưu
   - Chỉnh sửa hoặc xóa tìm kiếm đã lưu bất cứ lúc nào

8. Mẹo tìm kiếm nâng cao:
   - Sử dụng dấu ngoặc kép cho tìm kiếm chính xác: "iPhone 13 Pro Max"
   - Sử dụng dấu gạch nối để loại trừ: "laptop -dell" (tìm laptop trừ hãng Dell)
   - Sử dụng toán tử OR: "nike OR adidas" (tìm sản phẩm của một trong hai thương hiệu)
   - Thêm thông tin vị trí cho kết quả gần hơn: "bàn học khu B"
   - Sử dụng khoảng giá: "áo khoác 100k-300k"

Lưu ý: Hệ thống tìm kiếm được cải thiện liên tục nhờ AI. Nếu không tìm thấy kết quả mong muốn, hãy thử các từ khóa tương tự hoặc sử dụng bộ lọc để mở rộng tìm kiếm.
''',
      'keywords': ['tìm kiếm', 'search', 'tìm sản phẩm', 'bộ lọc', 'filter', 'tìm', 'lọc sản phẩm', 'tìm theo hình ảnh'],
      'category': 'search',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 1,
    },
    {
      'title': 'Tìm kiếm thông minh với AI',
      'content': '''
Student Market NTTU tích hợp công nghệ AI tiên tiến vào hệ thống tìm kiếm để mang lại trải nghiệm tốt nhất:

1. Tìm kiếm ngữ nghĩa (Semantic Search):
   - Hiểu ý định tìm kiếm thay vì chỉ tìm từ khóa trùng khớp
   - Phân tích ngữ cảnh và ngữ nghĩa của từ khóa
   - Ví dụ: Tìm "máy tính giá rẻ cho sinh viên" sẽ hiểu được nhu cầu về:
     + Laptop/máy tính có mức giá phải chăng
     + Phù hợp nhu cầu học tập (pin tốt, nhẹ, đủ hiệu năng cơ bản)
     + Có thể là hàng đã qua sử dụng nhưng còn tốt
   - Kết quả phản ánh ý định tìm kiếm thực sự của người dùng

2. Tìm kiếm đa ngôn ngữ:
   - Hỗ trợ tìm kiếm bằng tiếng Việt và tiếng Anh
   - Tự động dịch và đối chiếu từ khóa giữa hai ngôn ngữ
   - Hiểu từ lóng, từ viết tắt và biệt ngữ sinh viên
   - Xử lý các lỗi chính tả và dấu câu thiếu/thừa
   - Ví dụ: Tìm "loptop cũ" vẫn hiểu là "laptop cũ"

3. Tìm kiếm đa phương thức (Multimodal Search):
   - Kết hợp văn bản và hình ảnh để tìm kiếm
   - Ví dụ: Tải ảnh ghế và thêm từ khóa "màu nâu" để tìm ghế màu nâu tương tự
   - Nhận diện:
     + Thương hiệu và model sản phẩm từ hình ảnh
     + Màu sắc, họa tiết và kiểu dáng
     + Tình trạng sản phẩm (mới/cũ/hư hỏng)
   - Tính năng "Tìm sản phẩm tương tự" từ trang chi tiết sản phẩm

4. Gợi ý cá nhân hóa:
   - Học từ lịch sử tìm kiếm và duyệt web của bạn
   - Điều chỉnh kết quả dựa trên:
     + Các sản phẩm bạn đã xem gần đây
     + Sở thích đã khai báo trong hồ sơ
     + Xu hướng phổ biến trong sinh viên
     + Vị trí địa lý và thời gian tìm kiếm
   - Tự động cập nhật mô hình AI để gợi ý ngày càng chính xác hơn

5. Tính năng báo cáo và phản hồi:
   - Đánh giá kết quả tìm kiếm (liên quan/không liên quan)
   - Góp ý cải thiện tìm kiếm với nút phản hồi
   - Báo cáo kết quả không phù hợp
   - Mỗi phản hồi giúp cải thiện hệ thống AI

6. Quyền riêng tư trong tìm kiếm thông minh:
   - Kiểm soát dữ liệu được sử dụng trong "Cài đặt" > "Quyền riêng tư"
   - Tắt/bật cá nhân hóa tìm kiếm
   - Xóa lịch sử tìm kiếm bất cứ lúc nào
   - Chế độ tìm kiếm ẩn danh

7. Cập nhật sắp tới:
   - Tìm kiếm bằng giọng nói hỗ trợ tiếng Việt
   - Gợi ý thông minh để hoàn thiện câu tìm kiếm
   - Nhận diện sản phẩm qua camera theo thời gian thực
   - So sánh giá tự động với sản phẩm tương tự trên thị trường

Lưu ý: Tìm kiếm thông minh hoạt động hiệu quả nhất khi bạn cung cấp thông tin cụ thể và đầy đủ. Tính năng này đang được cải thiện liên tục, vì vậy chúng tôi rất mong nhận được phản hồi của bạn.
''',
      'keywords': ['tìm kiếm thông minh', 'AI search', 'tìm kiếm AI', 'semantic search', 'tìm kiếm ngữ nghĩa', 'tìm kiếm hình ảnh'],
      'category': 'search',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 2,
    },

    // DANH MỤC: SUPPORT - HỖ TRỢ
    {
      'title': 'Cách liên hệ bộ phận hỗ trợ',
      'content': '''
Khi cần hỗ trợ từ Student Market NTTU, bạn có thể sử dụng các phương thức liên hệ sau:

1. Trợ lý ảo trong ứng dụng
   - Truy cập: Nhấn vào biểu tượng trợ lý ở góc dưới màn hình chính
   - Hoạt động 24/7, trả lời tự động cho các câu hỏi thường gặp
   - Sử dụng công nghệ AI để hiểu và xử lý yêu cầu bằng ngôn ngữ tự nhiên
   - Có thể giải quyết các vấn đề cơ bản như:
     + Hướng dẫn sử dụng ứng dụng
     + Thông tin về chính sách
     + Trả lời các câu hỏi về đơn hàng
     + Hỗ trợ tìm kiếm sản phẩm
   - Tự động chuyển tiếp đến nhân viên hỗ trợ nếu không thể giải quyết

2. Chat trực tiếp với nhân viên hỗ trợ
   - Truy cập: "Tài khoản" > "Trợ giúp & Hỗ trợ" > "Chat với nhân viên"
   - Thời gian phục vụ: 8:00 - 22:00, từ thứ Hai đến Chủ nhật
   - Thời gian phản hồi trung bình: 2-5 phút trong giờ làm việc
   - Phù hợp cho các vấn đề cần giải quyết nhanh chóng
   - Có thể gửi ảnh chụp màn hình, ảnh sản phẩm để minh họa vấn đề

3. Gửi yêu cầu hỗ trợ
   - Truy cập: "Tài khoản" > "Trợ giúp & Hỗ trợ" > "Gửi yêu cầu"
   - Chọn loại vấn đề gặp phải từ danh sách có sẵn
   - Mô tả chi tiết và đính kèm ảnh chụp màn hình nếu cần
   - Nhập thông tin liên hệ để nhận phản hồi
   - Thời gian phản hồi: 24-48 giờ làm việc qua email hoặc tin nhắn
   - Phù hợp cho các vấn đề phức tạp cần xác minh và điều tra

4. Email hỗ trợ (theo bộ phận)
   - Hỗ trợ chung: support@studentmarket.nttu.edu.vn
   - Vấn đề thanh toán: payment@studentmarket.nttu.edu.vn
   - Khiếu nại, tranh chấp: dispute@studentmarket.nttu.edu.vn
   - Báo cáo vi phạm: report@studentmarket.nttu.edu.vn
   - Đối tác, hợp tác: partnership@studentmarket.nttu.edu.vn
   - Ghi rõ tiêu đề email và vấn đề cần hỗ trợ
   - Cung cấp thông tin tài khoản và ID giao dịch/đơn hàng (nếu có)

5. Hotline hỗ trợ
   - Số điện thoại chung: 028.3456.7890
   - Hỗ trợ thanh toán: 028.3456.7891
   - Hỗ trợ vận chuyển: 028.3456.7892
   - Thời gian làm việc: 8:00 - 20:00, từ thứ Hai đến Chủ nhật
   - Phù hợp cho các vấn đề khẩn cấp cần hỗ trợ ngay lập tức

6. Văn phòng hỗ trợ tại trường
   - Địa điểm: Phòng 103, Tòa nhà A, Trường Đại học NTTU
   - Thời gian: 8:00 - 17:00, từ thứ Hai đến thứ Sáu
   - Đặt lịch hẹn trước qua ứng dụng
   - Hỗ trợ trực tiếp các vấn đề phức tạp
   - Đào tạo sử dụng ứng dụng cho người mới

7. Hỗ trợ qua mạng xã hội
   - Facebook: fb.com/StudentMarketNTTU
   - Instagram: instagram.com/studentmarket_nttu
   - Thời gian phản hồi: 2-24 giờ
   - Chỉ sử dụng để hỏi thông tin chung, không chia sẻ thông tin cá nhân

Lưu ý khi liên hệ hỗ trợ:
- Cung cấp thông tin đầy đủ để được hỗ trợ nhanh chóng
- Screenshot lỗi hoặc vấn đề bạn gặp phải (nếu có)
- Nêu rõ các bước bạn đã thử để giải quyết vấn đề
- Các trường hợp khẩn cấp về bảo mật hoặc thanh toán sẽ được ưu tiên xử lý
- Thời gian phản hồi có thể kéo dài trong dịp lễ, Tết
- Luôn kiểm tra email và thông báo từ ứng dụng để nhận cập nhật về yêu cầu hỗ trợ

Mã số yêu cầu hỗ trợ của bạn sẽ có định dạng SM-XXXXXX, vui lòng sử dụng mã này khi trao đổi về vấn đề của bạn.
''',
      'keywords': ['hỗ trợ', 'liên hệ', 'support', 'trợ giúp', 'hotline', 'email', 'giúp đỡ', 'chat'],
      'category': 'support',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 1,
    },
    {
      'title': 'Cách giải quyết tranh chấp giao dịch',
      'content': '''
Khi gặp tranh chấp trong giao dịch trên Student Market NTTU, hãy tuân theo quy trình sau:

1. Tìm hiểu các loại tranh chấp được hỗ trợ:
   - Sản phẩm không đúng mô tả (khác với hình ảnh hoặc thông tin)
   - Sản phẩm bị hỏng/khiếm khuyết khi nhận hàng
   - Không nhận được hàng sau thời gian giao hàng ước tính
   - Người bán không phản hồi sau khi thanh toán
   - Người mua không thanh toán hoặc nhận hàng
   - Vấn đề về thanh toán (bị trừ tiền nhưng đơn hàng bị hủy)
   - Bị tính phí không rõ ràng hoặc phí cao hơn thỏa thuận

2. Thời hạn báo cáo vấn đề:
   - Đối với sản phẩm đã nhận: trong vòng 48 giờ sau khi nhận hàng
   - Đối với sản phẩm không nhận được: trong vòng 7 ngày sau ngày giao dự kiến
   - Đối với vấn đề thanh toán: trong vòng 30 ngày kể từ ngày thanh toán
   - Lưu ý: Vượt quá thời hạn trên sẽ khó khăn trong việc giải quyết tranh chấp

3. Bước 1: Liên hệ trực tiếp với bên còn lại
   - Sử dụng tính năng chat trong ứng dụng (không trao đổi bên ngoài)
   - Mô tả vấn đề một cách lịch sự, rõ ràng và cung cấp bằng chứng
   - Đề xuất giải pháp hợp lý (đổi/trả hàng, hoàn tiền một phần/toàn bộ)
   - Thảo luận để tìm ra thỏa thuận chung
   - Ghi lại toàn bộ cuộc trò chuyện làm bằng chứng
   - Thời gian khuyến nghị cho bước này: 1-3 ngày

4. Bước 2: Nộp đơn yêu cầu hỗ trợ (nếu bước 1 không thành công)
   - Vào "Tài khoản" > "Đơn hàng của tôi" > chọn đơn hàng có vấn đề
   - Nhấn "Báo cáo vấn đề" và chọn loại tranh chấp từ danh sách
   - Cung cấp thông tin chi tiết:
     + Mô tả vấn đề (càng cụ thể càng tốt)
     + Thời gian phát hiện vấn đề
     + Các bước đã thực hiện để liên hệ bên kia
     + Giải pháp mong muốn
   - Cung cấp bằng chứng (tối đa 5 tệp, mỗi tệp không quá 10MB):
     + Hình ảnh/video sản phẩm thực tế
     + Ảnh chụp mô tả sản phẩm khi đặt hàng
     + Tin nhắn trao đổi với bên kia
     + Biên lai thanh toán, xác nhận đơn hàng
   - Nêu rõ yêu cầu giải quyết (hoàn tiền, đổi hàng, bồi thường...)
   - Bạn sẽ nhận được mã số tranh chấp để theo dõi tiến trình

5. Bước 3: Đội ngũ hỗ trợ xem xét tranh chấp
   - Kiểm tra thông tin và bằng chứng từ cả hai bên
   - Có thể yêu cầu thêm thông tin hoặc bằng chứng bổ sung
   - Liên hệ để làm rõ thêm thông tin (nếu cần)
   - Phân tích dựa trên:
     + Chính sách của Student Market NTTU
     + Thông tin sản phẩm trong mô tả
     + Bằng chứng cung cấp bởi các bên
     + Lịch sử giao dịch của cả người mua và người bán
   - Đưa ra quyết định cuối cùng
   - Thời gian xử lý: 3-7 ngày làm việc tùy độ phức tạp

6. Bước 4: Thực hiện quyết định giải quyết
   - Hoàn tiền: Tiền sẽ được hoàn về phương thức thanh toán ban đầu
     + Thẻ tín dụng/ghi nợ: 7-14 ngày làm việc
     + Ví điện tử: 1-3 ngày làm việc
     + Tài khoản ngân hàng: 3-5 ngày làm việc
   - Đổi hàng: Người bán sẽ được yêu cầu gửi sản phẩm thay thế
   - Bồi thường một phần: Hoàn trả một phần giá trị giao dịch
   - Đóng tranh chấp: Nếu tìm thấy không có cơ sở cho khiếu nại

7. Biện pháp phòng tránh tranh chấp:
   - Người bán:
     + Mô tả chính xác và đầy đủ về sản phẩm
     + Chụp ảnh rõ ràng ở nhiều góc độ
     + Đóng gói cẩn thận, có video quá trình đóng gói
     + Ghi chú rõ các khuyết điểm (nếu có)
     + Sử dụng dịch vụ vận chuyển có bảo hiểm cho sản phẩm giá trị cao
   - Người mua:
     + Đọc kỹ mô tả và đánh giá về người bán
     + Đặt câu hỏi trước khi mua nếu không chắc chắn
     + Quay video khi mở hàng
     + Kiểm tra kỹ sản phẩm trước khi xác nhận "Đã nhận hàng"

Lưu ý:
- Giữ nguyên tình trạng sản phẩm có vấn đề để làm bằng chứng
- Không tự ý trả lại hàng mà không có sự đồng ý của người bán hoặc đội ngũ hỗ trợ
- Quyết định từ đội ngũ hỗ trợ là quyết định cuối cùng sau khi xem xét đầy đủ
- Các trường hợp gian lận hoặc lạm dụng chính sách sẽ bị xử lý theo điều khoản sử dụng
- Tranh chấp có giá trị lớn (trên 10 triệu đồng) có thể được đưa ra Hội đồng hòa giải
''',
      'keywords': ['tranh chấp', 'khiếu nại', 'hoàn tiền', 'đổi trả', 'bồi thường', 'báo cáo', 'vấn đề', 'dispute'],
      'category': 'support',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 2,
    },
    {
      'title': 'Chính sách đổi trả và hoàn tiền',
      'content': '''
Chính sách đổi trả và hoàn tiền của Student Market NTTU:

1. Điều kiện được đổi trả và hoàn tiền:
   - Sản phẩm không đúng với mô tả (khác biệt về màu sắc, kích thước, chất liệu...)
   - Sản phẩm bị lỗi, hư hỏng khi nhận hàng (không do người mua gây ra)
   - Sản phẩm giả, nhái, không đúng thương hiệu như công bố
   - Sản phẩm không hoạt động đúng chức năng được mô tả
   - Sản phẩm thiếu phụ kiện được cam kết kèm theo
   - Người bán gửi sai sản phẩm so với đơn đặt hàng
   - Người bán không giao hàng sau thời gian cam kết

2. Thời hạn yêu cầu đổi trả:
   - Sản phẩm thông thường: trong vòng 48 giờ kể từ khi nhận hàng
   - Sản phẩm điện tử: trong vòng 7 ngày kể từ khi nhận hàng
   - Sản phẩm có bảo hành: theo thời hạn trong chính sách bảo hành
   - Không nhận được hàng: trong vòng 7 ngày sau ngày giao hàng dự kiến

3. Các trường hợp không được đổi trả:
   - Sản phẩm đã qua sử dụng (trừ khi phát hiện lỗi khi sử dụng)
   - Sản phẩm bị hư hỏng do người mua
   - Khác biệt không đáng kể so với mô tả (màu sắc hơi khác do điều kiện ánh sáng...)
   - Sản phẩm được đánh dấu "Không đổi trả" trong mô tả và người mua đã đồng ý
   - Quá thời hạn yêu cầu đổi trả
   - Không còn đầy đủ bao bì, nhãn mác, phụ kiện kèm theo
   - Các sản phẩm đặc biệt: thực phẩm đã mở, đồ lót, tai nghe đã sử dụng...

4. Quy trình đổi trả và hoàn tiền:
   - Bước 1: Liên hệ người bán thông qua chat trong ứng dụng
     + Giải thích vấn đề và gửi hình ảnh/video minh chứng
     + Yêu cầu giải pháp (đổi sản phẩm mới hoặc hoàn tiền)
   - Bước 2: Nếu người bán đồng ý
     + Người bán sẽ gửi hướng dẫn đổi trả và mã xác nhận
     + Đóng gói sản phẩm cẩn thận với tất cả phụ kiện kèm theo
     + Gửi trả sản phẩm theo hướng dẫn của người bán
   - Bước 3: Nếu người bán từ chối hoặc không phản hồi trong 48 giờ
     + Vào "Đơn hàng của tôi" > chọn đơn hàng > "Yêu cầu đổi trả"
     + Điền thông tin chi tiết và tải lên bằng chứng
     + Đội ngũ hỗ trợ sẽ xem xét yêu cầu trong vòng 3-5 ngày làm việc

5. Phương thức hoàn tiền:
   - Hoàn tiền vào phương thức thanh toán ban đầu
     + Thẻ tín dụng/ghi nợ: 7-14 ngày làm việc
     + Ví điện tử: 1-3 ngày làm việc
     + Tài khoản ngân hàng: 3-5 ngày làm việc
     + NTT Point: hoàn trả ngay lập tức
   - Hoàn tiền vào số dư tài khoản Student Market (xử lý nhanh hơn)
   - Các hình thức hoàn tiền:
     + Hoàn tiền toàn bộ: bao gồm giá sản phẩm và phí vận chuyển
     + Hoàn tiền một phần: theo thỏa thuận hoặc quyết định của đội ngũ hỗ trợ
     + Hoàn tiền dưới dạng NTT Point (có thể có giá trị cao hơn 10-20%)

6. Chi phí đổi trả:
   - Lỗi từ người bán: người bán chịu chi phí vận chuyển đổi trả
   - Lỗi từ người mua: người mua chịu chi phí vận chuyển đổi trả
   - Tranh chấp: theo quyết định của đội ngũ hỗ trợ sau khi xem xét
   - Đổi size/màu sắc (không phải lỗi): người mua chịu chi phí vận chuyển

7. Mẹo để đảm bảo quyền lợi:
   - Chụp ảnh/quay video khi mở gói hàng
   - Kiểm tra kỹ sản phẩm trước khi xác nhận "Đã nhận hàng"
   - Lưu giữ tất cả hóa đơn, biên lai, tin nhắn trao đổi
   - Đọc kỹ chính sách đổi trả của người bán trước khi mua
   - Ưu tiên phương thức thanh toán có bảo vệ người mua

Lưu ý: Chính sách này áp dụng cho hầu hết các giao dịch trên Student Market NTTU. Tuy nhiên, một số người bán có thể có chính sách riêng được nêu rõ trong trang sản phẩm, vui lòng đọc kỹ trước khi mua.
''',
      'keywords': ['đổi trả', 'hoàn tiền', 'refund', 'return', 'đổi hàng', 'trả lại', 'bảo hành', 'lỗi sản phẩm'],
      'category': 'support',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 3,
    },

    // DANH MỤC: SHIPPING - VẬN CHUYỂN
    {
      'title': 'Các phương thức giao hàng',
      'content': '''
Student Market NTTU hỗ trợ các phương thức giao hàng sau:

1. Giao hàng nội bộ trường (Campus Delivery)
   - Áp dụng cho giao dịch trong khuôn viên trường
   - Thời gian giao hàng: 1-24 giờ
   - Phí giao hàng: Miễn phí
   - Yêu cầu: Cả người mua và người bán đều là sinh viên NTTU đã xác thực

2. Giao hàng trực tiếp (Face-to-face)
   - Người mua và người bán gặp trực tiếp để trao đổi
   - Địa điểm: Có thể chọn địa điểm công cộng an toàn 
   - Phí giao hàng: Không có
   - Lưu ý: Nên gặp tại nơi công cộng, đông người cho an toàn

3. Giao hàng qua dịch vụ đối tác (Partner Delivery)
   - Đối tác: Grab Express, Ahamove, Giao Hàng Nhanh
   - Thời gian giao hàng: 1-3 ngày trong thành phố, 3-7 ngày liên tỉnh
   - Phí giao hàng: Theo tính toán của đối tác (khoảng cách, trọng lượng)
   - Ưu điểm: Giảm 50% phí vận chuyển cho sinh viên đã xác thực

4. Giao hàng tiêu chuẩn (Standard Shipping)
   - Đối tác: Vietnam Post, VNPost, J&T Express
   - Thời gian giao hàng: 3-7 ngày
   - Phí giao hàng: Theo bảng giá vận chuyển
   - Phù hợp cho các mặt hàng giá trị thấp và trung bình

Quy trình giao nhận hàng:
1. Người bán chuẩn bị hàng và đóng gói cẩn thận
2. Chọn phương thức vận chuyển trong ứng dụng
3. In vận đơn hoặc chuẩn bị thông tin giao hàng
4. Giao hàng cho đơn vị vận chuyển hoặc trực tiếp cho người mua
5. Theo dõi trạng thái giao hàng qua ứng dụng
6. Xác nhận đã nhận hàng trong ứng dụng sau khi kiểm tra

Lưu ý:
- Đóng gói sản phẩm cẩn thận để tránh hư hỏng trong quá trình vận chuyển
- Kiểm tra kỹ thông tin người nhận, địa chỉ trước khi gửi hàng
- Có thể mua bảo hiểm cho các sản phẩm có giá trị cao
- Sử dụng tính năng theo dõi đơn hàng để cập nhật trạng thái giao hàng
''',
      'keywords': ['giao hàng', 'vận chuyển', 'shipping', 'delivery', 'đối tác giao hàng', 'phí vận chuyển'],
      'category': 'shipping',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 1,
    },
  ];

  static Future<void> seedDatabase() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    
    // Xóa dữ liệu cũ nếu cần
    final existingDocs = await firestore.collection('knowledge_documents').get();
    for (var doc in existingDocs.docs) {
      batch.delete(doc.reference);
    }
    
    // Thêm dữ liệu mới
    for (var docData in knowledgeDocuments) {
      final docRef = firestore.collection('knowledge_documents').doc();
      batch.set(docRef, docData);
    }
    
    // Commit batch
    await batch.commit();
    print('Đã seed ${knowledgeDocuments.length} tài liệu vào cơ sở tri thức');
  }
} 