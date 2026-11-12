import SwiftUI

/// Thanh chọn tháng dùng chung.
///
/// Nút có vùng chạm 44pt theo HIG, tiêu đề dùng text style để đáp ứng
/// Dynamic Type, và việc đổi tháng có animation nhẹ.
struct MonthPicker: View {
    @Binding var month: Date
    /// Cho phép xem các tháng trong tương lai. Mặc định là không.
    var allowsFutureMonths: Bool = false

    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Tháng hiện tại, dùng để chặn chuyển sang tương lai.
    private var currentMonth: Date {
        Date.now.startOfMonth
    }

    /// Không cho đi quá tháng hiện tại trừ khi được cho phép.
    private var canGoForward: Bool {
        allowsFutureMonths || month < currentMonth
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            CircleIconButton(
                systemImage: "chevron.left",
                accessibilityLabel: appState.string("common.previousMonth")
            ) {
                step(-1)
            }

            Spacer(minLength: 0)

            Text(appState.monthTitle(month))
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .contentTransition(.numericText())
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            CircleIconButton(
                systemImage: "chevron.right",
                tint: canGoForward ? AppTheme.accent : AppTheme.textTertiary,
                accessibilityLabel: appState.string("common.nextMonth")
            ) {
                step(1)
            }
            .disabled(!canGoForward)
        }
        .padding(.vertical, Spacing.xs)
    }

    private func step(_ value: Int) {
        let target = month.addingMonths(value)
        guard value <= 0 || canGoForward || target <= currentMonth else { return }
        if reduceMotion {
            month = target
        } else {
            withAnimation(.snappy) {
                month = target
            }
        }
    }
}
