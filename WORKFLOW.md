# 🔄 Luồng hoạt động hệ thống

## 1. 👤 Customer Flow

### 1.1. Đăng ký / Đăng nhập
```
Customer mở app → Đăng ký/Đăng nhập → Firebase Auth → Tạo user document trong Firestore
```

### 1.2. Xem thực đơn và đặt món
```
Xem menu → Chọn món → Thêm vào giỏ hàng → Nhập số bàn → Xác nhận đặt món
→ Tạo Order document trong Firestore (status: pending)
```

### 1.3. Theo dõi đơn hàng
```
Vào tab "Đơn hàng" → Xem danh sách đơn hàng (real-time từ Firestore)
→ Tap vào đơn → Xem chi tiết và trạng thái real-time
```

### Trạng thái đơn hàng customer thấy:
- ⏳ **Chờ xử lý** (pending) - Đơn vừa đặt
- ✅ **Đã xác nhận** (confirmed) - Nhà hàng đã nhận
- 👨‍🍳 **Đang chuẩn bị** (preparing) - Bếp đang nấu
- ✅ **Sẵn sàng** (ready) - Món đã xong, chờ phục vụ
- 🎉 **Hoàn thành** (completed) - Đã phục vụ xong
- ❌ **Đã hủy** (cancelled) - Đơn bị hủy

---

## 2. 👨‍🍳 Staff Flow (Kitchen Display System)

### 2.1. Đăng nhập
```
Staff mở app → Đăng nhập → Firebase Auth kiểm tra role = 'staff'
```

### 2.2. Xử lý đơn hàng
```
Màn hình Kitchen Display → Stream orders từ Firestore (status: pending, confirmed, preparing, ready)
→ Đơn mới xuất hiện tự động
```

### 2.3. Cập nhật trạng thái
```
pending → [Nút "XÁC NHẬN"] → confirmed
confirmed → [Nút "CHUẨN BỊ"] → preparing
preparing → [Nút "SẴN SÀNG"] → ready
ready → [Nút "ĐÃ PHỤC VỤ"] → completed (đơn biến mất khỏi màn hình)
```

### Filter đơn hàng:
- **Tất cả**: Hiển thị mọi đơn đang active
- **Đơn mới**: Chỉ pending
- **Đang làm**: Chỉ preparing
- **Sẵn sàng**: Chỉ ready

---

## 3. 👨‍💼 Admin Flow

### 3.1. Dashboard
```
Admin đăng nhập → Xem dashboard với thống kê:
- Thống kê tháng này: Doanh thu, đơn hoàn thành, đơn hủy, tổng đơn
- Thống kê hôm nay: Doanh thu, đơn hàng, đơn đang xử lý
- Biểu đồ doanh thu theo giờ
- Top 5 món bán chạy
```

### 3.2. Quản lý thực đơn
```
Tab "Thực đơn" → Xem danh sách món
→ Thêm món mới / Sửa món / Xóa món / Bật/Tắt món
→ Cập nhật Firestore → Real-time update trên customer app
```

### 3.3. Quản lý đơn hàng
```
Tab "Đơn hàng" → Xem tất cả đơn
→ Filter: Tất cả / Đang xử lý / Hoàn thành / Đã hủy
→ Xem chi tiết đơn / Hủy đơn (nếu cần)
```

---

## 4. 🔥 Firebase Real-time Flow

### 4.1. Khi customer đặt món
```
Customer app → Firestore.collection('orders').add()
↓
Firestore triggers real-time listener
↓
Staff app nhận order mới ngay lập tức (stream)
Admin dashboard cập nhật số liệu
```

### 4.2. Khi staff cập nhật trạng thái
```
Staff app → Firestore.collection('orders').doc(orderId).update({status: 'preparing'})
↓
Firestore triggers real-time listener
↓
Customer app cập nhật trạng thái đơn hàng ngay lập tức
Admin dashboard cập nhật số liệu
```

### 4.3. Khi admin thêm/sửa món
```
Admin app → Firestore.collection('menuItems').add()/update()
↓
Firestore triggers real-time listener
↓
Customer app cập nhật menu ngay lập tức
```

---

## 5. 🎯 Use Cases chính

### Use Case 1: Đặt món và xử lý đơn
```
1. Customer: Chọn món → Đặt món (pending)
2. Staff: Nhận đơn → Xác nhận (confirmed)
3. Staff: Bắt đầu nấu (preparing)
4. Staff: Món xong (ready)
5. Staff: Phục vụ xong (completed)
6. Customer: Thấy đơn hoàn thành trong lịch sử
```

### Use Case 2: Admin quản lý menu
```
1. Admin: Thêm món mới / Cập nhật giá
2. System: Firestore cập nhật
3. Customer: Thấy món mới ngay lập tức
```

### Use Case 3: Xem thống kê
```
1. Admin: Vào Dashboard
2. System: Query Firestore
   - Orders trong tháng hiện tại
   - Tính toán: doanh thu, đơn hoàn thành, đơn hủy
   - Real-time updates
3. Admin: Xem biểu đồ và số liệu
```

---

## 6. 🔐 Security Flow

### Firestore Rules
```
- Customer: Chỉ đọc orders của mình, tạo order mới
- Staff: Đọc tất cả orders, cập nhật status
- Admin: Full access tất cả collections
```

### Authentication Flow
```
1. User login → Firebase Auth
2. Get user role từ Firestore users collection
3. Route to appropriate app (customer/staff/admin)
4. Apply security rules based on role
```


