import SwiftUI
import UIKit

/// Design tokens của app.
///
/// Nguyên tắc: mọi màu đều khai báo cả biến thể sáng và tối, để UI tự đổi
/// theo hệ thống. Không dùng hex cứng cho màu giao diện.
enum AppTheme {

    // MARK: - Màu nhấn

    /// Màu nhấn chính (hành động chính, trạng thái chọn).
    static let accent = Color.dynamic(
        light: UIColor(red: 0.18, green: 0.42, blue: 1.00, alpha: 1),
        dark: UIColor(red: 0.44, green: 0.62, blue: 1.00, alpha: 1)
    )

    /// Nền nhấn nhạt cho thẻ, chip.
    static let accentSoft = Color.dynamic(
        light: UIColor(red: 0.18, green: 0.42, blue: 1.00, alpha: 0.10),
        dark: UIColor(red: 0.44, green: 0.62, blue: 1.00, alpha: 0.18)
    )

    // MARK: - Màu ngữ nghĩa

    /// Dòng tiền ra.
    static let expense = Color.dynamic(
        light: UIColor(red: 0.85, green: 0.22, blue: 0.22, alpha: 1),
        dark: UIColor(red: 1.00, green: 0.42, blue: 0.40, alpha: 1)
    )

    /// Dòng tiền vào.
    static let income = Color.dynamic(
        light: UIColor(red: 0.02, green: 0.56, blue: 0.39, alpha: 1),
        dark: UIColor(red: 0.24, green: 0.83, blue: 0.58, alpha: 1)
    )

    /// Sắp vượt hạn mức (80–100%).
    static let warning = Color.dynamic(
        light: UIColor(red: 0.72, green: 0.44, blue: 0.02, alpha: 1),
        dark: UIColor(red: 1.00, green: 0.71, blue: 0.26, alpha: 1)
    )

    /// Vượt hạn mức.
    static let danger = Color.dynamic(
        light: UIColor(red: 0.85, green: 0.22, blue: 0.22, alpha: 1),
        dark: UIColor(red: 1.00, green: 0.42, blue: 0.40, alpha: 1)
    )

    /// Trạng thái an toàn.
    static let success = Color.dynamic(
        light: UIColor(red: 0.02, green: 0.56, blue: 0.39, alpha: 1),
        dark: UIColor(red: 0.24, green: 0.83, blue: 0.58, alpha: 1)
    )

    // MARK: - Bề mặt

    /// Nền thẻ nội dung.
    static let surface = Color(.secondarySystemGroupedBackground)

    /// Nền nổi bật hơn thẻ (ô nhập, chip).
    static let surfaceRaised = Color(.tertiarySystemGroupedBackground)

    /// Nền nút nhấn.
    static let fill = Color(.secondarySystemFill)

    /// Đường kẻ.
    static let separator = Color.dynamic(
        light: UIColor(white: 0, alpha: 0.10),
        dark: UIColor(white: 1, alpha: 0.14)
    )

    /// Chữ chính.
    static let textPrimary = Color(.label)

    /// Chữ phụ.
    static let textSecondary = Color(.secondaryLabel)

    /// Chữ bậc ba.
    static let textTertiary = Color(.tertiaryLabel)

    // MARK: - Số liệu

    /// Màu của thanh tiến trình theo mức sử dụng hạn mức.
    static func budgetStatus(for ratio: Double) -> Color {
        if ratio >= 1 { return danger }
        if ratio >= 0.8 { return warning }
        return success
    }
}

extension Color {
    /// Màu tự đổi theo giao diện sáng/tối.
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}
