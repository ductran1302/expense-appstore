import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState

    @Query(sort: \ExpenseTransaction.date, order: .reverse) private var allTransactions: [ExpenseTransaction]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var searchText = ""
    @State private var editingTransaction: ExpenseTransaction?
    @State private var isAdding = false
    @State private var filter: CategoryFilter = .all
    @State private var isShowingDeleteAlert = false
    @State private var pendingDeletion: ExpenseTransaction?

    var body: some View {
        NavigationStack {
            List {
                heroSection

                if filtered.isEmpty {
                    emptySection
                } else {
                    ForEach(groupedDays) { group in
                        Section {
                            ForEach(group.transactions) { transaction in
                                Button {
                                    editingTransaction = transaction
                                } label: {
                                    TransactionRow(transaction: transaction)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        pendingDeletion = transaction
                                        isShowingDeleteAlert = true
                                    } label: {
                                        Label(L.delete, systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            DayHeader(date: group.date, total: group.total)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(L.transactionsTitle)
            .searchable(text: $searchText, prompt: L.searchPrompt)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker(selection: $filter) {
                            Label(L.filterAll, systemImage: CategoryFilter.all.symbol)
                                .tag(CategoryFilter.all)
                            ForEach(categories) { category in
                                Label(appState.categoryName(category), systemImage: category.symbol)
                                    .tag(CategoryFilter.category(category.stableKey))
                            }
                        }
                    } label: {
                        Label(filterTitle, systemImage: filter.symbol)
                            .font(.subheadline.weight(.medium))
                    }
                    .accessibilityLabel(L.filterCategory)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAdding = true
                    } label: {
                        Label(L.addTitle, systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAdding) {
                TransactionEditorView(transaction: nil)
            }
            .sheet(item: $editingTransaction) { transaction in
                TransactionEditorView(transaction: transaction)
            }
            .alert(L.deleteTitle, isPresented: $isShowingDeleteAlert) {
                Button(L.delete, role: .destructive) {
                    if let pendingDeletion {
                        context.delete(pendingDeletion)
                        try? context.save()
                    }
                    pendingDeletion = nil
                }
                Button(L.cancel, role: .cancel) {
                    pendingDeletion = nil
                }
            } message: {
                Text(L.deleteMessage)
            }
        }
    }

    // MARK: - Hero

    /// Khối tổng quan đầu màn hình: tổng chi tháng là điểm nhấn chính,
    /// thông tin phụ xếp bên dưới theo thứ bạch để không cạnh tranh chú ý.
    private var heroSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                MonthPicker(month: appState.monthBinding)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(L.totalSpent)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    Text(appState.format(totalSpent))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .accessibilityLabel(L.totalSpent)
                        .accessibilityValue(appState.format(totalSpent))
                }

                HStack(spacing: Spacing.lg) {
                    metric(
                        title: L.dailyAverage,
                        value: appState.format(averagePerDay),
                        systemImage: "calendar"
                    )
                    metric(
                        title: L.dataTransactions,
                        value: "\(filtered.count)",
                        systemImage: "list.bullet"
                    )
                    Spacer(minLength: 0)
                }
            }
            .padding(.vertical, Spacing.xs)
            .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.lg, bottom: Spacing.lg, trailing: Spacing.lg))
            .listRowBackground(Color.clear)
        }
    }

    private func metric(title: LocalizedStringKey, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .labelStyle(.titleAndIcon)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Empty state

    private var emptySection: some View {
        Section {
            VStack(spacing: Spacing.md) {
                Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppTheme.textTertiary)

                VStack(spacing: Spacing.xs) {
                    Text(searchText.isEmpty ? L.emptyTitle : L.emptySearchTitle)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(searchText.isEmpty ? L.emptyMessage : L.emptySearchMessage)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                if searchText.isEmpty {
                    Button(action: { isAdding = true }) {
                        Label(L.emptyAction, systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xxl)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    // MARK: - Data

    private var filtered: [ExpenseTransaction] {
        let monthStart = appState.selectedMonth
        let monthEnd = monthStart.endOfMonth
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return allTransactions.filter { transaction in
            guard transaction.date >= monthStart, transaction.date <= monthEnd else { return false }

            switch filter {
            case .all:
                break
            case .category(let key):
                guard transaction.category?.stableKey == key else { return false }
            }

            guard !query.isEmpty else { return true }
            return transaction.note.localizedCaseInsensitiveContains(query)
                || (transaction.category.map { appState.categoryName($0).localizedCaseInsensitiveContains(query) } ?? false)
        }
    }

    private var totalSpent: Decimal {
        filtered.reduce(Decimal.zero) { $0 + max($1.amount, 0) }
    }

    /// Nhãn hiển thị của bộ lọc đang chọn.
    private var filterTitle: String {
        switch filter {
        case .all:
            return appState.string("transactions.filterAll")
        case .category(let key):
            return categories.first { $0.stableKey == key }
                .map { appState.categoryName($0) } ?? appState.string("transactions.filterAll")
        }
    }

    private var averagePerDay: Decimal {
        let days = Calendar.app.range(of: .day, in: .month, for: appState.selectedMonth)?.count ?? 30
        guard days > 0 else { return .zero }
        return totalSpent / Decimal(days)
    }

    /// Một nhóm giao dịch theo ngày.
    struct DayGroup: Identifiable {
        let id: String
        let date: Date
        let total: Decimal
        let transactions: [ExpenseTransaction]
    }

    private var groupedDays: [DayGroup] {
        let grouped = Dictionary(grouping: filtered) { $0.date.dayKey }
        var result: [DayGroup] = []

        for (key, value) in grouped {
            guard let first = value.first else { continue }
            let total = value.reduce(Decimal.zero) { $0 + max($1.amount, 0) }
            result.append(DayGroup(id: key, date: first.date.beginningOfDay, total: total, transactions: value))
        }

        return result.sorted { $0.date > $1.date }
    }
}

// MARK: - Day header

private struct DayHeader: View {
    let date: Date
    let total: Decimal

    @Environment(AppState.self) private var appState

    var body: some View {
        HStack {
            Text(appState.dayTitle(date))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Text(appState.format(total))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .monospacedDigit()
        }
        .textCase(nil)
        // Section header không nhận `listRowInsets`, nên tự canh lề.
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Filter

/// Bộ lọc danh mục của danh sách giao dịch.
enum CategoryFilter: Hashable {
    case all
    case category(String)

    var symbol: String {
        switch self {
        case .all: return "line.3.horizontal.decrease.circle"
        case .category: return "tag.fill"
        }
    }
}
