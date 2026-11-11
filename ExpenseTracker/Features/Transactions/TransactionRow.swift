import SwiftUI

struct TransactionRow: View {
    let transaction: ExpenseTransaction

    @Environment(AppState.self) private var appState

    private var tint: Color {
        Color(hex: transaction.category?.colorHex ?? "#6C757D")
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 42, height: 42)
                Image(systemName: transaction.category?.symbol ?? "questionmark.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.category?.name ?? "Khác")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(transaction.date.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 8)

            Text(appState.format(transaction.amount))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(transaction.amount >= 0 ? AppTheme.expense : AppTheme.income)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
