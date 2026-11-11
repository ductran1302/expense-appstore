import Foundation
import SwiftData

/// Hạn mức chi tiêu theo tháng.
///
/// - `category == nil`: hạn mức tổng cho cả tháng.
/// - `category != nil`: hạn mức riêng cho một danh mục trong tháng đó.
@Model
final class MonthlyBudget {
    /// Đầu tháng (ngày 1) mà hạn mức này áp dụng. Luôn chuẩn hoá về 00:00 ngày 1.
    var monthStart: Date
    /// Hạn mức tối đa.
    var limit: Decimal
    /// Danh mục áp dụng, nil = toàn bộ tháng.
    var category: ExpenseCategory? = nil

    init(monthStart: Date, limit: Decimal, category: ExpenseCategory? = nil) {
        self.monthStart = monthStart.startOfMonth
        self.limit = limit
        self.category = category
    }
}

// MARK: - Khoá hạn mức

/// Phần mở rộng để tránh computed property bên trong thân `@Model`
/// (macro có thể báo lỗi tham chiếu vòng khi đọc quan hệ).
extension MonthlyBudget {
    /// Khoá duy nhất của hạn mức: tháng + danh mục (nil = tổng).
    var key: String {
        MonthlyBudget.makeKey(month: monthStart, categoryName: category?.name)
    }

    /// Dựng khoá hạn mức mà không cần tạo model.
    static func makeKey(month: Date, categoryName: String?) -> String {
        "\(month.monthKey)|\(categoryName ?? "all")"
    }
}
