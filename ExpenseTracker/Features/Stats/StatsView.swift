import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(AppState.self) private var appState

    @Query(sort: \ExpenseTransaction.date, order: .reverse) private var allTransactions: [ExpenseTransaction]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var chartMode: ChartMode = .category

    enum ChartMode: String, CaseIterable, Identifiable {
        case category
        case daily

        var id: String { rawValue }

        var title: String {
            switch self {
            case .category: return "Theo danh mục"
            case .daily: return "Theo ngày"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    MonthPicker(month: appState.monthBinding)

                    summaryTiles

                    Picker("Loại biểu đồ", selection: $chartMode) {
                        ForEach(ChartMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)

                    switch chartMode {
                    case .category:
                        categoryChart
                    case .daily:
                        dailyChart
                    }

                    categoryBreakdown
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Thống kê")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Summary

    private var summaryTiles: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatTile(
                    title: "Tổng chi",
                    value: appState.format(monthTotal),
                    caption: "tháng \(appState.selectedMonth.formatted(.dateTime.month(.wide)))",
                    tint: AppTheme.expense,
                    systemImage: "arrow.up.right"
                )
                StatTile(
                    title: "Thu nhập",
                    value: appState.format(monthIncome),
                    caption: monthIncome > 0 ? "có ghi nhận" : "chưa có",
                    tint: AppTheme.income,
                    systemImage: "arrow.down.left"
                )
            }

            HStack(spacing: 10) {
                StatTile(
                    title: "So với tháng trước",
                    value: appState.format(abs(changeAmount)),
                    caption: changeLabel,
                    tint: changeTint,
                    systemImage: changeTint == AppTheme.success ? "arrow.down.right" : "arrow.up.right"
                )
                StatTile(
                    title: "Số giao dịch",
                    value: "\(monthTransactions.count)",
                    caption: "trong tháng",
                    tint: AppTheme.accent,
                    systemImage: "number"
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Charts

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            if categorySlices.isEmpty {
                noData
            } else {
                Chart(categorySlices) { slice in
                    SectorMark(
                        angle: .value("Chi tiêu", slice.amount),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(slice.color)
                }
                .frame(height: 240)
                .chartLegend(.hidden)
                .padding(.vertical, 4)
            }
        }
        .cardStyle()
        .padding(.horizontal, 16)
    }

    private var dailyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            if dailyPoints.isEmpty {
                noData
            } else {
                Chart(dailyPoints) { point in
                    BarMark(
                        x: .value("Ngày", point.date, unit: .day),
                        y: .value("Chi tiêu", point.amount)
                    )
                    .foregroundStyle(AppTheme.accent.gradient)
                    .cornerRadius(3)
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(appState.compact(amount))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 5)) { value in
                        AxisValueLabel(format: .dateTime.day())
                    }
                }
            }
        }
        .cardStyle()
        .padding(.horizontal, 16)
    }

    private var noData: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.pie")
                .font(.system(size: 34))
                .foregroundStyle(.tertiary)
            Text("Chưa có dữ liệu trong tháng này")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }

    // MARK: - Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chi tiết danh mục")
                .font(.headline)

            if categorySlices.isEmpty {
                Text("Chưa có chi tiêu nào.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(categorySlices) { slice in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(slice.color.opacity(0.16))
                                .frame(width: 34, height: 34)
                            Image(systemName: slice.symbol)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(slice.color)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(slice.name)
                                .font(.subheadline.weight(.medium))
                            ProgressView(value: min(slice.ratio, 1))
                                .tint(slice.color)
                        }

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(appState.format(slice.amount))
                                .font(.subheadline.weight(.semibold))
                            Text("\(Int(slice.ratio * 100))%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .cardStyle()
        .padding(.horizontal, 16)
    }

    // MARK: - Data

    private var monthTransactions: [ExpenseTransaction] {
        let start = appState.selectedMonth
        let end = start.endOfMonth
        return allTransactions.filter { $0.date >= start && $0.date <= end }
    }

    private var monthTotal: Decimal {
        monthTransactions.reduce(Decimal.zero) { $0 + max($1.amount, 0) }
    }

    private var monthIncome: Decimal {
        monthTransactions.reduce(Decimal.zero) { $0 + abs(min($1.amount, 0)) }
    }

    private var previousMonthTotal: Decimal {
        let start = appState.previousMonth
        let end = start.endOfMonth
        return allTransactions
            .filter { $0.date >= start && $0.date <= end }
            .reduce(Decimal.zero) { $0 + max($1.amount, 0) }
    }

    private var changeAmount: Decimal {
        monthTotal - previousMonthTotal
    }

    private var changeTint: Color {
        if previousMonthTotal == 0 { return AppTheme.accent }
        return changeAmount <= 0 ? AppTheme.success : AppTheme.danger
    }

    private var changeLabel: String {
        if previousMonthTotal == 0 { return "chưa có dữ liệu tháng trước" }
        let percent = (changeAmount / previousMonthTotal) * 100
        let rounded = NSDecimalNumber(decimal: abs(percent)).intValue
        return "\(rounded)% \(changeAmount <= 0 ? "ít hơn" : "nhiều hơn")"
    }

    /// Một lát cột trong biểu đồ tròn.
    struct CategorySlice: Identifiable {
        let id: String
        let name: String
        let symbol: String
        let color: Color
        /// Giá trị dùng cho biểu đồ (Charts yêu cầu kiểu số đo lường được).
        let amount: Double
        /// Tỷ lệ 0...1 so với tổng chi tháng.
        let ratio: Double
    }

    private var categorySlices: [CategorySlice] {
        let grouped = Dictionary(grouping: monthTransactions) { $0.category?.name ?? "Khác" }
        let total = grouped.values.reduce(Decimal.zero) { partial, transactions in
            partial + transactions.reduce(Decimal.zero) { $0 + max($1.amount, 0) }
        }
        guard total > 0 else { return [] }

        let totalDouble = NSDecimalNumber(decimal: total).doubleValue
        var slices: [CategorySlice] = []

        for (name, transactions) in grouped {
            let amount = transactions.reduce(Decimal.zero) { $0 + max($1.amount, 0) }
            let category = categories.first { $0.name == name }
            let color = Color(hex: category?.colorHex ?? "#6C757D")
            let amountDouble = NSDecimalNumber(decimal: amount).doubleValue
            slices.append(
                CategorySlice(
                    id: name,
                    name: name,
                    symbol: category?.symbol ?? "questionmark.circle.fill",
                    color: color,
                    amount: amountDouble,
                    ratio: totalDouble > 0 ? amountDouble / totalDouble : 0
                )
            )
        }

        return slices.sorted { $0.amount > $1.amount }
    }

    /// Một cột trong biểu đồ theo ngày.
    struct DailyPoint: Identifiable {
        let id: String
        let date: Date
        let amount: Double
    }

    private var dailyPoints: [DailyPoint] {
        let grouped = Dictionary(grouping: monthTransactions) { $0.date.beginningOfDay }
        var points: [DailyPoint] = []

        for (date, transactions) in grouped {
            let amount = transactions.reduce(Decimal.zero) { $0 + max($1.amount, 0) }
            points.append(
                DailyPoint(
                    id: date.dayKey,
                    date: date,
                    amount: NSDecimalNumber(decimal: amount).doubleValue
                )
            )
        }

        return points.sorted { $0.date < $1.date }
    }
}
