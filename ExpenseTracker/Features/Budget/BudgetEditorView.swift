import SwiftUI
import SwiftData

struct BudgetEditorView: View {
    /// `nil` = tạo mới.
    let budget: MonthlyBudget?
    /// Tạo hạn mức tổng cho tháng thay vì theo danh mục.
    var isTotal: Bool = false

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]
    @Query(sort: \MonthlyBudget.monthStart, order: .reverse) private var allBudgets: [MonthlyBudget]

    @State private var limitText = ""
    @State private var selectedCategoryKey: String?
    @State private var month = Date.now
    @State private var didLoad = false
    @FocusState private var isLimitFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                if showsCategoryPicker {
                    Section(L.budgetCategory) {
                        Picker(selection: $selectedCategoryKey) {
                            Text(L.noCategory).tag(nil as String?)
                            ForEach(categories) { category in
                                Label(appState.categoryName(category), systemImage: category.symbol)
                                    .tag(category.stableKey as String?)
                            }
                        }
                    }
                }

                Section(L.budgetLimit) {
                    HStack(spacing: Spacing.sm) {
                        Text(CurrencyFormatter.symbol(for: appState.currencyCode))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.accent)

                        TextField("0", text: $limitText)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(AppTheme.accent)
                            .focused($isLimitFocused)
                            .onChange(of: limitText) { _, newValue in
                                let sanitized = sanitize(newValue)
                                if sanitized != newValue {
                                    limitText = sanitized
                                }
                            }
                            .accessibilityLabel(L.budgetLimit)
                    }
                    .padding(.vertical, Spacing.xs)
                }

                Section(L.budgetMonth) {
                    DatePicker(
                        L.budgetMonth,
                        selection: $month,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }

                if existingConflict {
                    Section {
                        Label(L.budgetConflict, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.warning)
                    }
                }
            }
            .navigationTitle(budget == nil ? L.budgetEditorNew : L.budgetEditorEdit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.save) { save() }
                        .fontWeight(.semibold)
                        .disabled(parsedLimit == nil || existingConflict)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(L.done) { isLimitFocused = false }
                }
            }
            .onAppear(perform: load)
        }
    }

    // MARK: - Helpers

    private var parsedLimit: Decimal? {
        guard let value = DecimalParser.parse(limitText), value > 0 else { return nil }
        return value
    }

    private var isTotalTarget: Bool {
        if let budget { return budget.category == nil }
        return isTotal
    }

    /// Chỉ hiện ô chọn danh mục khi hạn mức gắn với một danh mục cụ thể.
    private var showsCategoryPicker: Bool {
        if let budget { return budget.category != nil }
        return !isTotal
    }

    private var selectedCategory: ExpenseCategory? {
        guard let key = selectedCategoryKey else { return nil }
        return categories.first { $0.stableKey == key }
    }

    private var existingConflict: Bool {
        guard parsedLimit != nil else { return false }
        let targetMonth = month.startOfMonth
        let targetCategory = isTotalTarget ? nil : selectedCategory
        let key = MonthlyBudget.makeKey(month: targetMonth, categoryKey: targetCategory?.stableKey)
        return allBudgets.contains { existing in
            guard existing.key == key else { return false }
            guard let budget else { return true }
            return existing !== budget
        }
    }

    private func sanitize(_ text: String) -> String {
        var result = ""
        var hasSeparator = false
        for character in text {
            if character.isNumber {
                result.append(character)
            } else if character == "." || character == "," {
                if !hasSeparator {
                    result.append(".")
                    hasSeparator = true
                }
            }
        }
        return result
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true

        if let budget {
            limitText = CurrencyFormatter.editString(
                budget.limit,
                code: appState.currencyCode,
                locale: appState.locale
            )
            selectedCategoryKey = budget.category?.stableKey
            month = budget.monthStart
        } else {
            month = appState.selectedMonth
            selectedCategoryKey = isTotal ? nil : categories.first?.stableKey
            isLimitFocused = true
        }
    }

    private func save() {
        guard let limit = parsedLimit else { return }

        let targetMonth = month.startOfMonth
        let targetCategory = isTotalTarget ? nil : selectedCategory

        if let budget {
            budget.limit = limit
            budget.monthStart = targetMonth
            budget.category = targetCategory
        } else {
            let newBudget = MonthlyBudget(monthStart: targetMonth, limit: limit, category: targetCategory)
            context.insert(newBudget)
        }

        try? context.save()
        dismiss()
    }
}
