import SwiftUI
import SwiftData

struct TransactionEditorView: View {
    /// `nil` = tạo mới.
    let transaction: ExpenseTransaction?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date.now
    @State private var selectedCategoryKey: String?
    @State private var kind: TransactionKind = .expense
    @State private var didLoad = false
    @FocusState private var isAmountFocused: Bool

    enum TransactionKind: String, CaseIterable, Identifiable {
        case expense
        case income

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .expense: return L.typeExpense
            case .income: return L.typeIncome
            }
        }

        var symbol: String {
            switch self {
            case .expense: return "arrow.up.right.circle.fill"
            case .income: return "arrow.down.left.circle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .expense: return AppTheme.expense
            case .income: return AppTheme.income
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: $kind) {
                        ForEach(TransactionKind.allCases) { item in
                            Label(item.title, systemImage: item.symbol).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.lg, bottom: Spacing.sm, trailing: Spacing.lg))
                }

                Section(L.amount) {
                    HStack(spacing: Spacing.sm) {
                        Text(CurrencyFormatter.symbol(for: appState.currencyCode))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(kind.tint)

                        TextField(L.amountPlaceholder, text: $amountText)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(kind.tint)
                            .focused($isAmountFocused)
                            .onChange(of: amountText) { _, newValue in
                                let sanitized = sanitize(newValue)
                                if sanitized != newValue {
                                    amountText = sanitized
                                }
                            }
                            .accessibilityLabel(L.amount)
                    }
                    .padding(.vertical, Spacing.xs)
                }

                Section(L.category) {
                    Picker(selection: $selectedCategoryKey) {
                        Text(L.noCategory).tag(nil as String?)
                        ForEach(categories) { category in
                            Label(appState.categoryName(category), systemImage: category.symbol)
                                .tag(category.stableKey as String?)
                        }
                    }
                }

                Section(L.details) {
                    DatePicker(
                        L.date,
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    TextField(L.notePlaceholder, text: $note, axis: .vertical)
                        .lineLimit(1...3)
                        .accessibilityLabel(L.note)
                }
            }
            .navigationTitle(transaction == nil ? L.addTitle : L.editTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.save) { save() }
                        .fontWeight(.semibold)
                        .disabled(parsedAmount == nil)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(L.done) { isAmountFocused = false }
                }
            }
            .onAppear(perform: load)
        }
    }

    // MARK: - Helpers

    private var parsedAmount: Decimal? {
        guard let amount = DecimalParser.parse(amountText), amount > 0 else { return nil }
        return kind == .expense ? amount : -amount
    }

    private var selectedCategory: ExpenseCategory? {
        guard let key = selectedCategoryKey else { return nil }
        return categories.first { $0.stableKey == key }
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

        if let transaction {
            amountText = CurrencyFormatter.editString(
                abs(transaction.amount),
                code: appState.currencyCode,
                locale: appState.locale
            )
            note = transaction.note
            date = transaction.date
            selectedCategoryKey = transaction.category?.stableKey
            kind = transaction.amount < 0 ? .income : .expense
        } else {
            selectedCategoryKey = categories.first?.stableKey
            date = Date.now
            isAmountFocused = true
        }
    }

    private func save() {
        guard let amount = parsedAmount else { return }

        if let transaction {
            transaction.amount = amount
            transaction.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            transaction.date = date
            transaction.category = selectedCategory
        } else {
            let newTransaction = ExpenseTransaction(
                amount: amount,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                date: date,
                category: selectedCategory
            )
            context.insert(newTransaction)
        }

        try? context.save()
        dismiss()
    }
}
