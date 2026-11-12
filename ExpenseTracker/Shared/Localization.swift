import Foundation
import SwiftUI

/// Ngôn ngữ hiển thị của app.
enum AppLanguage: String, CaseIterable, Identifiable {
    case vietnamese = "vi"
    case english = "en"

    var id: String { rawValue }

    /// Tên hiển thị — luôn viết bằng chính ngôn ngữ đó.
    var displayName: String {
        switch self {
        case .vietnamese: return "Tiếng Việt"
        case .english: return "English"
        }
    }

    /// Locale dùng cho format số/ngày.
    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

/// Giao diện sáng/tối.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .system: return "settings.appearance.system"
        case .light: return "settings.appearance.light"
        case .dark: return "settings.appearance.dark"
        }
    }

    /// `nil` = theo hệ thống.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Khoá dịch nhanh.
///
/// Dùng `LocalizedStringKey` để SwiftUI tự tra cứu theo ngôn ngữ đang chọn
/// (thiết lập qua `.environment(\.locale, ...)` ở gốc app), không cần gọi
/// `NSLocalizedString` thủ công ở từng chỗ.
///
/// Với chuỗi có tham số hoặc số nhiều, dùng `AppState.string(_:arguments:)`
/// để tra cứu qua bundle của ngôn ngữ đã chọn.
enum L {
    // MARK: - Tabs

    static var tabTransactions: LocalizedStringKey { "tab.transactions" }
    static var tabStats: LocalizedStringKey { "tab.stats" }
    static var tabBudget: LocalizedStringKey { "tab.budget" }
    static var tabSettings: LocalizedStringKey { "tab.settings" }

    // MARK: - Common

    static var save: LocalizedStringKey { "common.save" }
    static var cancel: LocalizedStringKey { "common.cancel" }
    static var done: LocalizedStringKey { "common.done" }
    static var delete: LocalizedStringKey { "common.delete" }
    static var add: LocalizedStringKey { "common.add" }

    // MARK: - Transactions

    static var transactionsTitle: LocalizedStringKey { "transactions.title" }
    static var totalSpent: LocalizedStringKey { "transactions.totalSpent" }
    static var dailyAverage: LocalizedStringKey { "transactions.dailyAverage" }
    static var searchPrompt: LocalizedStringKey { "transactions.searchPrompt" }
    static var filterAll: LocalizedStringKey { "transactions.filterAll" }
    static var filterCategory: LocalizedStringKey { "transactions.filterCategory" }
    static var emptyTitle: LocalizedStringKey { "transactions.empty.title" }
    static var emptyMessage: LocalizedStringKey { "transactions.empty.message" }
    static var emptyAction: LocalizedStringKey { "transactions.empty.action" }
    static var emptySearchTitle: LocalizedStringKey { "transactions.empty.search" }
    static var emptySearchMessage: LocalizedStringKey { "transactions.empty.searchMessage" }
    static var deleteTitle: LocalizedStringKey { "transactions.delete.title" }
    static var deleteMessage: LocalizedStringKey { "transactions.delete.message" }
    static var addTitle: LocalizedStringKey { "transactions.add.title" }
    static var editTitle: LocalizedStringKey { "transactions.edit.title" }
    static var typeExpense: LocalizedStringKey { "transactions.type.expense" }
    static var typeIncome: LocalizedStringKey { "transactions.type.income" }
    static var amount: LocalizedStringKey { "transactions.amount" }
    static var amountPlaceholder: LocalizedStringKey { "transactions.amountPlaceholder" }
    static var category: LocalizedStringKey { "transactions.category" }
    static var details: LocalizedStringKey { "transactions.details" }
    static var noCategory: LocalizedStringKey { "transactions.noCategory" }
    static var date: LocalizedStringKey { "transactions.date" }
    static var note: LocalizedStringKey { "transactions.note" }
    static var notePlaceholder: LocalizedStringKey { "transactions.notePlaceholder" }

    // MARK: - Stats

    static var statsTitle: LocalizedStringKey { "stats.title" }
    static var chartByCategory: LocalizedStringKey { "stats.chart.byCategory" }
    static var chartByDay: LocalizedStringKey { "stats.chart.byDay" }
    static var statsEmpty: LocalizedStringKey { "stats.empty" }
    static var statsEmptyHint: LocalizedStringKey { "stats.empty.hint" }
    static var statsTotal: LocalizedStringKey { "stats.total" }
    static var statsSpent: LocalizedStringKey { "stats.spent" }
    static var vsLastMonth: LocalizedStringKey { "stats.vsLastMonth" }
    static var noLastMonth: LocalizedStringKey { "stats.noLastMonth" }

    // MARK: - Budget

