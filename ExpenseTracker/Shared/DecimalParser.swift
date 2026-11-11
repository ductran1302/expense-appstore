import Foundation

enum DecimalParser {
    /// Chuyển chuỗi người dùng nhập (có thể chứa dấu phân cách) thành `Decimal`.
    ///
    /// Hỗ trợ: "1234", "1234.5", "1.234,56", "1,234.56", "12 000".
    static func parse(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var cleaned = trimmed
        cleaned = cleaned.replacingOccurrences(of: " ", with: "")
        cleaned = cleaned.replacingOccurrences(of: "\u{00A0}", with: "")

        // Chỉ giữ lại chữ số và các dấu phân cách.
        cleaned = String(cleaned.filter { $0.isNumber || $0 == "." || $0 == "," })

        guard !cleaned.isEmpty else { return nil }

        let dotIndex = cleaned.lastIndex(of: ".")
        let commaIndex = cleaned.lastIndex(of: ",")

        switch (dotIndex, commaIndex) {
        case let (dot?, comma?):
            // Dấu xuất hiện sau cùng là dấu thập phân, dấu còn lại là phân tách nghìn.
            if comma > dot {
                cleaned = cleaned.replacingOccurrences(of: ".", with: "")
                cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
            } else {
                cleaned = cleaned.replacingOccurrences(of: ",", with: "")
            }
        case let (dot?, nil):
            // "1.234" có thể là phân tách nghìn nếu có đúng 3 chữ số phía sau dấu chấm.
            let decimals = cleaned.distance(from: cleaned.index(after: dot), to: cleaned.endIndex)
            if decimals == 3 && cleaned.filter { $0 == "." }.count == 1 {
                cleaned = cleaned.replacingOccurrences(of: ".", with: "")
            }
        case let (nil, comma?):
            let decimals = cleaned.distance(from: cleaned.index(after: comma), to: cleaned.endIndex)
            if decimals == 3 && cleaned.filter { $0 == "," }.count == 1 {
                cleaned = cleaned.replacingOccurrences(of: ",", with: "")
            } else {
                cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
            }
        case (nil, nil):
            break
        }

        // Bỏ dấu phân cách thừa ở cuối (ví dụ "12." -> "12").
        if cleaned.hasSuffix("."), cleaned.count > 1 {
            cleaned.removeLast()
        }

        return Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX"))
    }
}
