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
            VStack(spacing: 0) {
                header

                if filtered.isEmpty {
                    emptyState
                } else {
                    List {
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
                                            Label("Xoá", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                DayHeader(date: group.date, total: group.total)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Giao dịch")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Tìm theo ghi chú hoặc danh mục")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Danh mục", selection: $filter) {
                            Label(CategoryFilter.all.title, systemImage: CategoryFilter.all.symbol)
                                .tag(CategoryFilter.all)
                            ForEach(categories) { category in
                                Label(category.name, systemImage: category.symbol)
                                    .tag(CategoryFilter.category(category.name))
                            }
                        }
                    } label: {
                        Label(filter.title, systemImage: filter.symbol)
                            .font(.subheadline)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAdding = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAdding) {
                TransactionEditorView(transaction: nil)
            }
            .sheet(item: $editingTransaction) { transaction in
                TransactionEditorView(transaction: transaction)
            }
            .alert("Xoá giao dịch?", isPresented: $isShowingDeleteAlert) {
                Button("Xoá", role: .destructive) {
                    if let pendingDeletion {
                        context.delete(pendingDeletion)
                        try? context.save()
                    }
                    pendingDeletion = nil
                }
                Button("Huỷ", role: .cancel) {
                    pendingDeletion = nil
                }
            } message: {
                Text("Giao dịch sẽ bị xoá vĩnh viễn.")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            MonthPicker(month: appState.monthBinding)

            HStack(spacing: 10) {
                StatTile(
                    title: "Tổng chi",
                    value: appState.format(totalSpent),
                    caption: "\(filtered.count) giao dịch",
                    tint: AppTheme.expense,
                    systemImage: "arrow.up.right"
                )
                StatTile(
                    title: "Trung bình/ngày",
                    value: appState.format(averagePerDay),
                    caption: "theo tháng này",
                    tint: AppTheme.accent,
                    systemImage: "calendar"
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
        .padding(.top, 8)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Chưa có giao dịch", systemImage: "tray")
        } description: {
            Text(searchText.isEmpty
                 ? "Thêm giao dịch đầu tiên để bắt đầu theo dõi chi tiêu."
                 : "Không tìm thấy giao dịch phù hợp.")
        } actions: {
            Button("Thêm giao dịch") { isAdding = true }
                .buttonStyle(.borderedProminent)
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
            case .category(let name):
                guard transaction.category?.name == name else { return false }
            }

            guard !query.isEmpty else { return true }
            return transaction.note.localizedCaseInsensitiveContains(query)
                || (transaction.category?.name.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private var totalSpent: Decimal {
        filtered.reduce(Decimal.zero) { $0 + max($1.amount, 0) }
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
            Text(date.formatted(.dateTime.weekday(.wide).day().month()))
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(appState.format(total))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Filter

/// Bộ lọc danh mục của danh sách giao dịch.
enum CategoryFilter: Hashable {
    case all
    case category(String)

    var title: String {
        switch self {
        case .all: return "Tất cả"
        case .category(let name): return name
        }
    }

    var symbol: String {
        switch self {
        case .all: return "line.3.horizontal.decrease.circle"
        case .category: return "tag.fill"
        }
    }
}
