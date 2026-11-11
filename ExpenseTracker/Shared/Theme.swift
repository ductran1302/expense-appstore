import SwiftUI
import UIKit

/// Một số thẻ tròn dùng chung cho toàn app.
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}

extension View {
    /// Áp dụng nền thẻ chuẩn.
    func cardStyle() -> some View {
        modifier(CardBackground())
    }
}

/// Bảng màu chủ đạo.
enum AppTheme {
    /// Màu nhấn chính.
    static let accent = Color(hex: "#2F6BFF")

    /// Màu cảnh báo khi sắp vượt hạn mức.
    static let warning = Color(hex: "#F59E0B")

    /// Màu cảnh báo khi vượt hạn mức.
    static let danger = Color(hex: "#EF4444")

    /// Màu an toàn.
    static let success = Color(hex: "#10B981")

    /// Màu cho dòng tiền vào.
    static let income = Color(hex: "#10B981")

    /// Màu cho dòng tiền ra.
    static let expense = Color(hex: "#EF4444")

    /// Màu nhạt dùng cho ô nhập liệu.
    static let fieldBackground = Color(.tertiarySystemGroupedBackground)
}

/// Một "con số" lớn hiển thị trên thẻ thống kê.
struct StatTile: View {
    let title: String
    let value: String
    var caption: String?
    var tint: Color = AppTheme.accent
    var systemImage: String = "chart.bar.fill"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
