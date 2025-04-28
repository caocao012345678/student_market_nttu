// Dữ liệu mẫu cho cơ sở tri thức của chatbot

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/knowledge_base.dart';

class MockKnowledgeData {
  static final List<Map<String, dynamic>> knowledgeDocuments = [
    // DANH MỤC: ACCOUNT - TÀI KHOẢN
    {
      'title': 'Cách đăng ký tài khoản',
      'content': '''
Để đăng ký tài khoản mới trên Student Market NTTU, vui lòng làm theo các bước sau:

1. Mở ứng dụng Student Market NTTU
2. Nhấn vào nút "Đăng ký" ở màn hình đăng nhập
3. Điền đầy đủ thông tin cá nhân, bao gồm:
   - Họ và tên
   - Email (ưu tiên sử dụng email của trường)
   - Mật khẩu (ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường và số)
   - Số điện thoại
4. Đọc và chấp nhận Điều khoản sử dụng
5. Nhấn nút "Đăng ký"
6. Xác nhận email thông qua liên kết được gửi đến địa chỉ email của bạn
7. Sau khi xác nhận email, tài khoản của bạn đã sẵn sàng sử dụng

Lưu ý: Nếu bạn là sinh viên NTTU, vui lòng sử dụng email của trường để được hưởng các đặc quyền dành cho sinh viên.
''',
      'keywords': ['đăng ký', 'tài khoản', 'đăng ký tài khoản', 'tạo tài khoản', 'đăng nhập lần đầu', 'account'],
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
4. Nếu bạn quên đăng xuất trên thiết bị này trước đó, ứng dụng sẽ tự động đăng nhập

Khôi phục mật khẩu:
1. Trên màn hình đăng nhập, nhấn vào "Quên mật khẩu"
2. Nhập email đăng ký tài khoản của bạn
3. Nhấn "Gửi yêu cầu"
4. Kiểm tra hộp thư email của bạn (bao gồm thư mục spam)
5. Nhấn vào liên kết khôi phục mật khẩu trong email
6. Tạo mật khẩu mới và xác nhận
7. Đăng nhập lại với mật khẩu mới

Lưu ý: Liên kết khôi phục mật khẩu chỉ có hiệu lực trong 24 giờ. Nếu bạn không nhận được email, vui lòng kiểm tra thư mục spam hoặc gửi lại yêu cầu.
''',
      'keywords': ['đăng nhập', 'quên mật khẩu', 'khôi phục mật khẩu', 'mật khẩu', 'login', 'lấy lại mật khẩu'],
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
   - Khoa/Ngành học
   - Năm học
5. Tải lên ảnh thẻ sinh viên hoặc biên lai đóng học phí gần nhất
6. Nhấn "Gửi xác thực"
7. Chờ duyệt (thường trong vòng 24-48 giờ)

Sau khi được xác thực, bạn sẽ nhận được:
- Badge "Sinh viên NTTU" trên trang cá nhân
- Giảm phí giao dịch 50%
- Khả năng tiếp cận các chương trình ưu đãi dành cho sinh viên
- Ưu tiên hiển thị trong kết quả tìm kiếm

Lưu ý: Nếu quá 48 giờ chưa nhận được phản hồi, vui lòng liên hệ bộ phận hỗ trợ qua mục "Trợ giúp" > "Liên hệ hỗ trợ".
''',
      'keywords': ['xác thực', 'sinh viên', 'tài khoản sinh viên', 'verification', 'xác minh'],
      'category': 'account',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 3,
    },

    // DANH MỤC: PRODUCT - SẢN PHẨM
    {
      'title': 'Cách đăng bán sản phẩm',
      'content': '''
Để đăng sản phẩm bán trên Student Market NTTU, thực hiện theo các bước sau:

1. Đăng nhập vào tài khoản của bạn
2. Nhấn vào nút "+" ở góc dưới màn hình hoặc vào "Tài khoản" > "Sản phẩm của tôi" > "Đăng sản phẩm mới"
3. Điền thông tin sản phẩm:
   - Tên sản phẩm: ngắn gọn, rõ ràng và chứa từ khóa chính
   - Danh mục: chọn đúng danh mục để người mua dễ tìm thấy
   - Giá bán: đặt giá hợp lý, có thể tham khảo sản phẩm tương tự
   - Số lượng: số lượng sẵn có để bán
   - Mô tả: chi tiết về tình trạng, đặc điểm, chức năng của sản phẩm
   - Thông số: kích thước, màu sắc, thông số kỹ thuật (nếu có)
4. Tải lên ít nhất 3 ảnh chất lượng cao của sản phẩm, chụp ở các góc khác nhau
5. Thêm các từ khóa/tag để tăng khả năng tìm kiếm
6. Chọn phương thức giao hàng và thanh toán được chấp nhận
7. Nhấn "Xem trước" để kiểm tra lại thông tin
8. Nhấn "Đăng sản phẩm" để hoàn tất

Lưu ý:
- Sản phẩm sẽ được kiểm duyệt trước khi hiển thị công khai
- Hãy cung cấp hình ảnh thực tế và mô tả chính xác để tránh khiếu nại
- Không đăng sản phẩm vi phạm quy định của Student Market NTTU
''',
      'keywords': ['đăng bán', 'đăng sản phẩm', 'bán hàng', 'tạo sản phẩm', 'đăng tin'],
      'category': 'product',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 1,
    },
    {
      'title': 'Quy định đăng sản phẩm',
      'content': '''
Khi đăng sản phẩm trên Student Market NTTU, vui lòng tuân thủ các quy định sau:

Sản phẩm được phép:
- Sách, tài liệu học tập
- Thiết bị điện tử, đồ dùng cá nhân đã qua sử dụng
- Dụng cụ học tập, vật dụng trong ký túc xá
- Quần áo, giày dép còn sử dụng tốt
- Đồ thể thao, nhạc cụ
- Dịch vụ gia sư, hỗ trợ học tập

Sản phẩm bị cấm:
- Đồ uống có cồn, thuốc lá và các chất gây nghiện
- Thuốc không kê đơn và vật phẩm y tế không được phép
- Vũ khí, công cụ hỗ trợ, vật liệu nguy hiểm
- Hàng giả, hàng nhái, hàng vi phạm bản quyền
- Sản phẩm khiêu dâm, không lành mạnh
- Thẻ tín dụng, tài khoản số hoặc các dịch vụ tài chính phi pháp
- Sản phẩm vi phạm pháp luật Việt Nam

Yêu cầu về hình ảnh:
- Ít nhất 3 hình ảnh cho mỗi sản phẩm
- Hình ảnh phải là của chính sản phẩm, không sử dụng hình ảnh từ internet
- Hình ảnh rõ nét, chụp đủ góc cạnh và chi tiết sản phẩm
- Không chèn logo, watermark cá nhân lên hình ảnh
- Không sử dụng hình ảnh khiêu dâm, bạo lực

Yêu cầu về mô tả:
- Mô tả trung thực, đầy đủ về sản phẩm
- Nêu rõ khuyết điểm, hư hỏng (nếu có)
- Không quảng cáo quá mức, sai sự thật
- Không chứa thông tin cá nhân như số điện thoại, địa chỉ cụ thể

Mọi sản phẩm đăng tải sẽ được kiểm duyệt trong vòng 24 giờ. Sản phẩm vi phạm quy định sẽ bị từ chối và tài khoản có thể bị hạn chế nếu vi phạm nhiều lần.
''',
      'keywords': ['quy định', 'điều kiện', 'cấm', 'chính sách', 'kiểm duyệt', 'không được phép'],
      'category': 'product',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 2,
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

2. Chuyển khoản ngân hàng
   - Chuyển khoản trực tiếp đến tài khoản người bán
   - Hỗ trợ tất cả ngân hàng nội địa
   - Yêu cầu xác nhận chuyển khoản thông qua ứng dụng

3. Ví điện tử
   - MoMo
   - VNPay
   - ZaloPay
   - ShopeePay

4. Thanh toán bằng NTT Credit
   - Sử dụng điểm uy tín tích lũy trong hệ thống
   - Giảm giá lên đến 50% cho giao dịch
   - Chỉ áp dụng cho sinh viên đã xác thực

5. Thanh toán trả góp (cho sản phẩm trên 1 triệu đồng)
   - Trả góp 3 tháng không lãi suất
   - Yêu cầu xác minh tài khoản và có điểm tín dụng tối thiểu 80

Lưu ý:
- Mọi giao dịch đều được bảo vệ bởi chính sách đảm bảo của Student Market NTTU
- Tiền sẽ được giữ lại trong 24 giờ sau khi người mua xác nhận đã nhận hàng
- Báo cáo ngay nếu bạn gặp vấn đề với thanh toán
''',
      'keywords': ['thanh toán', 'payment', 'phương thức thanh toán', 'COD', 'chuyển khoản', 'ví điện tử'],
      'category': 'payment',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 1,
    },
    {
      'title': 'Cách sử dụng NTT Credit và điểm uy tín',
      'content': '''
NTT Credit là hệ thống điểm uy tín và ưu đãi dành cho người dùng Student Market NTTU:

NTT Point (Điểm thưởng):
- Được nhận khi hoàn thành giao dịch thành công
- Mỗi 10,000đ chi tiêu = 1 NTT Point
- Mỗi đánh giá 5 sao từ người mua/bán = 5 NTT Point
- Mỗi sản phẩm được bán thành công = 10 NTT Point
- Mỗi chia sẻ ứng dụng thành công = 20 NTT Point

Quy đổi NTT Point:
- 1000 NTT Point = giảm 1% giá trị đơn hàng (tối đa 50%)
- 5000 NTT Point = 1 voucher vận chuyển miễn phí
- 10000 NTT Point = 50,000đ tiền mặt
- 20000 NTT Point = 1 tháng thành viên VIP

NTT Credit (Điểm uy tín):
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

Đặc quyền theo điểm uy tín:
- 120+ điểm: Được phép mua trả góp 3 tháng
- 140+ điểm: Được phép bán sản phẩm giá trị cao
- 150+ điểm: Được phép mua trả góp 6 tháng
- 160+ điểm: Được giao dịch không cần đặt cọc
- 180+ điểm: Được ưu tiên hiển thị trong tìm kiếm
- 200+ điểm: Được mời vào chương trình Người bán ưu tú

Lưu ý: Điểm uy tín dưới 60 sẽ bị hạn chế quyền bán hàng và yêu cầu đặt cọc cho mọi giao dịch.
''',
      'keywords': ['ntt credit', 'điểm uy tín', 'điểm thưởng', 'credit', 'ưu đãi', 'giảm giá'],
      'category': 'payment',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 2,
    },

    // DANH MỤC: SEARCH - TÌM KIẾM
    {
      'title': 'Cách tìm kiếm sản phẩm hiệu quả',
      'content': '''
Để tìm kiếm sản phẩm hiệu quả trên Student Market NTTU, hãy thực hiện các bước sau:

Tìm kiếm cơ bản:
1. Nhấn vào biểu tượng kính lúp ở thanh công cụ
2. Nhập từ khóa cần tìm
3. Nhấn Enter hoặc nút Tìm kiếm

Tìm kiếm nâng cao:
1. Mở trang Tìm kiếm
2. Nhập từ khóa chính
3. Sử dụng bộ lọc:
   - Danh mục: Chọn danh mục cụ thể
   - Khoảng giá: Thiết lập giá thấp nhất và cao nhất
   - Tình trạng: Mới, Đã qua sử dụng, Còn bảo hành
   - Vị trí: Chọn khu vực cụ thể
   - Sắp xếp: Giá tăng/giảm, Mới nhất, Phổ biến

Mẹo tìm kiếm hiệu quả:
- Sử dụng từ khóa ngắn gọn và chính xác
- Thử nhiều cách gọi khác nhau của sản phẩm
- Kết hợp tên sản phẩm với thương hiệu, model
- Sử dụng bộ lọc để thu hẹp kết quả
- Sử dụng tính năng "Lưu tìm kiếm" để nhận thông báo khi có sản phẩm mới phù hợp
- Kiểm tra mục "Đề xuất cho bạn" dựa trên lịch sử tìm kiếm
- Dùng tab "Gần bạn" để xem sản phẩm trong bán kính 2km

Tìm kiếm bằng hình ảnh:
1. Nhấn vào biểu tượng camera bên cạnh thanh tìm kiếm
2. Tải lên hình ảnh sản phẩm cần tìm
3. Hệ thống sẽ hiển thị các sản phẩm tương tự

Tính năng "Thông báo khi có hàng":
1. Tìm kiếm sản phẩm bạn muốn
2. Nếu không có kết quả, nhấn "Thông báo khi có hàng" 
3. Thiết lập các tiêu chí
4. Khi có sản phẩm phù hợp, bạn sẽ nhận được thông báo
''',
      'keywords': ['tìm kiếm', 'search', 'tìm sản phẩm', 'bộ lọc', 'filter', 'tìm'],
      'category': 'search',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 1,
    },

    // DANH MỤC: SUPPORT - HỖ TRỢ
    {
      'title': 'Cách liên hệ bộ phận hỗ trợ',
      'content': '''
Khi cần hỗ trợ từ Student Market NTTU, bạn có thể sử dụng các phương thức liên hệ sau:

1. Trợ lý ảo trong ứng dụng
   - Khả dụng 24/7
   - Trả lời tự động cho các câu hỏi thường gặp
   - Chuyển tiếp đến nhân viên hỗ trợ nếu cần thiết

2. Gửi yêu cầu hỗ trợ
   - Mở ứng dụng > Tài khoản > Trợ giúp & Hỗ trợ
   - Chọn loại vấn đề gặp phải
   - Mô tả chi tiết và đính kèm ảnh chụp màn hình nếu cần
   - Thời gian phản hồi: 24-48 giờ làm việc

3. Email hỗ trợ
   - Địa chỉ: support@studentmarket.nttu.edu.vn
   - Ghi rõ tiêu đề email và vấn đề cần hỗ trợ
   - Cung cấp thông tin tài khoản và ID giao dịch (nếu có)

4. Hotline hỗ trợ
   - Số điện thoại: 028.3456.7890
   - Thời gian làm việc: 8:00 - 20:00, từ thứ Hai đến Chủ nhật
   - Hỗ trợ trực tiếp cho các vấn đề khẩn cấp

5. Văn phòng hỗ trợ tại trường
   - Địa điểm: Phòng 103, Tòa nhà A, Trường Đại học NTTU
   - Thời gian: 8:00 - 17:00, từ thứ Hai đến thứ Sáu
   - Đặt lịch hẹn trước qua ứng dụng

Lưu ý:
- Cung cấp thông tin đầy đủ để được hỗ trợ nhanh chóng
- Các trường hợp khẩn cấp về bảo mật hoặc thanh toán sẽ được ưu tiên xử lý
- Thời gian phản hồi có thể kéo dài trong dịp lễ, Tết
''',
      'keywords': ['hỗ trợ', 'liên hệ', 'support', 'trợ giúp', 'hotline', 'email', 'giúp đỡ'],
      'category': 'support',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 1,
    },
    {
      'title': 'Cách giải quyết tranh chấp giao dịch',
      'content': '''
Khi gặp tranh chấp trong giao dịch trên Student Market NTTU, hãy tuân theo quy trình sau:

Bước 1: Liên hệ trực tiếp với bên còn lại
- Sử dụng tính năng chat trong ứng dụng
- Mô tả vấn đề một cách lịch sự và đề xuất giải pháp
- Thảo luận để tìm ra thỏa thuận chung

Bước 2: Nộp đơn yêu cầu hỗ trợ (nếu bước 1 không thành công)
- Vào "Tài khoản" > "Đơn hàng của tôi" > chọn đơn hàng có vấn đề
- Nhấn "Báo cáo vấn đề" và chọn loại tranh chấp:
  + Sản phẩm không đúng mô tả
  + Sản phẩm bị hỏng/khiếm khuyết
  + Không nhận được hàng
  + Vấn đề về thanh toán
  + Khác (nêu rõ chi tiết)
- Cung cấp bằng chứng: hình ảnh, video, tin nhắn trao đổi
- Nêu rõ yêu cầu giải quyết (hoàn tiền, đổi hàng, bồi thường...)

Bước 3: Đội ngũ hỗ trợ xem xét tranh chấp
- Xem xét bằng chứng từ cả hai bên
- Liên hệ để làm rõ thêm thông tin (nếu cần)
- Đưa ra quyết định dựa trên chính sách và điều khoản sử dụng
- Thời gian xử lý: 3-5 ngày làm việc

Bước 4: Thực hiện quyết định giải quyết
- Hoàn tiền: Tiền sẽ được hoàn về phương thức thanh toán ban đầu trong 7-14 ngày
- Đổi hàng: Người bán sẽ được yêu cầu gửi sản phẩm thay thế
- Bồi thường một phần: Hoàn trả một phần giá trị giao dịch

Lưu ý:
- Thời hạn báo cáo vấn đề: trong vòng 7 ngày sau khi nhận hàng
- Giữ nguyên tình trạng sản phẩm có vấn đề để làm bằng chứng
- Không tự ý trả lại hàng mà không có sự đồng ý của người bán hoặc đội ngũ hỗ trợ
- Quyết định từ đội ngũ hỗ trợ là quyết định cuối cùng
- Các trường hợp gian lận hoặc lạm dụng chính sách sẽ bị xử lý theo điều khoản sử dụng
''',
      'keywords': ['tranh chấp', 'khiếu nại', 'hoàn tiền', 'đổi trả', 'bồi thường', 'báo cáo', 'vấn đề'],
      'category': 'support',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'order': 2,
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
   - Ưu đãi: Giảm 50% phí vận chuyển cho sinh viên đã xác thực

4. Giao hàng tiêu chuẩn (Standard Shipping)
   - Đối tác: Vietnam Post, VNPost, J&T Express
   - Thời gian giao hàng: 3-7 ngày
   - Phí giao hàng: Theo bảng giá vận chuyển
   - Phù hợp cho các mặt hàng giá trị thấp và trung bình

5. Giao hàng nhanh (Express Shipping)
   - Đối tác: Giao Hàng Tiết Kiệm, Giao Hàng Nhanh
   - Thời gian giao hàng: 1-3 ngày
   - Phí giao hàng: Cao hơn giao hàng tiêu chuẩn 30-50%
   - Phù hợp cho hàng cần giao nhanh chóng

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