    static var budgetTitle: LocalizedStringKey { "budget.title" }
    static var budgetTotalSet: LocalizedStringKey { "budget.total.set" }
    static var budgetTotalSetHint: LocalizedStringKey { "budget.total.setHint" }
    static var budgetCategoriesEmpty: LocalizedStringKey { "budget.categories.empty" }
    static var budgetCategoriesEmptyHint: LocalizedStringKey { "budget.categories.emptyHint" }
    static var budgetAdd: LocalizedStringKey { "budget.add" }
    static var budgetEditorNew: LocalizedStringKey { "budget.editor.new" }
    static var budgetEditorEdit: LocalizedStringKey { "budget.editor.edit" }
    static var budgetLimit: LocalizedStringKey { "budget.editor.limit" }
    static var budgetMonth: LocalizedStringKey { "budget.editor.month" }
    static var budgetCategory: LocalizedStringKey { "budget.editor.category" }
    static var budgetConflict: LocalizedStringKey { "budget.editor.conflict" }

    // MARK: - Settings

    static var settingsTitle: LocalizedStringKey { "settings.title" }
    static var sectionAppearance: LocalizedStringKey { "settings.section.appearance" }
    static var sectionLanguage: LocalizedStringKey { "settings.section.language" }
    static var sectionCurrency: LocalizedStringKey { "settings.section.currency" }
    static var sectionData: LocalizedStringKey { "settings.section.data" }
    static var sectionBackup: LocalizedStringKey { "settings.section.backup" }
    static var sectionCategories: LocalizedStringKey { "settings.section.categories" }
    static var sectionAbout: LocalizedStringKey { "settings.section.about" }
    static var dataTransactions: LocalizedStringKey { "settings.data.transactions" }
    static var dataCategories: LocalizedStringKey { "settings.data.categories" }
    static var dataBudgets: LocalizedStringKey { "settings.data.budgets" }
    static var dataSample: LocalizedStringKey { "settings.data.sample" }
    static var dataSampleHint: LocalizedStringKey { "settings.data.sampleHint" }
    static var dataErase: LocalizedStringKey { "settings.data.erase" }
    static var dataEraseTitle: LocalizedStringKey { "settings.data.eraseTitle" }
    static var dataEraseMessage: LocalizedStringKey { "settings.data.eraseMessage" }
    static var dataEraseConfirm: LocalizedStringKey { "settings.data.eraseConfirm" }
    static var backupJSON: LocalizedStringKey { "settings.backup.json" }
    static var backupCSV: LocalizedStringKey { "settings.backup.csv" }
    static var backupImport: LocalizedStringKey { "settings.backup.import" }
    static var backupHint: LocalizedStringKey { "settings.backup.hint" }
    static var manageCategories: LocalizedStringKey { "settings.categories.manage" }
    static var aboutVersion: LocalizedStringKey { "settings.about.version" }
    static var aboutStorage: LocalizedStringKey { "settings.about.storage" }
    static var aboutPrivacy: LocalizedStringKey { "settings.about.privacy" }

    // MARK: - Categories

    static var categoriesTitle: LocalizedStringKey { "categories.title" }
    static var categoriesAdd: LocalizedStringKey { "categories.add" }
    static var categoriesEdit: LocalizedStringKey { "categories.edit" }
    static var categoriesName: LocalizedStringKey { "categories.name" }
    static var categoriesNamePlaceholder: LocalizedStringKey { "categories.namePlaceholder" }
    static var categoriesIcon: LocalizedStringKey { "categories.icon" }
    static var categoriesColor: LocalizedStringKey { "categories.color" }
    static var categoriesBuiltin: LocalizedStringKey { "categories.builtin" }
    static var categoriesDeleteConfirm: LocalizedStringKey { "categories.deleteConfirm" }
    static var categoriesDeleteMessage: LocalizedStringKey { "categories.deleteMessage" }
}

extension L {
    /// Chuỗi có số nhiều cho danh mục.
    static func categoryCount(_ count: Int, bundle: Bundle, locale: Locale) -> String {
        let key = count == 1 ? "categories.count.one" : "categories.count.other"
        return format(key, count, bundle: bundle, locale: locale)
    }

    /// "Còn 3 ngày" / "3 days left".
    static func daysLeft(_ days: Int, bundle: Bundle, locale: Locale) -> String {
        let key = days == 1 ? "budget.daysLeft.one" : "budget.daysLeft.other"
        return format(key, days, bundle: bundle, locale: locale)
    }

    /// Định dạng chuỗi có tham số theo bundle và locale đã chọn.
    ///
    /// Truyền số qua `NSNumber` để `%d` luôn khớp đúng độ rộng, không phụ
    /// thuộc kích thước `Int` của nền tảng.
    private static func format(
        _ key: String,
        _ value: Int,
        bundle: Bundle,
        locale: Locale
    ) -> String {
        let template = bundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: template, locale: locale, arguments: [NSNumber(value: value)])
    }
}
