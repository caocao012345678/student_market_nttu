# Hướng dẫn cấu hình API Gemini

Ứng dụng Student Market NTTU sử dụng Gemini AI của Google để cung cấp trợ lý chatbot thông minh. Để thiết lập và chạy chatbot, bạn cần cấu hình API key Gemini.

## Bước 1: Lấy API key Gemini

1. Truy cập [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Đăng nhập bằng tài khoản Google của bạn
3. Tạo API key mới
4. Sao chép API key đã tạo

## Bước 2: Cấu hình cho môi trường phát triển

### Cho ứng dụng mobile và desktop:

1. Tìm tệp `.env` trong thư mục gốc của dự án
2. Thay thế giá trị `YOUR_API_KEY_HERE` bằng API key thực của bạn:

```
GEMINI_API_KEY=your_actual_api_key_here
```

### Cho ứng dụng web:

1. Mở tệp `web/js/env_config.js`
2. Thay thế giá trị mẫu bằng API key thực của bạn:

```javascript
window.ENV = {
  GEMINI_API_KEY: "your_actual_api_key_here"
};
```

## Lưu ý bảo mật

- **KHÔNG** đưa API key thật vào hệ thống kiểm soát phiên bản như Git
- Tệp `.env` và `web/js/env_config.js` đã được thêm vào `.gitignore`
- Khi triển khai ứng dụng lên môi trường production, hãy sử dụng biến môi trường của máy chủ hoặc dịch vụ hosting thay vì lưu API key trực tiếp trong tệp

## Xử lý sự cố

Nếu bạn gặp lỗi "API key không hợp lệ", hãy kiểm tra:

1. API key đã được cập nhật trong tệp `.env` (cho mobile/desktop) và `web/js/env_config.js` (cho web)
2. API key không chứa khoảng trắng ở đầu hoặc cuối
3. API key vẫn đang hoạt động (không bị hết hạn hoặc vô hiệu hóa)

Để kiểm tra API key một cách nhanh chóng, bạn có thể sử dụng cURL:

```bash
curl -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_API_KEY_HERE" \
     -X POST \
     -d '{"contents":[{"parts":[{"text":"Hello, how are you?"}]}]}' \
     "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent"
```

Thay `YOUR_API_KEY_HERE` bằng API key thực của bạn. 