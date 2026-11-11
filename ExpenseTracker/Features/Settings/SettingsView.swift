import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState

    @Query private var categories: [ExpenseCategory]
    @Query private var transactions: [ExpenseTransaction]
    @Query private var budgets: [MonthlyBudget]

    @State private var isExportingJSON = false
    @State private var isExportingCSV = false
    @State private var isImporting = false
    @State private var exportDocument = ExportDocument(data: Data())
    @State private var isShowingImportAlert = false
    @State private var importMessage = ""
    @State private var isShowingClearAlert = false
    @State private var isShowingSampleAlert = false

    var body: some View {
        NavigationStack {
            List {
                currencySection
                dataSection
                backupSection
                categorySection
                aboutSection
            }
            .navigationTitle("Cài đặt")
            .navigationBarTitleDisplayMode(.inline)
            .fileExporter(
                isPresented: $isExportingJSON,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "expense-tracker-backup"
            ) { result in
                handleExportResult(result)
            }
            .fileExporter(
                isPresented: $isExportingCSV,
                document: exportDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "expense-tracker-giao-dich"
            ) { result in
                handleExportResult(result)
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportResult(result)
            }
            .alert("Nhập dữ liệu", isPresented: $isShowingImportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importMessage)
            }
            .alert("Xoá toàn bộ dữ liệu?", isPresented: $isShowingClearAlert) {
                Button("Xoá tất cả", role: .destructive) { clearAllData() }
                Button("Huỷ", role: .cancel) {}
            } message: {
                Text("Toàn bộ giao dịch, hạn mức và danh mục tự tạo sẽ bị xoá. Không thể hoàn tác.")
            }
            .alert("Thêm dữ liệu mẫu?", isPresented: $isShowingSampleAlert) {
                Button("Thêm", role: .none) { addSampleData() }
                Button("Huỷ", role: .cancel) {}
            } message: {
                Text("Sẽ thêm khoảng 25 giao dịch mẫu trong 45 ngày gần nhất để bạn xem thử biểu đồ.")
            }
        }
    }

    // MARK: - Sections

    private var currencySection: some View {
        Section("Tiền tệ") {
            Picker("Loại tiền", selection: appState.currencyBinding) {
                ForEach(CurrencyFormatter.supported) { item in
                    Text(item.name).tag(item.code)
                }
            }
        }
    }

    private var dataSection: some View {
        Section("Dữ liệu") {
            LabeledContent("Giao dịch", value: "\(transactions.count)")
            LabeledContent("Danh mục", value: "\(categories.count)")
            LabeledContent("Hạn mức", value: "\(budgets.count)")

            Button {
                isShowingSampleAlert = true
            } label: {
                Label("Thêm dữ liệu mẫu", systemImage: "wand.and.stars")
            }

            Button(role: .destructive) {
                isShowingClearAlert = true
            } label: {
                Label("Xoá toàn bộ dữ liệu", systemImage: "trash")
            }
        }
    }

    private var backupSection: some View {
        Section {
            Button {
                exportJSON()
            } label: {
                Label("Sao lưu JSON (toàn bộ)", systemImage: "arrow.down.doc")
            }

            Button {
                exportCSV()
            } label: {
                Label("Xuất CSV (giao dịch)", systemImage: "tablecells")
            }

            Button {
                isImporting = true
            } label: {
                Label("Nhập từ file JSON", systemImage: "arrow.up.doc")
            }
        } header: {
            Text("Sao lưu & khôi phục")
        } footer: {
            Text("File JSON chứa toàn bộ danh mục, giao dịch và hạn mức. File CSV mở được bằng Excel hoặc Numbers.")
        }
    }

    private var categorySection: some View {
        Section("Danh mục") {
            NavigationLink {
                CategoryManagerView()
            } label: {
                Label("Quản lý danh mục chi tiêu", systemImage: "tag.fill")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Phiên bản", value: appVersion)
            LabeledContent("Dữ liệu", value: "Trên thiết bị này")
        } header: {
            Text("Thông tin")
        } footer: {
            Text("Toàn bộ dữ liệu được lưu cục bộ trên iPhone. App không gửi thông tin lên internet.")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Actions

    private func exportJSON() {
        let archive = ExpenseArchive.make(
            categories: categories,
            transactions: transactions,
            budgets: budgets
        )
        guard let data = try? archive.jsonData() else { return }
        exportDocument = ExportDocument(data: data)
        isExportingJSON = true
    }

    private func exportCSV() {
        let csv = CSVExporter.makeCSV(transactions: transactions)
        guard let data = csv.data(using: .utf8) else { return }
        exportDocument = ExportDocument(data: data)
        isExportingCSV = true
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            break
        case .failure:
            importMessage = "Không xuất được file. Vui lòng thử lại."
            isShowingImportAlert = true
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let needsStop = url.startAccessingSecurityScopedResource()
            defer {
                if needsStop { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                let archive = try ExpenseArchive.decode(data: data)
                let summary = ArchiveImporter.importArchive(archive, into: context)
                importMessage = summary.summary
            } catch {
                importMessage = "Không đọc được file. Hãy chọn file JSON do app xuất ra."
            }
            isShowingImportAlert = true
        case .failure:
            importMessage = "Không nhập được file. Vui lòng thử lại."
            isShowingImportAlert = true
        }
    }

    private func clearAllData() {
        for transaction in transactions { context.delete(transaction) }
        for budget in budgets { context.delete(budget) }
        for category in categories where !category.isBuiltIn { context.delete(category) }
        try? context.save()
    }

    private func addSampleData() {
        SeedData.createSampleTransactions(in: context)
    }
}
