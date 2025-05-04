# Firebase Cloud Functions cho Student Market NTTU

Thư mục này chứa các Cloud Functions sử dụng trong ứng dụng Student Market NTTU.

## Các chức năng

1. **sendFCM** - Gửi thông báo FCM đến người dùng cụ thể
2. **sendChatNotification** - Tự động gửi thông báo khi có tin nhắn mới

## Cách triển khai

### Yêu cầu

- Node.js (v14 trở lên)
- Firebase CLI
- Dự án Firebase với Firestore và Cloud Messaging

### Cài đặt

1. Cài đặt Firebase CLI nếu chưa có:
   ```bash
   npm install -g firebase-tools
   ```

2. Đăng nhập vào Firebase:
   ```bash
   firebase login
   ```

3. Khởi tạo thư mục functions (nếu chưa có):
   ```bash
   cd functions
   npm install
   ```

4. Cài đặt các dependencies:
   ```bash
   npm install firebase-admin firebase-functions
   ```

### Triển khai

Triển khai Cloud Functions lên Firebase:

```bash
firebase deploy --only functions
```

Hoặc triển khai từng chức năng cụ thể:

```bash
firebase deploy --only functions:sendFCM
firebase deploy --only functions:sendChatNotification
```

## Sử dụng trong Flutter

Trong ứng dụng Flutter, sử dụng package `cloud_functions` để gọi các Cloud Functions:

```dart
import 'package:cloud_functions/cloud_functions.dart';

Future<void> sendNotification() async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('sendFCM');
    final result = await callable.call({
      'targetUserId': 'user123',
      'title': 'Thông báo mới',
      'body': 'Bạn có một thông báo mới',
      'data': {
        'type': 'chat_message',
        'chatId': 'chat123'
      }
    });
    
    print('Kết quả: ${result.data}');
  } catch (e) {
    print('Lỗi: $e');
  }
}
```

## Lưu ý bảo mật

Cloud Functions được cấu hình để yêu cầu xác thực. Người dùng phải đăng nhập thì mới có thể gọi các functions. 