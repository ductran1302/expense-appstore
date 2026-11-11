import Foundation
import SwiftData

/// Danh mục chi tiêu (Ăn uống, Đi lại, ...). Mỗi giao dịch thuộc về tối đa một danh mục.
@Model
final class ExpenseCategory {
    /// Tên hiển thị, ví dụ "Ăn uống".
    var name: String
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
        symbol: String,
        colorHex: String,
        isBuiltIn: Bool = false,
        sortOrder: Int = 0
    ) {
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
    }
}
