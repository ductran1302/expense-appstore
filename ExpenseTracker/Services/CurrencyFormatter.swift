import Foundation

/// Một loại tiền được hỗ trợ.
struct CurrencyOption: Identifiable, Hashable {
    /// Mã tiền tệ ISO, ví dụ "VND".
    let code: String
    /// Tên hiển thị, ví dụ "Việt Nam Đồng (₫)".
    let name: String

    var id: String { code }
}

/// Định dạng tiền theo loại tiền tệ.
enum CurrencyFormatter {
    /// Các loại tiền hỗ trợ.
    static let supported: [CurrencyOption] = [
        CurrencyOption(code: "VND", name: "Việt Nam Đồng (₫)"),
        CurrencyOption(code: "USD", name: "US Dollar ($)"),
        CurrencyOption(code: "EUR", name: "Euro (€)"),
        CurrencyOption(code: "JPY", name: "Yên Nhật (¥)"),
        CurrencyOption(code: "GBP", name: "Bảng Anh (£)"),
        CurrencyOption(code: "KRW", name: "Won Hàn Quốc (₩)"),
        CurrencyOption(code: "CNY", name: "Nhân Dân Tệ (¥)"),
        CurrencyOption(code: "THB", name: "Bát Thái (฿)"),
        CurrencyOption(code: "SGD", name: "Đô la Singapore (S$)"),
        CurrencyOption(code: "AUD", name: "Đô la Úc (A$)"),
        CurrencyOption(code: "CAD", name: "Đô la Canada (C$)"),
        CurrencyOption(code: "TWD", name: "Đô la Đài (NT$)")
    ]

    /// Số chữ số thập phân tối đa theo loại tiền.
    private static func fractionDigits(for code: String) -> Int {
        switch code {
        case "VND", "JPY", "KRW":
            return 0
        default:
            return 2
        }
    }

    /// Định dạng số tiền thành chuỗi hiển thị, ví dụ "1.250.000 ₫".
    static func string(_ amount: Decimal, code: String, locale: Locale = .autoupdatingCurrent) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = locale
        formatter.maximumFractionDigits = fractionDigits(for: code)
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
    }

    /// Định dạng rút gọn cho trục biểu đồ, ví dụ "1,2Tr".
    static func compact(_ amount: Double, code: String, locale: Locale = .autoupdatingCurrent) -> String {
        let symbol = symbol(for: code)
        let absolute = abs(amount)
        let value: Double
        let suffix: String

        if code == "VND" {
            if absolute >= 1_000_000 {
                value = amount / 1_000_000
                suffix = "Tr"
            } else if absolute >= 1_000 {
                value = amount / 1_000
                suffix = "K"
            } else {
                value = amount
                suffix = ""
            }
        } else if absolute >= 1_000_000_000 {
            value = amount / 1_000_000_000
            suffix = "T"
        } else if absolute >= 1_000_000 {
            value = amount / 1_000_000
            suffix = "Tr"
        } else if absolute >= 1_000 {
            value = amount / 1_000
            suffix = "K"
        } else {
            value = amount
            suffix = ""
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.maximumFractionDigits = abs(value) >= 100 ? 0 : 1
        formatter.minimumFractionDigits = 0

        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return suffix.isEmpty ? "\(number)\(symbol)" : "\(number)\(suffix)"
    }

    /// Ký hiệu tiền tệ.
    static func symbol(for code: String) -> String {
        switch code {
        case "VND": return "₫"
        case "USD": return "$"
        case "EUR": return "€"
        case "JPY": return "¥"
        case "GBP": return "£"
        case "KRW": return "₩"
        case "CNY": return "¥"
        case "THB": return "฿"
        case "SGD": return "S$"
        case "AUD": return "A$"
        case "CAD": return "C$"
        case "TWD": return "NT$"
        default: return code
        }
    }

    /// Chuỗi số thuần để nhập trong ô text (không có ký hiệu, không phân tách nghìn).
    static func editString(
        _ amount: Decimal,
        code: String = "VND",
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = fractionDigits(for: code)
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
    }
}
