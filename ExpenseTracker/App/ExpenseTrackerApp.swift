import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    @State private var appState = AppState()

    private let container: ModelContainer

    init() {
        let schema = Schema([
            ExpenseTransaction.self,
            ExpenseCategory.self,
            MonthlyBudget.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Store hỏng: chạy tạm bằng store in-memory để app không crash.
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                container = try ModelContainer(for: schema, configurations: [fallback])
            } catch {
                fatalError("Khong khoi tao duoc ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
        .modelContainer(container)
    }
}
