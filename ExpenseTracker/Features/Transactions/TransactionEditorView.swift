import SwiftUI
import SwiftData

struct TransactionEditorView: View {
    /// `nil` = tạo mới.
    let transaction: ExpenseTransaction?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date.now
    @State private var selectedCategoryName: String?
    @State private var kind: TransactionKind = .expense
    @State private var didLoad = false

    enum TransactionKind: String, CaseIterable, Identifiable {
        case expense
        case income

        var id: String { rawValue }

        var title: String {
            switch self {
            case .expense: return "Chi tiêu"
            case .income: return "Thu nhập"
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
                    Picker("Loại", selection: $kind) {
                        ForEach(TransactionKind.allCases) { item in
                            Label(item.title, systemImage: item.symbol).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section("Số tiền") {
                    HStack(spacing: 8) {
                        Text(CurrencyFormatter.symbol(for: appState.currencyCode))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(kind.tint)

                        TextField("0", text: $amountText)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(kind.tint)
                            .onChange(of: amountText) { _, newValue in
                                guard !newValue.isEmpty else { return }
                                amountText = sanitize(newValue)
                            }
                    }
                    .padding(.vertical, 6)
                }

                Section("Danh mục") {
                    Picker("Danh mục", selection: $selectedCategoryName) {
                        Text("Không có").tag(nil as String?)
                        ForEach(categories) { category in
                            Label(category.name, systemImage: category.symbol)
                                .tag(category.name as String?)
                        }
                    }
                }

                Section("Chi tiết") {
                    DatePicker("Ngày", selection: $date, displayedComponents: [.date, .hourAndMinute])

                    TextField("Ghi chú (không bắt buộc)", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .navigationTitle(transaction == nil ? "Thêm giao dịch" : "Sửa giao dịch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { save() }
                        .fontWeight(.semibold)
                        .disabled(parsedAmount == nil)
                }
            }
            .onAppear(perform: load)
        }
    }

    // MARK: - Helpers

    private var parsedAmount: Decimal? {
        guard let amount = DecimalParser.parse(amountText) else { return nil }
        return kind == .expense ? abs(amount) : -abs(amount)
    }

    private var selectedCategory: ExpenseCategory? {
        guard let name = selectedCategoryName else { return nil }
        return categories.first { $0.name == name }
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
            amountText = CurrencyFormatter.editString(abs(transaction.amount), code: appState.currencyCode)
            note = transaction.note
            date = transaction.date
            selectedCategoryName = transaction.category?.name
            kind = transaction.amount < 0 ? .income : .expense
        } else {
            selectedCategoryName = categories.first?.name
            date = Date.now
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
