# Chi Tiêu — Expense Tracker

App iOS quản lý chi tiêu cá nhân, viết bằng **SwiftUI + SwiftData + Swift Charts**.
Toàn bộ dữ liệu lưu **cục bộ** trên máy (không cần tài khoản, không gửi dữ liệu lên internet).

| Giao dịch | Thống kê | Ngân sách | Cài đặt |
|---|---|---|---|
| Thêm/sửa/xoá, lọc theo danh mục, tìm kiếm, nhóm theo ngày | Biểu đồ tròn theo danh mục, cột theo ngày, so sánh tháng trước | Hạn mức tổng & theo danh mục, cảnh báo vượt hạn mức | Đổi ngôn ngữ & giao diện, quản lý danh mục, sao lưu JSON, xuất CSV |

## Tính năng nổi bật

- **Hai ngôn ngữ** — Tiếng Việt (mặc định) và English, chuyển ngay trong app, không cần cài lại.
- **Sáng/Tối** — bám theo hệ thống hoặc đặt cứng trong Cài đặt.
- **Định dạng theo vùng** — số tiền và ngày tháng đổi theo locale của ngôn ngữ đang chọn.
- **Đọc được với VoiceOver** — nhãn tiếng Việt/Anh cho mọi biểu tượng và số liệu.
- **Dynamic Type** — toàn bộ chữ dùng text style của hệ thống, không hard-code kích thước.
- **12 loại tiền tệ** — VND, USD, EUR, JPY, GBP, KRW, CNY, THB, SGD, AUD, CAD, TWD.

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
   - **Languages**: chọn cả Vietnamese + English
   - **Age Rating**: 4+
   - **Privacy**: app không thu thập dữ liệu → chọn "Data Not Collected"
5. Chờ duyệt (thường 1–24 giờ).

### Trước khi submit, kiểm tra lại

- [ ] Đổi `PRODUCT_BUNDLE_IDENTIFIER` thành ID riêng
- [ ] Chọn Development Team
- [ ] Bump `MARKETING_VERSION` (ví dụ `1.0.1`) và `CURRENT_PROJECT_VERSION` trong project settings
- [ ] Kiểm tra icon 1024×1024 trong `Assets.xcassets/AppIcon.appiconset`
- [ ] Cập nhật mô tả, ảnh chụp màn hình (bắt buộc: 6.7" và 5.5", cả 2 ngôn ngữ nếu bán đa ngôn ngữ)
- [ ] `PrivacyInfo.xcprivacy` đã có sẵn (không tracking, không thu thập data)

## Ngôn ngữ

Bản dịch nằm trong `ExpenseTracker/Localizable.xcstrings` (String Catalog của Xcode).

- Nguồn chân lý: `tools/generate_localization.py` — sửa dict `STRINGS` rồi chạy lại script.
- `sourceLanguage` là `en`; tiếng Việt nằm trong `localizations.vi`.
- `AppState.localizationBundle` tra cứu bundle `vi.lproj`/`en.lproj` để đổi ngôn ngữ lúc chạy.
- Danh mục dựng sẵn có `localizationKey` nên tên danh mục cũng đổi theo ngôn ngữ.

```bash
python tools/generate_localization.py   # sinh lại .xcstrings
python tools/check_localization_usage.py # kiểm tra L.xxx có tồn tại
```

## Cấu trúc dự án

```
ExpenseTracker/
├── App/
│   ├── ExpenseTrackerApp.swift      # Điểm vào, ModelContainer, locale + color scheme
│   ├── RootView.swift               # TabView gồm 4 tab
│   └── AppState.swift               # State dùng chung (tiền tệ, tháng, ngôn ngữ, giao diện)
├── Models/
│   ├── ExpenseTransaction.swift     # Giao dịch
│   ├── ExpenseCategory.swift        # Danh mục (có localizationKey)
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
│   ├── Theme.swift                  # Design token: màu tự đổi sáng/tối
│   ├── Components.swift             # Card, Badge, ProgressBar, SectionLabel
│   ├── Localization.swift           # Enum L + AppLanguage + AppAppearance
│   ├── MonthPicker.swift
│   ├── Color+Hex.swift              # Màu danh mục thích ứng sáng/tối
│   └── Calendar+Months.swift
├── Assets.xcassets/
├── Localizable.xcstrings            # Bản dịch EN/VI
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

# Kiểm tra cú pháp Swift cơ bản
python tools/check_swift_syntax.py

# Sinh lại bản dịch
python tools/generate_localization.py

# Sinh lại app icon
python tools/generate_app_icon.py
```

Cần Python 3.9+ (script sinh icon cần thêm `pip install pillow`).

## Định hướng mở rộng

- Đồng bộ đám mây qua CloudKit (SwiftData hỗ trợ sẵn, chỉ cần đổi `ModelConfiguration`)
- Widget hiển thị tổng chi ngày hôm nay
- App Watch
- Ngôn ngữ thứ ba (đã có sẵn khung `String Catalog`)
