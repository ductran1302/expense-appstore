import SwiftUI

struct TransactionRow: View {
    let transaction: ExpenseTransaction

    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var tint: CategoryColor {
        CategoryColor(hex: transaction.category?.colorHex ?? "#6C757D", scheme: colorScheme)
    }

    private var isIncome: Bool {
        transaction.amount < 0
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(tint.soft)
                    .frame(width: 40, height: 40)
                Image(systemName: transaction.category?.symbol ?? "questionmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint.base)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category.map { appState.categoryName($0) }
                     ?? appState.string("transactions.noCategory"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                } else {
                    Text(transaction.date.formatted(Date.FormatStyle(locale: appState.locale).hour().minute()))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }

            Spacer(minLength: Spacing.sm)

            Text(appState.format(abs(transaction.amount)))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(isIncome ? AppTheme.income : AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, Spacing.xxs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let category = transaction.category.map { appState.categoryName($0) }
            ?? appState.string("transactions.noCategory")
        let amount = appState.format(abs(transaction.amount))
        let sign = isIncome ? "+" : "-"
        return "\(category), \(sign)\(amount)"
    }
}
