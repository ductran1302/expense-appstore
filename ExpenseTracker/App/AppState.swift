import Foundation
import Observation
import SwiftUI

/// Trạng thái dùng chung cho toàn app.
@Observable
final class AppState {
    /// Mã tiền tệ đang dùng.
    var currencyCode: String

    /// Tháng đang chọn (luôn là ngày 1 của tháng).
    var selectedMonth: Date

    /// Ngôn ngữ hiển thị. Mặc định là tiếng Việt.
    var language: AppLanguage

    /// Giao diện sáng/tối.
    var appearance: AppAppearance

    private enum Keys {
        static let currencyCode = "settings.currencyCode"
        static let selectedMonth = "settings.selectedMonth"
        static let language = "settings.language"
        static let appearance = "settings.appearance"
    }

    init() {
        let defaults = UserDefaults.standard

        let storedCode = defaults.string(forKey: Keys.currencyCode) ?? "VND"
        self.currencyCode = CurrencyFormatter.supported.contains(where: { $0.code == storedCode })
            ? storedCode
            : "VND"

        let storedMonth = defaults.double(forKey: Keys.selectedMonth)
        if storedMonth > 0 {
            self.selectedMonth = Date(timeIntervalSince1970: storedMonth).startOfMonth
        } else {
            self.selectedMonth = Date.now.startOfMonth
        }

        let storedLanguage = defaults.string(forKey: Keys.language) ?? ""
        self.language = AppLanguage(rawValue: storedLanguage) ?? .vietnamese

        let storedAppearance = defaults.string(forKey: Keys.appearance) ?? ""
        self.appearance = AppAppearance(rawValue: storedAppearance) ?? .system
    }

    // MARK: - Mutations

    /// Đổi loại tiền và lưu lại.
    func updateCurrency(_ code: String) {
        guard code != currencyCode else { return }
        currencyCode = code
        UserDefaults.standard.set(code, forKey: Keys.currencyCode)
    }

    /// Đổi tháng đang xem và lưu lại.
    func updateMonth(_ month: Date) {
        let normalized = month.startOfMonth
        guard normalized != selectedMonth else { return }
        selectedMonth = normalized
        UserDefaults.standard.set(normalized.timeIntervalSince1970, forKey: Keys.selectedMonth)
    }

    /// Đổi ngôn ngữ và lưu lại.
    func updateLanguage(_ language: AppLanguage) {
        guard language != self.language else { return }
        self.language = language
        UserDefaults.standard.set(language.rawValue, forKey: Keys.language)
    }

    /// Đổi giao diện và lưu lại.
    func updateAppearance(_ appearance: AppAppearance) {
        guard appearance != self.appearance else { return }
        self.appearance = appearance
        UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance)
    }

    // MARK: - Derived

    /// Locale dùng cho định dạng số và ngày.
    var locale: Locale {
        language.locale
    }

    /// Bundle của ngôn ngữ đang chọn, dùng cho `NSLocalizedString`.
    ///
    /// `NSLocalizedString` mặc định theo ngôn ngữ hệ thống, nên khi người dùng
    /// đổi ngôn ngữ trong app phải tra cứu bundle tương ứng.
    var localizationBundle: Bundle {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    /// Chuỗi đã dịch theo ngôn ngữ đang chọn.
    func string(_ key: String) -> String {
        localizationBundle.localizedString(forKey: key, value: key, table: nil)
    }

    /// Chuỗi đã dịch có tham số, ví dụ `string("stats.up", arguments: "12%")`.
    ///
    /// Tham số số nên truyền qua `NSNumber` để `%d` luôn khớp đúng độ rộng.
    func string(_ key: String, arguments: CVarArg...) -> String {
        let template = localizationBundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: template, locale: locale, arguments: arguments)
    }

    /// Chuỗi đã dịch có tham số là số.
    func string(_ key: String, count: Int) -> String {
        let template = localizationBundle.localizedString(forKey: key, value: key, table: nil)
        return String(
            format: template,
            locale: locale,
            arguments: [NSNumber(value: count)]
        )
    }

    /// Tên tháng theo ngôn ngữ đang chọn, ví dụ "Tháng 11 năm 2026" / "November 2026".
    func monthTitle(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).month(.wide).year())
    }

    /// Ngày đầy đủ theo ngôn ngữ đang chọn, ví dụ "Thứ Bảy, 5 tháng 11".
    func dayTitle(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: locale).weekday(.wide).day().month())
    }

    /// Số tiền theo loại tiền và ngôn ngữ đang chọn.
    func format(_ amount: Decimal) -> String {
        CurrencyFormatter.string(amount, code: currencyCode, locale: locale)
    }

    /// Tên danh mục theo ngôn ngữ đang chọn.
    func categoryName(_ category: ExpenseCategory) -> String {
        category.displayName(bundle: localizationBundle)
    }

    /// Số tiền rút gọn (dùng cho trục biểu đồ).
    func compact(_ amount: Double) -> String {
        CurrencyFormatter.compact(amount, code: currencyCode, locale: locale)
    }

    // MARK: - Bindings

    /// Binding cho ô chọn tháng.
    var monthBinding: Binding<Date> {
        Binding(
            get: { self.selectedMonth },
            set: { self.updateMonth($0) }
        )
    }

    /// Binding cho ô chọn tiền tệ.
    var currencyBinding: Binding<String> {
        Binding(
            get: { self.currencyCode },
            set: { self.updateCurrency($0) }
        )
    }

    /// Binding cho ô chọn ngôn ngữ.
    var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { self.language },
            set: { self.updateLanguage($0) }
        )
    }

    /// Binding cho ô chọn giao diện.
    var appearanceBinding: Binding<AppAppearance> {
        Binding(
            get: { self.appearance },
            set: { self.updateAppearance($0) }
        )
    }

    /// Tháng trước đó.
    var previousMonth: Date {
        selectedMonth.addingMonths(-1)
    }

    /// Tháng sau đó.
    var nextMonth: Date {
        selectedMonth.addingMonths(1)
    }
}
