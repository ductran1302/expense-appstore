import Foundation
import SwiftUI

/// Thang khoảng cách chuẩn (base 4pt).
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 28
    static let xxxl: CGFloat = 40
}

/// Bo góc chuẩn.
enum Radius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let pill: CGFloat = 999
}

/// Kích thước chạm tối thiểu theo HIG (44pt).
enum HitSize {
    static let minimum: CGFloat = 44
}

/// Thẻ nội dung dùng chung.
///
/// Bo góc, nền và đường viền đều lấy từ màu semantic nên tự thích ứng
/// sáng/tối và tăng độ tương phản.
struct Card: ViewModifier {
    var padding: CGFloat = Spacing.lg
    var background: Color = AppTheme.surface

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(AppTheme.separator, lineWidth: 1)
            )
    }
}

extension View {
    /// Bọc nội dung trong thẻ chuẩn.
    func cardStyle(padding: CGFloat = Spacing.lg, background: Color = AppTheme.surface) -> some View {
        modifier(Card(padding: padding, background: background))
    }
}

/// Nhãn nhỏ nằm trên tiêu đề, dùng để gom nhóm nội dung.
struct SectionLabel: View {
    let text: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.semibold))
            }
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(AppTheme.textSecondary)
        .textCase(.uppercase)
        .kerning(0.4)
    }
}

/// Chip tròn nhỏ dùng cho trạng thái / delta.
struct Badge: View {
    let text: String
    var systemImage: String?
    var tint: Color = AppTheme.accent

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.bold))
            }
            Text(text)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(tint)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs + 1)
        .background(tint.opacity(0.14), in: Capsule())
    }
}

/// Thanh tiến trình mảnh, bo tròn hai đầu.
struct ProgressBar: View {
    let value: Double
    var tint: Color = AppTheme.accent
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.fill)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, value)) * proxy.size.width)
            }
        }
        .frame(height: height)
        .animation(.smooth(duration: 0.35), value: value)
    }
}

/// Nút tròn dùng cho thao tác chính.
struct CircleIconButton: View {
    let systemImage: String
    var tint: Color = AppTheme.accent
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: HitSize.minimum, height: HitSize.minimum)
                .background(AppTheme.surfaceRaised, in: Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel(accessibilityLabel)
    }
}
