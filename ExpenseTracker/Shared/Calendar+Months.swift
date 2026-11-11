import Foundation

extension Calendar {
    /// Lịch dùng chung cho toàn app.
    static var app: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .autoupdatingCurrent
        calendar.firstWeekday = 2 // Thứ Hai
        return calendar
    }
}

extension Date {
    /// Đầu tháng (00:00 ngày 1) của ngày này.
    var startOfMonth: Date {
        let components = Calendar.app.dateComponents([.year, .month], from: self)
        return Calendar.app.date(from: components) ?? self
    }

    /// Cuối tháng (23:59:59 ngày cuối) của ngày này.
    var endOfMonth: Date {
        let start = startOfMonth
        return Calendar.app.date(byAdding: DateComponents(month: 1, second: -1, to: start)) ?? start
    }

    /// Thêm/bớt số tháng, giữ nguyên ngày trong tháng (ví dụ 31/1 + 1 tháng = 28/2).
    func addingMonths(_ value: Int) -> Date {
        Calendar.app.date(byAdding: .month, value: value, to: self) ?? self
    }

    /// Khoá duy nhất theo tháng, ví dụ "2026-11".
    var monthKey: String {
        let components = Calendar.app.dateComponents([.year, .month], from: self)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return String(format: "%04d-%02d", year, month)
    }

    /// Khoá duy nhất theo ngày, ví dụ "2026-11-05".
    var dayKey: String {
        let components = Calendar.app.dateComponents([.year, .month, .day], from: self)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// 00:00 của ngày này.
    var beginningOfDay: Date {
        Calendar.app.startOfDay(for: self)
    }
}
