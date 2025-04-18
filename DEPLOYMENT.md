# Hướng dẫn triển khai ứng dụng Student Market NTTU

## API Key và Biến môi trường

### Cho phát triển

1. **Thiết lập tệp .env**:
   - Tạo tệp `.env` trong thư mục gốc của dự án
   - Thêm API key Gemini:
     ```
     GEMINI_API_KEY=your_api_key_here
     ```
   - Tệp này đã được cấu hình để đưa vào bundle khi build ứng dụng

2. **Sử dụng API key khi build**:
   - Bạn có thể truyền API key qua tham số khi build:
     ```bash
     flutter build apk --dart-define=GEMINI_API_KEY=your_api_key_here
     ```

### Cho triển khai sản phẩm thực tế

Đối với môi trường production, bạn nên:

1. **Sử dụng CI/CD**:
   - Lưu trữ API key trong biến môi trường của hệ thống CI/CD
   - Truyền giá trị này vào quá trình build thông qua `--dart-define`

2. **Đối với Android**:
   - Lưu API key trong tệp `local.properties` (đã được gitignore)
   - Hoặc sử dụng biến môi trường thông qua Gradle

3. **Đối với iOS**:
   - Sử dụng Xcconfig để quản lý biến môi trường
   - Hoặc sử dụng biến môi trường thông qua các công cụ CI như Fastlane

4. **Đối với Web**:
   - Sử dụng biến môi trường của máy chủ web (như Firebase Hosting, Netlify, Vercel)
   - Cấu hình để chèn giá trị vào runtime

## Cách ứng dụng truy cập API key

Ứng dụng truy cập API key theo thứ tự ưu tiên sau:

1. Từ tệp `.env` (được nạp khi khởi động)
2. Từ biến môi trường được truyền qua `--dart-define`
3. Sử dụng giá trị mặc định nếu không có nguồn nào khác

## Bảo mật

- **KHÔNG** đưa API key thật vào mã nguồn
- **KHÔNG** commit tệp `.env` chứa API key thật (chỉ commit `.env.example`)
- Sử dụng Firebase App Check hoặc giới hạn domain cho API key khi có thể
- Xem xét việc sử dụng proxy server để che giấu API key khỏi client

## Vấn đề thường gặp

- Nếu ứng dụng không thể tải tệp `.env`, nó sẽ sử dụng giá trị dự phòng hoặc giá trị từ `--dart-define`
- Nếu gặp vấn đề với API Gemini, kiểm tra log để xem thông báo lỗi chi tiết 