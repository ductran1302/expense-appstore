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
    @State private var selectedCategoryName: String?
    @State private var month = Date.now
    @State private var didLoad = false

    var body: some View {
        NavigationStack {
            Form {
                if showsCategoryPicker {
                    Section("Danh mục") {
                        Picker("Danh mục", selection: $selectedCategoryName) {
                            Text("Không có").tag(nil as String?)
                            ForEach(categories) { category in
                                Label(category.name, systemImage: category.symbol)
                                    .tag(category.name as String?)
                            }
                        }
                    }
                }

                Section("Hạn mức") {
                    HStack(spacing: 8) {
                        Text(CurrencyFormatter.symbol(for: appState.currencyCode))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(AppTheme.accent)

                        TextField("0", text: $limitText)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .onChange(of: limitText) { _, newValue in
                                limitText = sanitize(newValue)
                            }
                    }
                    .padding(.vertical, 6)
                }

                Section("Tháng áp dụng") {
                    DatePicker(
                        "Tháng",
                        selection: $month,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }

                Section {
                    HStack {
                        Text("Hạn mức đã tồn tại cho tháng & danh mục này")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(existingConflict ? "Có" : "Không")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(existingConflict ? AppTheme.warning : AppTheme.success)
                    }
                }
            }
            .navigationTitle(budget == nil ? "Thêm hạn mức" : "Sửa hạn mức")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { save() }
                        .fontWeight(.semibold)
                        .disabled(parsedLimit == nil || existingConflict)
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
        if let budget { return budget.category === nil }
        return isTotal
    }

    /// Chỉ hiện ô chọn danh mục khi hạn mức gắn với một danh mục cụ thể.
    private var showsCategoryPicker: Bool {
        if let budget { return budget.category !== nil }
        return !isTotal
    }

    private var selectedCategory: ExpenseCategory? {
        guard let name = selectedCategoryName else { return nil }
        return categories.first { $0.name == name }
    }

    private var existingConflict: Bool {
        guard parsedLimit != nil else { return false }
        let targetMonth = month.startOfMonth
        let targetCategory = isTotalTarget ? nil : selectedCategory
        let key = MonthlyBudget.makeKey(month: targetMonth, categoryName: targetCategory?.name)
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
            limitText = CurrencyFormatter.editString(budget.limit, code: appState.currencyCode)
            selectedCategoryName = budget.category?.name
            month = budget.monthStart
        } else {
            month = appState.selectedMonth
            selectedCategoryName = isTotal ? nil : categories.first?.name
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
