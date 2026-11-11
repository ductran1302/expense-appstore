import Foundation
import SwiftData

/// Một khoản chi (hoặc thu nếu `amount` âm).
@Model
final class ExpenseTransaction {
    /// Số tiền. Dùng `Decimal` để không sai số tiền tuyệt đối.
    var amount: Decimal
    /// Ghi chú tuỳ chọn.
    var note: String
    /// Ngày phát sinh giao dịch.
    var date: Date
    /// Danh mục, có thể nil nếu người dùng xoá danh mục.
    var category: ExpenseCategory? = nil

    init(amount: Decimal, note: String = "", date: Date = .now, category: ExpenseCategory? = nil) {
        self.amount = amount
        self.note = note
        self.date = date
        self.category = category
    }
}
