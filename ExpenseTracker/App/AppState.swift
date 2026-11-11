import Foundation
import Observation
import SwiftUI

/// Trạng thái dùng chung cho toàn app.
@Observable
final class AppState {
    /// Mã tiền tệ đang dùng.
    var currencyCode: String
    /// Tháng đang chọn (luôn là ngày 1 của tháng).
    var selectedMonth: Date

    private enum Keys {
        static let currencyCode = "settings.currencyCode"
        static let selectedMonth = "settings.selectedMonth"
    }

    init() {
        let defaults = UserDefaults.standard

        let storedCode = defaults.string(forKey: Keys.currencyCode) ?? "VND"
        self.currencyCode = CurrencyFormatter.supported.contains(where: { $0.code == storedCode })
            ? storedCode
            : "VND"

        let storedMonth = defaults.double(forKey: Keys.selectedMonth)
        if storedMonth > 0 {
            self.selectedMonth = Date(timeIntervalSince1970: storedMonth).startOfMonth
        } else {
            self.selectedMonth = Date.now.startOfMonth
        }
    }

    // MARK: - Mutations

    /// Đổi loại tiền và lưu lại.
    func updateCurrency(_ code: String) {
        guard code != currencyCode else { return }
        currencyCode = code
        UserDefaults.standard.set(code, forKey: Keys.currencyCode)
    }

    /// Đổi tháng đang xem và lưu lại.
    func updateMonth(_ month: Date) {
        let normalized = month.startOfMonth
        guard normalized != selectedMonth else { return }
        selectedMonth = normalized
        UserDefaults.standard.set(normalized.timeIntervalSince1970, forKey: Keys.selectedMonth)
    }

    // MARK: - Bindings

    /// Binding cho ô chọn tháng.
    var monthBinding: Binding<Date> {
        Binding(
            get: { self.selectedMonth },
            set: { self.updateMonth($0) }
        )
    }

    /// Binding cho ô chọn tiền tệ.
    var currencyBinding: Binding<String> {
        Binding(
            get: { self.currencyCode },
            set: { self.updateCurrency($0) }
        )
    }

    // MARK: - Helpers

    /// Tháng trước đó.
    var previousMonth: Date {
        selectedMonth.addingMonths(-1)
    }

    /// Tháng sau đó.
    var nextMonth: Date {
        selectedMonth.addingMonths(1)
    }

    /// Định dạng tiền theo loại tiền hiện tại.
    func format(_ amount: Decimal) -> String {
        CurrencyFormatter.string(amount, code: currencyCode)
    }

    /// Định dạng tiền rút gọn (dùng cho trục biểu đồ).
    func compact(_ amount: Double) -> String {
        CurrencyFormatter.compact(amount, code: currencyCode)
    }
}
