import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \ExpenseTransaction.date, order: .reverse) private var allTransactions: [ExpenseTransaction]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var chartMode: ChartMode = .category

    enum ChartMode: String, CaseIterable, Identifiable {
        case category
        case daily

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .category: return L.chartByCategory
            case .daily: return L.chartByDay
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    MonthPicker(month: appState.monthBinding)

                    // Số tổng chi là điểm nhấn: đặt nổi bật, không chia nhỏ
                    // thành nhiều ô bằng nhau.
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(L.statsSpent)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(appState.format(monthTotal))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .contentTransition(.numericText())
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        deltaLine
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle(padding: Spacing.xl)

                    Picker(selection: $chartMode) {
                        ForEach(ChartMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    chart

                    if !categorySlices.isEmpty {
                        breakdown
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L.statsTitle)
        }
    }

    // MARK: - Delta

    @ViewBuilder
    private var deltaLine: some View {
        if previousMonthTotal > 0 {
            let isUp = changeAmount > 0
            let isFlat = changeAmount == 0
            let percent = Int((abs(changeAmount) / previousMonthTotal * 100).rounded())

            HStack(spacing: Spacing.xs) {
                Badge(
                    text: "\(percent)%",
                    systemImage: isFlat ? "arrow.right" : (isUp ? "arrow.up.right" : "arrow.down.right"),
                    tint: isFlat ? AppTheme.textSecondary : (isUp ? AppTheme.expense : AppTheme.success)
                )
                Text(L.vsLastMonth)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(deltaAccessibilityLabel(percent: percent, isUp: isUp, isFlat: isFlat))
        } else {
            Text(L.noLastMonth)
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    /// Nhãn đọc màn hình cho VoiceOver, có định dạng số theo locale đang dùng.
    private func deltaAccessibilityLabel(percent: Int, isUp: Bool, isFlat: Bool) -> String {
        let key: String
        if isFlat {
            key = "stats.flat"
        } else if isUp {
            key = "stats.up"
        } else {
            key = "stats.down"
        }
        return appState.string(key, arguments: "\(percent)%")
    }

    // MARK: - Charts

    @ViewBuilder
    private var chart: some View {
        switch chartMode {
        case .category:
            categoryChart
        case .daily:
            dailyChart
        }
    }

    private var categoryChart: some View {
        VStack(spacing: Spacing.md) {
            if categorySlices.isEmpty {
                emptyChart
            } else {
                ZStack {
                    Chart(categorySlices) { slice in
                        SectorMark(
                            angle: .value("Spent", slice.amount),
                            innerRadius: .ratio(0.68),
                            angularInset: 1.5
                        )
                        .cornerRadius(4)
                        .foregroundStyle(slice.color)
                    }
                    .frame(height: 230)

                    // Tổng nằm trong tâm vòng tròn: trục dữ liệu ở ngay
                    // nơi mắt người dùng đã nhìn.
                    VStack(spacing: 2) {
                        Text(appState.format(monthTotal))
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text(L.statsTotal)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.horizontal, Spacing.xxl)
                }
                .accessibilityLabel(L.statsTotal)
                .accessibilityValue(appState.format(monthTotal))
            }
        }
        .cardStyle(padding: Spacing.lg)
    }

    private var dailyChart: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if dailyPoints.isEmpty {
                emptyChart
            } else {
                Chart(dailyPoints) { point in
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Spent", point.amount)
                    )
                    .foregroundStyle(AppTheme.accent.gradient)
                    .cornerRadius(3)
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(AppTheme.separator)
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
        .cardStyle(padding: Spacing.lg)
    }

    private var emptyChart: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "chart.pie")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(AppTheme.textTertiary)
            Text(L.statsEmpty)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
            Text(L.statsEmptyHint)
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }

    // MARK: - Breakdown

    private var breakdown: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel(text: appState.string("stats.breakdown"))

            ForEach(categorySlices) { slice in
                VStack(spacing: Spacing.xs) {
                    HStack(spacing: Spacing.sm) {
                        Circle()
                            .fill(slice.color)
                            .frame(width: 10, height: 10)
                            .accessibilityHidden(true)

                        Text(slice.name)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textPrimary)

                        Spacer(minLength: Spacing.sm)

                        Text(appState.format(slice.amount))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .monospacedDigit()

                        Text("\(Int(slice.ratio * 100))%")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .monospacedDigit()
                            .frame(width: 42, alignment: .trailing)
                    }

                    ProgressBar(value: slice.ratio, tint: slice.color, height: 4)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "\(slice.name), \(appState.format(slice.amount)), \(Int(slice.ratio * 100))%"
                )
            }
        }
        .cardStyle(padding: Spacing.lg)
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

    /// Một lát cột trong biểu đồ tròn.
    struct CategorySlice: Identifiable {
        let id: String
        let name: String
        let color: Color
        /// Giá trị dùng cho biểu đồ (Charts yêu cầu kiểu số đo lường được).
        let amount: Double
        /// Tỷ lệ 0...1 so với tổng chi tháng.
        let ratio: Double
    }

    private var categorySlices: [CategorySlice] {
        let grouped = Dictionary(grouping: monthTransactions) { transaction in
            transaction.category?.stableKey ?? "other"
        }
        let total = grouped.values.reduce(Decimal.zero) { partial, transactions in
            partial + transactions.reduce(Decimal.zero) { $0 + max($1.amount, 0) }
        }
        guard total > 0 else { return [] }

        let totalDouble = NSDecimalNumber(decimal: total).doubleValue
        var slices: [CategorySlice] = []

        for (key, transactions) in grouped {
            let amount = transactions.reduce(Decimal.zero) { $0 + max($1.amount, 0) }
            let category = categories.first { $0.stableKey == key }
            let categoryColor = CategoryColor(
                hex: category?.colorHex ?? "#6C757D",
                scheme: colorScheme
            )
            let amountDouble = NSDecimalNumber(decimal: amount).doubleValue
            slices.append(
                CategorySlice(
                    id: key,
                    name: category.map { appState.categoryName($0) }
                        ?? appState.string("category.other"),
                    color: categoryColor.base,
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
