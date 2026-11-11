import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState

    @Query(sort: \ExpenseTransaction.date, order: .reverse) private var allTransactions: [ExpenseTransaction]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    @Query(sort: \MonthlyBudget.monthStart, order: .reverse) private var allBudgets: [MonthlyBudget]

    @State private var editingBudget: MonthlyBudget?
    @State private var isAdding = false
    @State private var isAddingTotal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MonthPicker(month: appState.monthBinding)

                    totalBudgetCard

                    if categoryBudgets.isEmpty {
                        noBudgetCard
                    } else {
                        VStack(spacing: 10) {
                            ForEach(categoryBudgets) { budget in
                                BudgetRow(
                                    budget: budget,
                                    spent: spent(in: budget.category),
                                    color: Color(hex: budget.category?.colorHex ?? "#6C757D")
                                )
                                .contentShape(Rectangle())
                                .onTapGesture { editingBudget = budget }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(budget)
                                    } label: {
                                        Label("Xoá hạn mức", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal, 16)
                    }

                    Button {
                        isAdding = true
                    } label: {
                        Label("Thêm hạn mức theo danh mục", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Ngân sách")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isAdding) {
                BudgetEditorView(budget: nil)
            }
            .sheet(isPresented: $isAddingTotal) {
                BudgetEditorView(budget: nil, isTotal: true)
            }
            .sheet(item: $editingBudget) { budget in
                BudgetEditorView(budget: budget)
            }
        }
    }

    // MARK: - Cards

    private var totalBudgetCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Tổng ngân sách tháng")
                    .font(.headline)
                Spacer()
                Button {
                    isAddingTotal = true
                } label: {
                    Image(systemName: totalBudget == nil ? "plus.circle.fill" : "slider.horizontal.3")
                        .font(.title3)
                        .foregroundStyle(AppTheme.accent)
                }
            }

            if let totalBudget {
                let spent = monthTotal
                let usage = ratio(spent: spent, limit: totalBudget.limit)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(appState.format(spent))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(color(for: usage))
                        Text("/ \(appState.format(totalBudget.limit))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(usage * 100))%")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(color(for: usage))
                    }

                    ProgressView(value: min(usage, 1))
                        .tint(color(for: usage))

                    HStack {
                        Text(remainingText(spent: spent, limit: totalBudget.limit))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Ngày còn lại: \(daysRemaining)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Button {
                    isAddingTotal = true
                } label: {
                    HStack {
                        Image(systemName: "target")
                        Text("Đặt hạn mức tổng cho tháng")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .cardStyle()
        .padding(.horizontal, 16)
    }

    private var noBudgetCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "target")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("Chưa đặt hạn mức theo danh mục")
                .font(.subheadline.weight(.medium))
            Text("Đặt hạn mức cho ăn uống, đi lại... để theo dõi chi tiêu có vượt hạn hay không.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
        .padding(.horizontal, 16)
    }

    // MARK: - Data

    private var monthBudgets: [MonthlyBudget] {
        allBudgets.filter { Calendar.app.isDate($0.monthStart, equalTo: appState.selectedMonth, toGranularity: .month) }
    }

    private var totalBudget: MonthlyBudget? {
        monthBudgets.first { $0.category === nil }
    }

    private var categoryBudgets: [MonthlyBudget] {
        monthBudgets.filter { $0.category !== nil }
    }

    private var monthTransactions: [ExpenseTransaction] {
        let start = appState.selectedMonth
        let end = start.endOfMonth
        return allTransactions.filter { $0.date >= start && $0.date <= end }
    }

    private var monthTotal: Decimal {
        monthTransactions.reduce(Decimal.zero) { $0 + max($1.amount, 0) }
    }

    private func spent(in category: ExpenseCategory?) -> Decimal {
        monthTransactions
            .filter { transaction in
                guard let category else { return true }
                return transaction.category === category
            }
            .reduce(Decimal.zero) { $0 + max($1.amount, 0) }
    }

    private func ratio(spent: Decimal, limit: Decimal) -> Double {
        guard limit > 0 else { return 0 }
        return NSDecimalNumber(decimal: spent / limit).doubleValue
    }

    private func color(for ratio: Double) -> Color {
        if ratio >= 1 { return AppTheme.danger }
        if ratio >= 0.8 { return AppTheme.warning }
        return AppTheme.success
    }

    private func remainingText(spent: Decimal, limit: Decimal) -> String {
        let remaining = limit - spent
        if remaining >= 0 {
            return "Còn lại \(appState.format(remaining))"
        }
        return "Vượt hạn mức \(appState.format(abs(remaining)))"
    }

    private var daysRemaining: Int {
        let calendar = Calendar.app
        let total = calendar.range(of: .day, in: .month, for: appState.selectedMonth)?.count ?? 30
        let today = Date.now
        guard calendar.isDate(today, equalTo: appState.selectedMonth, toGranularity: .month) else {
            return total
        }
        let day = calendar.component(.day, from: today)
        return max(total - day + 1, 0)
    }

    private func delete(_ budget: MonthlyBudget) {
        context.delete(budget)
        try? context.save()
    }
}

// MARK: - Row

private struct BudgetRow: View {
    let budget: MonthlyBudget
    let spent: Decimal
    let color: Color

    @Environment(AppState.self) private var appState

    private var ratio: Double {
        guard budget.limit > 0 else { return 0 }
        return NSDecimalNumber(decimal: spent / budget.limit).doubleValue
    }

    private var tint: Color {
        if ratio >= 1 { return AppTheme.danger }
        if ratio >= 0.8 { return AppTheme.warning }
        return color
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.16))
                    .frame(width: 38, height: 38)
                Image(systemName: budget.category?.symbol ?? "questionmark.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(budget.category?.name ?? "Khác")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(appState.format(spent)) / \(appState.format(budget.limit))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: min(ratio, 1))
                    .tint(tint)
                Text(tint == AppTheme.danger ? "Đã vượt hạn mức" : "Còn \(appState.format(max(budget.limit - spent, 0)))")
                    .font(.caption2)
                    .foregroundStyle(tint)
            }
        }
        .padding(.vertical, 2)
    }
}
