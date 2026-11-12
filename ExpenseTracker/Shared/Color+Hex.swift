import Foundation
import SwiftUI
import UIKit

extension Color {
    /// Tạo màu từ chuỗi hex ("#FF6B35", "FF6B35", "#F63" hoặc "#FF6B35CC").
    init(hex: String) {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.hasPrefix("#") {
            string.removeFirst()
        }

        var value: UInt64 = 0
        guard Scanner(string: string).scanHexInt64(&value) else {
            self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
            return
        }

        let r, g, b, a: UInt64
        switch string.count {
        case 3:
            r = ((value >> 8) & 0xF) * 17
            g = ((value >> 4) & 0xF) * 17
            b = (value & 0xF) * 17
            a = 255
        case 6:
            r = (value >> 16) & 0xFF
            g = (value >> 8) & 0xFF
            b = value & 0xFF
            a = 255
        case 8:
            r = (value >> 24) & 0xFF
            g = (value >> 16) & 0xFF
            b = (value >> 8) & 0xFF
            a = value & 0xFF
        default:
            r = 0
            g = 0
            b = 0
            a = 255
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Hex tương đương để lưu vào model.
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        _ = uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(
            format: "#%02X%02X%02X",
            Int(round(r * 255)),
            Int(round(g * 255)),
            Int(round(b * 255))
        )
    }
}

/// Màu hiển thị của một danh mục.
///
/// Người dùng chọn màu khi tạo danh mục (dữ liệu hex lưu trong database),
/// nhưng màu đó phải đọc được ở cả chế độ sáng lẫn tối. Vì vậy màu được
/// nâng độ sáng ở chế độ tối và dùng nền riêng thay vì alpha trên nền thẻ.
struct CategoryColor {
    /// Màu chính dùng cho biểu tượng, chữ.
    let base: Color
    /// Nền nhạt dùng cho huy hiệu tròn.
    let soft: Color

    init(hex: String, scheme: ColorScheme) {
        let hue = Color(hex: hex).hue
        let saturation = Color(hex: hex).saturation

        if scheme == .dark {
            // Nâng độ sáng để chữ đọc được trên nền tối.
            self.base = Color(
                hue: hue,
                saturation: min(1, saturation * 0.9),
                brightness: 0.82
            )
            self.soft = Color(
                hue: hue,
                saturation: min(1, saturation * 0.7),
                brightness: 0.26
            )
        } else {
            self.base = Color(
                hue: hue,
                saturation: min(1, saturation * 0.95),
                brightness: 0.62
            )
            self.soft = Color(
                hue: hue,
                saturation: min(1, saturation * 0.65),
                brightness: 0.94
            )
        }
    }
}

extension Color {
    /// Khoảng cách màu (0...1).
    var hue: Double {
        let uiColor = UIColor(self)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return 0 }
        return Double(h)
    }

    /// Độ bão hoà (0...1).
    var saturation: Double {
        let uiColor = UIColor(self)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return 0 }
        return Double(s)
    }
}
