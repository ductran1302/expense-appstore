import SwiftUI

/// Thanh chọn tháng dùng chung.
struct MonthPicker: View {
    @Binding var month: Date
    var canGoForward: Bool = true

    private var title: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.snappy) { month = month.addingMonths(-1) }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(Color(.tertiarySystemGroupedBackground), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Text(title)
                .font(.headline)
                .contentTransition(.numericText())
                .frame(minWidth: 150)

            Spacer(minLength: 0)

            Button {
                withAnimation(.snappy) { month = month.addingMonths(1) }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(Color(.tertiarySystemGroupedBackground), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canGoForward)
            .opacity(canGoForward ? 1 : 0.35)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
