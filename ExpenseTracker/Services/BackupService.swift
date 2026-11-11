import Foundation
import SwiftData
import UniformTypeIdentifiers

/// Định dạng sao lưu (JSON) của toàn bộ dữ liệu app.
struct ExpenseArchive: Codable {
    /// Định danh định dạng, dùng để kiểm tra khi import.
    let format: String
    /// Phiên bản định dạng.
    let version: Int
    /// Thời điểm xuất file.
    let exportedAt: Date
    /// Danh mục.
    let categories: [CategoryPayload]
    /// Giao dịch.
    let transactions: [TransactionPayload]
    /// Hạn mức.
    let budgets: [BudgetPayload]

    struct CategoryPayload: Codable {
        let name: String
        let symbol: String
        let colorHex: String
        let sortOrder: Int
    }

    struct TransactionPayload: Codable {
        /// Số tiền dạng chuỗi để không mất chính xác.
        let amount: String
        let note: String
        let date: Date
        /// Tên danh mục, nil nếu không có danh mục.
        let categoryName: String?
    }

    struct BudgetPayload: Codable {
        /// Tháng theo định dạng "yyyy-MM".
        let month: String
        let limit: String
        let categoryName: String?
    }

    static let currentFormat = "expense-tracker-archive"
    static let currentVersion = 1

    /// Tạo archive từ dữ liệu hiện có.
    static func make(
        categories: [ExpenseCategory],
        transactions: [ExpenseTransaction],
        budgets: [MonthlyBudget]
    ) -> ExpenseArchive {
        ExpenseArchive(
            format: currentFormat,
            version: currentVersion,
            exportedAt: .now,
            categories: categories.map {
                CategoryPayload(
                    name: $0.name,
                    symbol: $0.symbol,
                    colorHex: $0.colorHex,
                    sortOrder: $0.sortOrder
                )
            },
            transactions: transactions.map {
                TransactionPayload(
                    amount: NSDecimalNumber(decimal: $0.amount).stringValue,
                    note: $0.note,
                    date: $0.date,
                    categoryName: $0.category?.name
                )
            },
            budgets: budgets.map {
                BudgetPayload(
                    month: $0.monthStart.monthKey,
                    limit: NSDecimalNumber(decimal: $0.limit).stringValue,
                    categoryName: $0.category?.name
                )
            }
        )
    }

    /// Mã hoá ra JSON cho file xuất.
    func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    /// Giải mã JSON từ file nhập.
    static func decode(data: Data) throws -> ExpenseArchive {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExpenseArchive.self, from: data)
    }
}

/// Chuyển dữ liệu ra CSV để mở bằng Excel/Numbers.
enum CSVExporter {
    /// Tạo nội dung CSV cho danh sách giao dịch.
    static func makeCSV(transactions: [ExpenseTransaction]) -> String {
        var lines = ["Ngày,Danh mục,Ghi chú,Số tiền"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        for transaction in transactions.sorted(by: { $0.date > $1.date }) {
            let date = formatter.string(from: transaction.date)
            let category = transaction.category?.name ?? "Khác"
            let note = escape(transaction.note)
            let amount = NSDecimalNumber(decimal: transaction.amount).stringValue
            lines.append("\(date),\(escape(category)),\(note),\(amount)")
        }
        return lines.joined(separator: "\n")
    }

    private static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

/// Kết quả import.
struct ImportResult {
    var categoriesAdded = 0
    var transactionsAdded = 0
    var budgetsAdded = 0

    var summary: String {
        "Đã thêm \(categoriesAdded) danh mục, \(transactionsAdded) giao dịch và \(budgetsAdded) hạn mức."
    }
}

/// Nhập dữ liệu từ file archive vào database.
enum ArchiveImporter {
    /// Nhập archive, bỏ qua trùng lặp, trả về số lượng đã thêm.
    static func importArchive(
        _ archive: ExpenseArchive,
        into context: ModelContext
    ) -> ImportResult {
        var result = ImportResult()

        // Danh mục: dùng theo tên, đã có thì cập nhật biểu tượng/màu.
        let existingCategories = (try? context.fetch(FetchDescriptor<ExpenseCategory>())) ?? []
        var categoryMap: [String: ExpenseCategory] = [:]
        for category in existingCategories {
            categoryMap[category.name] = category
        }

        for payload in archive.categories {
            if let existing = categoryMap[payload.name] {
                existing.symbol = payload.symbol
                existing.colorHex = payload.colorHex
                existing.sortOrder = payload.sortOrder
                continue
            }
            let category = ExpenseCategory(
                name: payload.name,
                symbol: payload.symbol,
                colorHex: payload.colorHex,
                isBuiltIn: false,
                sortOrder: payload.sortOrder
            )
            context.insert(category)
            categoryMap[payload.name] = category
            result.categoriesAdded += 1
        }

        // Giao dịch: bỏ qua nếu đã tồn tại (cùng ngày, số tiền, ghi chú, danh mục).
        let existingTransactions = (try? context.fetch(FetchDescriptor<ExpenseTransaction>())) ?? []
        var transactionSignatures = Set(existingTransactions.map { signature(for: $0) })

        for payload in archive.transactions {
            guard let amount = Decimal(string: payload.amount, locale: Locale(identifier: "en_US_POSIX")) else {
                continue
            }
            let transaction = ExpenseTransaction(
                amount: amount,
                note: payload.note,
                date: payload.date,
                category: payload.categoryName.flatMap { categoryMap[$0] }
            )
            let signature = signature(for: transaction)
            guard !transactionSignatures.contains(signature) else { continue }
            transactionSignatures.insert(signature)
            context.insert(transaction)
            result.transactionsAdded += 1
        }

        // Hạn mức: dùng khoá tháng + danh mục.
        let existingBudgets = (try? context.fetch(FetchDescriptor<MonthlyBudget>())) ?? []
        var budgetKeys = Set(existingBudgets.map { $0.key })

        for payload in archive.budgets {
            guard let limit = Decimal(string: payload.limit, locale: Locale(identifier: "en_US_POSIX")) else {
                continue
            }
            guard let monthDate = monthStart(from: payload.month) else { continue }
            let category = payload.categoryName.flatMap { categoryMap[$0] }
            let budget = MonthlyBudget(monthStart: monthDate, limit: limit, category: category)
            guard !budgetKeys.contains(budget.key) else { continue }
            budgetKeys.insert(budget.key)
            context.insert(budget)
            result.budgetsAdded += 1
        }

        try? context.save()
        return result
    }

    private static func signature(for transaction: ExpenseTransaction) -> String {
        let amount = NSDecimalNumber(decimal: transaction.amount).stringValue
        return "\(transaction.date.dayKey)|\(amount)|\(transaction.note)|\(transaction.category?.name ?? "")"
    }

    private static func monthStart(from key: String) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]) else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        return Calendar.app.date(from: components)
    }
}
