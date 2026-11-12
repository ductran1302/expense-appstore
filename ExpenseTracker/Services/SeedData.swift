import Foundation
import SwiftData

/// Dữ liệu mẫu được tạo tự động khi người dùng mở app lần đầu.
enum SeedData {
    /// Danh mục mặc định.
    ///
    /// `key` là khoá bản dịch trong String Catalog, nên tên hiển thị đổi theo
    /// ngôn ngữ người dùng chọn.
    static let defaultCategories: [(key: String, name: String, symbol: String, color: String)] = [
        ("category.food", "Ăn uống", "fork.knife", "#FF6B35"),
        ("category.transport", "Đi lại", "car.fill", "#4ECDC4"),
        ("category.shopping", "Mua sắm", "bag.fill", "#FFD166"),
        ("category.bills", "Hóa đơn", "bolt.fill", "#A06CD5"),
        ("category.health", "Sức khoẻ", "heart.fill", "#EF476F"),
        ("category.entertainment", "Giải trí", "gamecontroller.fill", "#06D6A0"),
        ("category.education", "Học tập", "book.fill", "#118AB2"),
        ("category.home", "Nhà cửa", "house.fill", "#8D99AE"),
        ("category.gifts", "Quà tặng", "gift.fill", "#F4978E"),
        ("category.income", "Thu nhập", "arrow.down.circle.fill", "#2A9D8F"),
        ("category.other", "Khác", "questionmark.circle.fill", "#6C757D")
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
                localizationKey: item.key,
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

    /// Gán khoá bản dịch cho danh mục dựng sẵn đã tồn tại từ phiên bản cũ.
    ///
    /// Khi thêm cột `localizationKey` vào model, SwiftData chỉ thêm cột NULL cho
    /// dữ liệu cũ. Nếu không gán lại khoá, các danh mục dựng sẵn sẽ không còn
    /// đổi ngôn ngữ và khoá hạn mức cũ sẽ không khớp với khoá mới.
    static func backfillLocalizationKeys(in context: ModelContext) {
        let descriptor = FetchDescriptor<ExpenseCategory>()
        guard let all = try? context.fetch(descriptor) else { return }

        let keyByName = Dictionary(
            defaultCategories.map { ($0.name, $0.key) },
            uniquingKeysWith: { first, _ in first }
        )

        var changed = false
        for category in all where category.localizationKey == nil {
            if let key = keyByName[category.name] {
                category.localizationKey = key
                changed = true
            }
        }

        if changed {
            try? context.save()
        }
    }

    /// Tạo một bộ giao dịch mẫu trong 45 ngày gần nhất, dùng để xem thử biểu đồ.
    @discardableResult
    static func createSampleTransactions(in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<ExpenseCategory>(sortBy: [SortDescriptor(\ExpenseCategory.sortOrder)])
        let categories = (try? context.fetch(descriptor)) ?? []
        guard !categories.isEmpty else { return false }

        func category(_ key: String) -> ExpenseCategory? {
            categories.first { $0.localizationKey == key }
        }

        let now = Date.now
        let calendar = Calendar.app
        var samples: [(key: String, amount: Decimal, note: String, dayOffset: Int)] = [
            ("category.food", 45_000, "Cà phê sáng", 0),
            ("category.food", 120_000, "Cơm trưa với đồng nghiệp", 0),
            ("category.transport", 30_000, "Grab về nhà", 0),
            ("category.food", 85_000, "Tối ăn lẩu", 1),
            ("category.shopping", 450_000, "Giày thể thao", 2),
            ("category.bills", 320_000, "Điện tháng này", 3),
            ("category.health", 200_000, "Khám sức khoẻ tổng quát", 4),
            ("category.food", 55_000, "Bánh mì ăn sáng", 5),
            ("category.entertainment", 180_000, "Xem phim", 6),
            ("category.education", 650_000, "Sách lập trình", 7),
            ("category.transport", 60_000, "Xăng xe", 8),
            ("category.food", 210_000, "Mua đồ ăn cuối tuần", 9),
            ("category.home", 780_000, "Hóa đơn nước", 11),
            ("category.food", 38_000, "Trà sữa", 12),
            ("category.shopping", 1_200_000, "Áo khoác mùa đông", 14),
            ("category.entertainment", 250_000, "Gaming", 16),
            ("category.food", 96_000, "Bữa cơm gia đình", 18),
            ("category.transport", 45_000, "Taxi sân bay", 21),
            ("category.food", 150_000, "Tiệc cà phê", 24),
            ("category.bills", 240_000, "Internet", 26),
            ("category.food", 72_000, "Bữa sáng cuối tuần", 29),
            ("category.shopping", 320_000, "Tai nghe", 33),
            ("category.health", 480_000, "Gym 3 tháng", 36),
            ("category.education", 350_000, "Khoá học online", 40),
            ("category.food", 110_000, "Bữa lẩu gia đình", 43)
        ]

        for sample in samples {
            guard let target = category(sample.key) else { continue }
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
