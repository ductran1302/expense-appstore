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
                    Label("Giao dịch", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(Tab.transactions)

            StatsView()
                .tabItem {
                    Label("Thống kê", systemImage: "chart.pie.fill")
                }
                .tag(Tab.stats)

            BudgetView()
                .tabItem {
                    Label("Ngân sách", systemImage: "target")
                }
                .tag(Tab.budget)

            SettingsView()
                .tabItem {
                    Label("Cài đặt", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .task {
            guard !didSeed else { return }
            didSeed = true
            SeedData.createDefaultCategories(in: context)
        }
    }
}
