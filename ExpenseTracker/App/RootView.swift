import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context

    @State private var selectedTab: Tab = .transactions
    @State private var didSeed = false

    enum Tab: Hashable {
        case transactions
        case stats
        case budget
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TransactionListView()
                .tabItem {
                    Label(L.tabTransactions, systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(Tab.transactions)

            StatsView()
                .tabItem {
                    Label(L.tabStats, systemImage: "chart.pie.fill")
                }
                .tag(Tab.stats)

            BudgetView()
                .tabItem {
                    Label(L.tabBudget, systemImage: "target")
                }
                .tag(Tab.budget)

            SettingsView()
                .tabItem {
                    Label(L.tabSettings, systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(AppTheme.accent)
        .task {
            guard !didSeed else { return }
            didSeed = true
            // Vá khoá bản dịch cho danh mục tạo từ phiên bản trước.
            SeedData.backfillLocalizationKeys(in: context)
            SeedData.createDefaultCategories(in: context)
        }
    }
}
