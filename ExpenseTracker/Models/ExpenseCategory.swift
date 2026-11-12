import Foundation
import SwiftData

/// Danh mục chi tiêu (Ăn uống, Đi lại, ...). Mỗi giao dịch thuộc về tối đa một danh mục.
@Model
final class ExpenseCategory {
    /// Tên hiển thị. Với danh mục dựng sẵn, tên này là bản dịch tiếng Việt
    /// (dùng làm giá trị dự phòng khi không tra được bản dịch).
    var name: String
    /// Khoá bản dịch cho danh mục dựng sẵn (ví dụ "category.food").
    /// Danh mục do người dùng tạo có `nil` và luôn hiển thị `name`.
    var localizationKey: String?
    /// Tên SF Symbol dùng làm biểu tượng, ví dụ "fork.knife".
    var symbol: String
    /// Mã màu hex, ví dụ "#FF6B35".
    var colorHex: String
    /// Danh mục mặc định được tạo sẵn, người dùng không nên xoá (sẽ được chuyển "Khác").
    var isBuiltIn: Bool
    /// Thứ tự hiển thị trong danh sách.
    var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \ExpenseTransaction.category)
    var transactions: [ExpenseTransaction] = []

    @Relationship(deleteRule: .nullify, inverse: \MonthlyBudget.category)
    var budgets: [MonthlyBudget] = []

    init(
        name: String,
        localizationKey: String? = nil,
        symbol: String,
        colorHex: String,
        isBuiltIn: Bool = false,
        sortOrder: Int = 0
    ) {
        self.name = name
        self.localizationKey = localizationKey
        self.symbol = symbol
        self.colorHex = colorHex
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
    }
}

extension ExpenseCategory {
    /// Khoá định danh ổn định của danh mục, dùng cho so sánh và hạn mức.
    ///
    /// Dùng `localizationKey` cho danh mục dựng sẵn để không đổi khi đổi ngôn ngữ.
    var stableKey: String {
        localizationKey ?? "custom:\(name)"
    }

    /// Tên hiển thị theo ngôn ngữ đang chọn.
    func displayName(bundle: Bundle) -> String {
        guard let localizationKey else { return name }
        let translated = bundle.localizedString(forKey: localizationKey, value: name, table: nil)
        return translated == localizationKey ? name : translated
    }
}
