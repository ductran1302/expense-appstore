# Chi Tiêu — Expense Tracker

App iOS quản lý chi tiêu cá nhân, viết bằng **SwiftUI + SwiftData + Swift Charts**.
Toàn bộ dữ liệu lưu **cục bộ** trên máy (không cần tài khoản, không gửi dữ liệu lên internet).

| Giao dịch | Thống kê | Ngân sách | Cài đặt |
|---|---|---|---|
| Thêm / sửa / xoá, lọc theo danh mục, tìm kiếm | Biểu đồ tròn theo danh mục, cột theo ngày, so sánh tháng trước | Hạn mức tổng & theo danh mục, cảnh báo vượt hạn mức | Đổi tiền tệ, quản lý danh mục, sao lưu JSON, xuất CSV |

## Yêu cầu

- macOS + **Xcode 16 trở lên**
- iOS **17.0** trở lên (iPhone/iPad)
- Tài khoản Apple Developer (99 USD/năm) để đưa lên App Store

## Chạy app trên máy Mac

```bash
git clone https://github.com/ductran1302/expense-appstore.git
cd expense-appstore
open ExpenseTracker.xcodeproj
```

Trong Xcode:

1. Chọn target **ExpenseTracker** > tab **Signing & Capabilities**.
2. Chọn **Team** của bạn (nếu chưa có, chọn `Add an Account...` và đăng nhập Apple ID).
3. Nếu Bundle ID bị trùng, đổi thành ID riêng của bạn, ví dụ `com.yourname.chitieuthanh`.
4. Chọn simulator hoặc iPhone của bạn, nhấn **⌘R**.

> Nếu Xcode báo lỗi signing, mở `Signing & Capabilities` > tick **Automatically manage signing**.

## Đưa lên App Store

1. **Product > Destination > Any iOS Device (arm64)**.
2. **Product > Archive**.
3. Trong Xcode Organizer: **Distribute App** > **App Store Connect** > đăng nhập Apple ID.
4. Upload lên App Store Connect, điền thông tin app:
   - **App Name**: `Chi Tiêu`
   - **Primary Category**: Finance
   - **Age Rating**: 4+
   - **Privacy**: app không thu thập dữ liệu → chọn "Data Not Collected"
5. Chờ duyệt (thường 1–24 giờ).

### Trước khi submit, kiểm tra lại

- [ ] Đổi `PRODUCT_BUNDLE_IDENTIFIER` thành ID riêng
- [ ] Chọn Development Team
- [ ] Bump `MARKETING_VERSION` (ví dụ `1.0.1`) và `CURRENT_PROJECT_VERSION` trong project settings
- [ ] Kiểm tra icon 1024×1024 trong `Assets.xcassets/AppIcon.appiconset`
- [ ] Cập nhật mô tả, ảnh chụp màn hình (bắt buộc: 6.7" và 5.5")
- [ ] `PrivacyInfo.xcprivacy` đã có sẵn (không tracking, không thu thập data)

## Cấu trúc dự án

```
ExpenseTracker/
├── App/
│   ├── ExpenseTrackerApp.swift      # Điểm vào, khởi tạo ModelContainer
│   ├── RootView.swift               # TabView gồm 4 tab
│   └── AppState.swift               # State dùng chung (tiền tệ, tháng đang xem)
├── Models/
│   ├── ExpenseTransaction.swift     # Giao dịch
│   ├── ExpenseCategory.swift        # Danh mục
│   └── MonthlyBudget.swift          # Hạn mức theo tháng
├── Features/
│   ├── Transactions/                # Danh sách, form thêm/sửa
│   ├── Stats/                       # Biểu đồ
│   ├── Budget/                      # Hạn mức
│   └── Settings/                    # Cài đặt, quản lý danh mục
├── Services/
│   ├── BackupService.swift          # Export/Import JSON, xuất CSV
│   ├── CurrencyFormatter.swift      # Định dạng tiền tệ
│   ├── SeedData.swift               # Danh mục & giao dịch mẫu
│   └── ExportDocument.swift
├── Shared/
│   ├── Theme.swift                  # Màu, thẻ, StatTile
│   ├── MonthPicker.swift
│   ├── Calendar+Months.swift
│   ├── Color+Hex.swift
│   └── DecimalParser.swift
├── Assets.xcassets/
├── Info.plist
└── PrivacyInfo.xcprivacy
```

## Công cụ (chạy được trên Windows)

Vì `.xcodeproj` được sinh tự động bằng script nên không cần mở/sửa project bằng tay trên Windows.

```bash
# Thêm/bớt file Swift rồi cập nhật lại project
python tools/generate_xcodeproj.py

# Kiểm tra project còn hợp lệ không
python tools/validate_xcodeproj.py

# Sinh lại app icon
python tools/generate_app_icon.py
```

Cần Python 3.9+ (script sinh icon cần thêm `pip install pillow`).

## Tính năng chi tiết

### Giao dịch
- Nhập nhanh số tiền (bàn phím số), chọn danh mục, ngày giờ, ghi chú
- Vuốt để xoá, chạm để sửa
- Nhóm theo ngày, hiển thị tổng chi mỗi ngày
- Lọc theo danh mục, tìm kiếm theo ghi chú/danh mục
- Chế độ "Thu nhập" (số tiền âm, hiển thị màu xanh)

### Thống kê
- Biểu đồ tròn (donut) theo danh mục
- Biểu đồ cột theo từng ngày trong tháng
- Tổng chi, thu nhập, trung bình/ngày, so sánh với tháng trước

### Ngân sách
- Hạn mức tổng theo tháng + hạn mức riêng cho từng danh mục
- Thanh tiến trình đổi màu: xanh (<80%), vàng (80–100%), đỏ (>100%)
- Hiển thị số tiền còn lại / vượt hạn mức

### Sao lưu
- **JSON** — toàn bộ danh mục, giao dịch, hạn mức (dùng để khôi phục, import tự bỏ qua trùng lặp)
- **CSV** — danh sách giao dịch, mở bằng Excel/Numbers

## Định hướng mở rộng

- Đồng bộ đám mây qua CloudKit (SwiftData hỗ trợ sẵn, chỉ cần đổi `ModelConfiguration`)
- Widget hiển thị tổng chi ngày hôm nay
- App Watch
- Đa ngôn ngữ (Việt/Anh) qua String Catalog
