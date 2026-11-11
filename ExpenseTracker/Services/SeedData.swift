import Foundation
import SwiftData

/// Dữ liệu mẫu được tạo tự động khi người dùng mở app lần đầu.
enum SeedData {
    /// Danh mục mặc định.
    static let defaultCategories: [(name: String, symbol: String, color: String)] = [
        ("Ăn uống", "fork.knife", "#FF6B35"),
        ("Đi lại", "car.fill", "#4ECDC4"),
        ("Mua sắm", "bag.fill", "#FFD166"),
        ("Hóa đơn", "bolt.fill", "#A06CD5"),
        ("Sức khoẻ", "heart.fill", "#EF476F"),
        ("Giải trí", "gamecontroller.fill", "#06D6A0"),
        ("Học tập", "book.fill", "#118AB2"),
        ("Nhà cửa", "house.fill", "#8D99AE"),
        ("Quà tặng", "gift.fill", "#F4978E"),
        ("Thu nhập", "arrow.down.circle.fill", "#2A9D8F"),
        ("Khác", "questionmark.circle.fill", "#6C757D")
    ]

    /// Tạo danh mục mặc định nếu chưa có danh mục nào.
    @discardableResult
    static func createDefaultCategories(in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<ExpenseCategory>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return false }

        for (index, item) in defaultCategories.enumerated() {
            let category = ExpenseCategory(
                name: item.name,
                symbol: item.symbol,
                colorHex: item.color,
                isBuiltIn: true,
                sortOrder: index
            )
            context.insert(category)
        }
        try? context.save()
        return true
    }

    /// Tạo một bộ giao dịch mẫu trong 45 ngày gần nhất, dùng để xem thử biểu đồ.
    @discardableResult
    static func createSampleTransactions(in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<ExpenseCategory>(sortBy: [SortDescriptor(\ExpenseCategory.sortOrder)])
        let categories = (try? context.fetch(descriptor)) ?? []
        guard !categories.isEmpty else { return false }

        func category(_ name: String) -> ExpenseCategory? {
            categories.first { $0.name == name }
        }

        let now = Date.now
        let calendar = Calendar.app
        var samples: [(category: String, amount: Decimal, note: String, dayOffset: Int)] = [
            ("Ăn uống", 45_000, "Cà phê sáng", 0),
            ("Ăn uống", 120_000, "Cơm trưa với đồng nghiệp", 0),
            ("Đi lại", 30_000, "Grab về nhà", 0),
            ("Ăn uống", 85_000, "Tối ăn lẩu", 1),
            ("Mua sắm", 450_000, "Giày thể thao", 2),
            ("Hóa đơn", 320_000, "Điện tháng này", 3),
            ("Sức khoẻ", 200_000, "Khám sức khoẻ tổng quát", 4),
            ("Ăn uống", 55_000, "Bánh mì ăn sáng", 5),
            ("Giải trí", 180_000, "Xem phim", 6),
            ("Học tập", 650_000, "Sách lập trình", 7),
            ("Đi lại", 60_000, "Xăng xe", 8),
            ("Ăn uống", 210_000, "Mua đồ ăn cuối tuần", 9),
            ("Nhà cửa", 780_000, "Hóa đơn nước", 11),
            ("Ăn uống", 38_000, "Trà sữa", 12),
            ("Mua sắm", 1_200_000, "Áo khoác mùa đông", 14),
            ("Giải trí", 250_000, "Gaming", 16),
            ("Ăn uống", 96_000, "Bữa cơm gia đình", 18),
            ("Đi lại", 45_000, "Taxi sân bay", 21),
            ("Ăn uống", 150_000, "Tiệc cà phê", 24),
            ("Hóa đơn", 240_000, "Internet", 26),
            ("Ăn uống", 72_000, "Bữa sáng cuối tuần", 29),
            ("Mua sắm", 320_000, "Tai nghe", 33),
            ("Sức khoẻ", 480_000, "Gym 3 tháng", 36),
            ("Học tập", 350_000, "Khoá học online", 40),
            ("Ăn uống", 110_000, "Bữa lẩu gia đình", 43)
        ]

        for sample in samples {
            guard let target = category(sample.category) else { continue }
            let date = calendar.date(byAdding: .day, value: -sample.dayOffset, to: now) ?? now
            let transaction = ExpenseTransaction(
                amount: sample.amount,
                note: sample.note,
                date: date,
                category: target
            )
            context.insert(transaction)
        }

        try? context.save()
        return true
    }
}
