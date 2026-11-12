# Hướng dẫn test app trên máy Mac

Tài liệu này dành cho bước **build lần đầu** và **kiểm thử tính năng** trước khi đưa lên App Store.

> Lưu ý: toàn bộ mã nguồn được viết và kiểm tra tĩnh trên Windows (không có Xcode),
> nên **lần build đầu tiên trên Mac là bước xác minh thật đầu tiên**. Nếu có lỗi compile,
> xem mục [Xử lý lỗi compile](#xử-lý-lỗi-compile).

## 1. Chuẩn bị

| Thứ | Yêu cầu |
|---|---|
| macOS | 13.0 trở lên (Ventura) |
| Xcode | 16.0 trở lên |
| iOS runtime | 17.0 trở lên (mặc định Xcode 16 đã có sẵn iOS 18 simulator) |
| Tài khoản | Apple ID (miễn phí) để chạy trên simulator — không cần tài khoản trả phí |
| Bundle ID | `com.ductran1302.expensetracker` — đổi nếu trùng |

### Cài Xcode

```
https://developer.apple.com/download/
```

Chọn "Download for Mac" → giải nén `.xiph` → double-click → cài vào `/Applications`.
Lần đầu mở, Xcode sẽ hỏi cài thêm Components (simulator runtime) — chọn **Install**.

## 2. Lấy code

```bash
cd ~/Desktop
git clone https://github.com/ductran1302/expense-appstore.git
cd expense-appstore
open ExpenseTracker.xcodeproj
```

## 3. Cấu hình signing (bắt buộc 1 lần)

Trong Xcode, chọn target **ExpenseTracker** (biểu tượng màu xanh bên trái) → tab **Signing & Capabilities**:

1. Mục **Signing**: chọn **Team** → nếu chưa có, chọn **Add an Account…** → đăng nhập Apple ID.
2. Tick **Automatically manage signing**.
3. Nếu báo *Provisioning profile errors* vì Bundle ID trùng:
   - Sửa **Bundle Identifier** thành ID của riêng bạn, ví dụ `com.yourname.chitieuthanh`.
   - Hoặc giữ nguyên và đổi Team sang tài khoản có sẵn ID đó.

> **Chạy trên simulator thì không cần signing thật.** Nếu chỉ muốn xem app chạy thì bỏ qua
> bước này, chọn simulator và nhấn ⌘R — Xcode sẽ tự ký bằng chứng thư tự tạo.

## 4. Chọn thiết bị và chạy

### Trên Simulator (nhanh nhất)

1. Toolbar trên cùng, chọn scheme **ExpenseTracker**.
2. Chọn thiết bị, ví dụ **iPhone 16 Pro**.
3. Nhấn **⌘R** (Run).

### Trên iPhone thật

1. Cắm iPhone, mở **Finder** → chọn iPhone → tab **General** → **Device Management** →
   tin cậy máy tính của bạn.
2. Trong Xcode: chọn thiết bị là iPhone của bạn → nhấn **⌘R**.
3. Trên iPhone: **Settings > General > VPN & Device Management** → tin cậy Developer.

## 5. Checklist kiểm thử

Chạy qua từng mục. Mọi mục đều dựa trên mã nguồn hiện tại.

### 5.1 Lần chạy đầu tiên

- [ ] App mở lên tab **Giao dịch**, tiêu đề hiển thị "Giao dịch"
- [ ] Danh mục dựng sẵn xuất hiện khi bấm nút **lọc** (icon tròn có 3 gạch ở góc trên trái):
  Ăn uống, Đi lại, Mua sắm, Hóa đơn, Sức khoẻ, Giải trí, Học tập, Nhà cửa, Quà tặng, Thu nhập, Khác
- [ ] Thẻ tổng quan hiển thị **0 ₫** và "Trung bình mỗi ngày" bằng 0
- [ ] Màn hình trống hiện empty state "Chưa có chi tiêu nào" + nút **Thêm giao dịch**

### 5.2 Thêm giao dịch

- [ ] Bấm **+** ở góc trên phải → form mở, **con trỏ tự nhập vào ô số tiền**
- [ ] Nhập `125000` → hiển thị `125.000` (dấu phân cách nghìn theo locale)
- [ ] Chọn loại **Chi tiêu** / **Thu nhập** bằng segmented control
- [ ] Chọn danh mục → đổi ngày → ghi chú → **Lưu**
- [ ] Giao dịch xuất hiện trong danh sách, tổng ở thẻ tổng quan cập nhật ngay
- [ ] Vuốt ngang trên giao dịch → hiện nút **Xoá** (màu đỏ)
- [ ] Chạm vào giao dịch → mở đúng form, sửa rồi Lưu → dữ liệu được cập nhật
- [ ] Nhấn **Huỷ** ở giữa (kéo xuống để dismiss) → không lưu

### 5.3 Tìm kiếm và lọc

- [ ] Kéo xuống → ô tìm kiếm hiện, gõ "cà phê" → lọc đúng giao dịch
- [ ] Chọn một danh mục trong menu lọc → chỉ hiện giao dịch của danh mục đó
- [ ] Bỏ lọc → danh sách đầy đủ trở lại
- [ ] Tìm không ra kết quả → hiện "Nothing matches" (khi chuyển sang English)

### 5.4 Tab Thống kê

- [ ] Chuyển tháng bằng mũi tên ← → → (mũi tên phải bị vô hiệu ở tháng hiện tại)
- [ ] Biểu đồ tròn hiện, **tổng chi nằm ở tâm vòng tròn**
- [ ] Segmented control đổi giữa "Theo danh mục" và "Theo ngày"
- [ ] Biểu đồ cột hiện theo từng ngày, trục Y có nhãn rút gọn (vd "1,2Tr")
- [ ] Dưới biểu đồ là danh sách phân tầng: chấm màu + tên + số tiền + % + thanh tiến trình
- [ ] Badge delta hiện % so với tháng trước (mũi tên lên = đỏ, xuống = xanh)

### 5.5 Tab Ngân sách

- [ ] Thẻ "Ngân sách tháng" hiện lời mời **Đặt hạn mức cho tháng** khi chưa có
- [ ] Bấm → mở form, nhập hạn mức (vd `2000000`) → Lưu
- [ ] Thanh tiến trình hiện, màu đổi theo mức dùng: xanh (<80%), vàng (80–100%), đỏ (>100%)
- [ ] Thêm hạn mức theo danh mục → hiện dưới dạng "Hạn mức theo danh mục"
- [ ] Bấm một hạn mức → mở form sửa
- [ ] **Vuốt phải / long-press** một hạn mức → context menu có **Xoá**
- [ ] Thêm hạn mức trùng tháng + danh mục → báo "Đã có hạn mức cho tháng và danh mục này" và nút Lưu bị khoá

### 5.6 Tab Cài đặt

- [ ] **Giao diện**: chọn Sáng → app đổi ngay; chọn Tối → đổi; chọn Hệ thống → theo máy
- [ ] **Ngôn ngữ**: chọn **English** → toàn bộ UI đổi sang tiếng Anh (giữ nguyên dữ liệu)
- [ ] Chọn lại **Tiếng Việt** → UI về tiếng Việt
- [ ] **Tiền tệ**: đổi sang USD → mọi số tiền hiển thị theo USD
- [ ] **Thêm dữ liệu mẫu** → xác nhận → có ~25 giao dịch trong 45 ngày qua, biểu đồ đầy dữ liệu
- [ ] **Sao lưu toàn bộ (JSON)** → hộp thoại lưu file xuất hiện → chọn nơi lưu → file `.json` tạo được
- [ ] **Xuất giao dịch (CSV)** → file `.csv` tạo được, mở bằng Numbers/Excel thấy cột đúng
- [ ] **Nhập từ JSON** → chọn file backup vừa xuất → thông báo "Đã nhập N giao dịch"
- [ ] Nhập lại cùng file đó → báo nhập 0 giao dịch (không nhân bản)
- [ ] **Xoá toàn bộ dữ liệu** → hộp thoại xác nhận hiện → Xoá tất cả → dữ liệu trống

### 5.7 Đa ngôn ngữ (quan trọng)

- [ ] **Mặc định là tiếng Việt** khi cài mới (không vào Setting đổi gì)
- [ ] Đổi sang English → tên danh mục dựng sẵn cũng đổi (Ăn uống → Food & drink)
- [ ] Số tiền format theo locale: `1.250.000 ₫` (VI) vs `₩1,250,000` (EN)
- [ ] Ngày tháng format theo locale: "Tháng 11 năm 2026" (VI) vs "November 2026" (EN)
- [ ] Số nhiều đúng: "1 giao dịch" / "2 giao dịch" (VI), "1 transaction" / "2 transactions" (EN)

### 5.8 Dark mode

- [ ] Bật Dark Mode của máy (Settings > Appearance) → app chuyển theo
- [ ] Màu danh mục vẫn đọc được, không bị chìm vào nền
- [ ] Chữ phụ (caption, secondary) vẫn tương phản tốt
- [ ] Thanh tiến trình vẫn nhìn rõ trên nền tối

### 5.9 Accessibility (không bắt buộc nhưng nên kiểm)

- [ ] Bật **VoiceOver** (Settings > Accessibility > VoiceOver) → mỗi giao dịch đọc đủ
      "Ăn uống, -125.000 ₫"
- [ ] Bật **Bold Text** và tăng cỡ chữ lớn (Settings > Accessibility > Display) → không bị cắt chữ
- [ ] Bật **Reduce Motion** (Settings > Accessibility > Motion) → chuyển tháng không còn animation

## 6. Test trên thiết bị thật (khác simulator)

Cần để kiểm tra hiệu năng, cảm ứng, và hành vi thật:

- [ ] Chạy trên iPhone thật — mượt khi cuộn danh sách dài
- [ ] Xoay ngang (nếu app hỗ trợ) — layout không vỡ
- [ ] Thêm nhiều giao dịch (100+) — danh sách vẫn cuộn mượt
- [ ] Tắt app rồi mở lại — dữ liệu còn nguyên (SwiftData đã lưu)

## 7. Test nhiều ngôn ngữ / nhiều thiết bị (bắt buộc trước khi submit)

Theo yêu cầu của Apple khi bán đa ngôn ngữ, cần ảnh chụp màn hình cho **từng ngôn ngữ**:

```bash
# Chụp màn hình simulator
xcrun simctl io booted screenshot ~/Desktop/shot.png

# Đổi sang dark mode rồi chụp tiếp
xcrun simctl ui booted appearance dark
xcrun simctl io booted screenshot ~/Desktop/shot-dark.png
```

| Cần chụp | Kích thước |
|---|---|
| iPhone (6.7") | 1290×2796 |
| iPhone (5.5") | 1242×2208 |
| iPad (13") | 2064×2752 (nếu bán trên iPad) |

Chụp **tối thiểu**: tab Giao dịch (có dữ liệu), tab Thống kê, tab Ngân sách, tab Cài đặt —
**mỗi ngôn ngữ × mỗi kích thước**. Bật dữ liệu mẫu trước khi chụp.

## 8. Xử lý lỗi compile

Nếu Xcode báo lỗi, copy **toàn bộ** thông báo lỗi (đỏ = error, vàng = warning) rồi gửi lại.
Một số lỗi có khả năng gặp và cách xử lý:

| Triệu chứng | Cách xử lý |
|---|---|
| `Cannot find 'X' in scope` | Kiểm tra tên file/case: `Theme.swift` vs `themes.swift`. Đường dẫn file phải khớp `path` trong `project.pbxproj`. |
| `Type 'X' has no member 'Y'` | Thường do file chưa được thêm vào target. Kiểm tra file có hiện trong Navigator bên trái và có tick xanh ở target. |
| `Ambiguous use of 'init'` | Thường do truyền nhầm `String` với `LocalizedStringKey`. Kiểm tra chỗ gọi `L.xxx`. |
| `Cannot find 'L' in scope` | File `Shared/Localization.swift` chưa được thêm vào target. |
| `Extra argument 'xxx' in call` | Signature đã đổi (vd `CSVExporter.makeCSV` nay cần `header:` và `otherCategory:`). |
| `Cannot convert value of type 'String?' to expected argument type 'LocalizedStringKey'` | Dùng `appState.string("key")` thay vì `L.key` khi hàm yêu cầu `String`. |
| Build chậm lần đầu | Bình thường — Xcode index toàn bộ SwiftData framework. |

### Nếu thêm/xoá file Swift sau này

```bash
python tools/generate_xcodeproj.py    # cập nhật lại project
```

Hoặc làm trực tiếp trong Xcode (chuẩn hơn): chuột phải vào group → **Add File…**

### Kiểm tra trước khi commit

```bash
python tools/validate_xcodeproj.py        # project hợp lệ
python tools/check_swift_syntax.py        # cú pháp cơ bản
python tools/check_localization_usage.py  # L.xxx tồn tại
python tools/generate_localization.py     # đồng bộ bản dịch
```

## 9. Đưa lên TestFlight trước khi submit App Store

TestFlight cho phép test trên thiết bị thật và mời người khác dùng thử:

1. Trong Xcode: **Product > Destination > Any iOS Device (arm64)** → **Product > Archive**.
2. Organizer → **Distribute App** → **App Store Connect** → đăng nhập → **Upload**.
3. Vào [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **My Apps** → app của bạn →
   **TestFlight** → chọn build → **Add Testers** (email của bạn).
4. Trên iPhone: cài **TestFlight** app → chấp nhận build.
5. Test trên thiết bị thật, rồi mới submit bản chính thức.

## 10. Checklist submit

- [ ] Build Release **không có lỗi** (⌘B với config Release)
- [ ] Chạy thử trên iPhone thật, cả sáng và tối
- [ ] Ảnh chụp màn hình đủ cho 2 ngôn ngữ × 2 kích thước
- [ ] Mô tả app bằng cả tiếng Việt lẫn tiếng Anh
- [ ] `PrivacyInfo.xcprivacy` đã có sẵn → trả lời "Data Not Collected"
- [ ] Kiểm tra `CFBundleLocalizations` có cả `vi` và `en`
- [ ] App Icon 1024×1024 không có alpha (đã kiểm tra: RGB, không trong suốt)
- [ ] Quay video màn hình (không bắt buộc nhưng tăng tỉ lệ duyệt)
