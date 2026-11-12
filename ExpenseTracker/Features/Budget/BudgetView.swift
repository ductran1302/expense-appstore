import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \ExpenseTransaction.date, order: .reverse) private var allTransactions: [ExpenseTransaction]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    @Query(sort: \MonthlyBudget.monthStart, order: .reverse) private var allBudgets: [MonthlyBudget]

    @State private var editingBudget: MonthlyBudget?
    @State private var isAdding = false
    @State private var isAddingTotal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    MonthPicker(month: appState.monthBinding)

                    totalBudgetCard

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionLabel(text: appState.string("budget.categories.title"))

                        if categoryBudgets.isEmpty {
                            emptyCategories
                        } else {
                            ForEach(categoryBudgets) { budget in
                                budgetRow(budget)
                            }
                        }
                    }
                    .cardStyle(padding: Spacing.lg)

                    Button(action: { isAdding = true }) {
                        Label(L.budgetAdd, systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L.budgetTitle)
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

    // MARK: - Total budget

    private var totalBudgetCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                SectionLabel(text: appState.string("budget.total.title"))
                Spacer()
                if let totalBudget {
                    Button {
                        editingBudget = totalBudget
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                            .frame(width: HitSize.minimum, height: HitSize.minimum)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L.budgetEditorEdit)
                }
            }

            if let totalBudget {
                let spent = monthTotal
                let usage = ratio(spent: spent, limit: totalBudget.limit)
                let status = AppTheme.budgetStatus(for: usage)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(appState.format(spent))
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())

                    ProgressBar(value: usage, tint: status, height: 8)

                    HStack {
                        Text(usage >= 1
                             ? appState.string("budget.over")
                             : appState.string("budget.remaining"))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)

                        Spacer()

                        Text(appState.format(abs(totalBudget.limit - spent)))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(status)
                            .monospacedDigit()
                    }

                    if daysRemaining > 0 {
                        Text(L.daysLeft(
                            daysRemaining,
                            bundle: appState.localizationBundle,
                            locale: appState.locale
                        ))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Button(action: { isAddingTotal = true }) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "target")
                                .foregroundStyle(AppTheme.accent)
                            Text(L.budgetTotalSet)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.accent)
                        }
                        .frame(minHeight: HitSize.minimum)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Text(L.budgetTotalSetHint)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .cardStyle(padding: Spacing.xl)
    }

    // MARK: - Rows

    private func budgetRow(_ budget: MonthlyBudget) -> some View {
        let spent = spent(in: budget.category)
        let usage = ratio(spent: spent, limit: budget.limit)
        let status = AppTheme.budgetStatus(for: usage)
        let categoryColor = CategoryColor(
            hex: budget.category?.colorHex ?? "#6C757D",
            scheme: colorScheme
        )

        return Button {
            editingBudget = budget
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(categoryColor.soft)
                        .frame(width: 36, height: 36)
                    Image(systemName: budget.category?.symbol ?? "questionmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(categoryColor.base)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Text(budget.category.map { appState.categoryName($0) }
                             ?? appState.string("transactions.noCategory"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Text(appState.format(spent))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                            .monospacedDigit()
                    }

                    ProgressBar(value: usage, tint: status, height: 5)

                    Text(usage >= 1
                         ? "\(appState.string("budget.over")) \(appState.format(abs(budget.limit - spent)))"
                         : "\(appState.string("budget.remaining")) \(appState.format(budget.limit - spent))")
                        .font(.caption2)
                        .foregroundStyle(status)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                delete(budget)
            } label: {
                Label(L.delete, systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var emptyCategories: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(AppTheme.textTertiary)
            Text(L.budgetCategoriesEmpty)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
            Text(L.budgetCategoriesEmptyHint)
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
    }

    // MARK: - Data

    private var monthBudgets: [MonthlyBudget] {
        allBudgets.filter {
            Calendar.app.isDate($0.monthStart, equalTo: appState.selectedMonth, toGranularity: .month)
        }
    }

    private var totalBudget: MonthlyBudget? {
        monthBudgets.first { $0.category == nil }
    }

    private var categoryBudgets: [MonthlyBudget] {
        monthBudgets.filter { $0.category != nil }
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
