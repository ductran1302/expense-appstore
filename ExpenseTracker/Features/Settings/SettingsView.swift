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
    @State private var activeAlert: SettingsAlert?

    /// Một alert duy nhất cho cả màn hình.
    ///
    /// SwiftUI chỉ kích hoạt `.alert` cuối cùng gắn vào một view, nên các
    /// hộp thoại phải dùng chung một cơ chế thay vì nhiều modifier `.alert`.
    enum SettingsAlert: Identifiable {
        case message(LocalizedStringKey, String)
        case erase
        case sample

        var id: String {
            switch self {
            case .message(let title, _): return "message-\(String(describing: title))"
            case .erase: return "erase"
            case .sample: return "sample"
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                appearanceSection
                languageSection
                currencySection
                dataSection
                backupSection
                categoriesSection
                aboutSection
            }
            .navigationTitle(L.settingsTitle)
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
                defaultFilename: "expense-tracker-transactions"
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
            .alert(item: $activeAlert) { alert in
                switch alert {
                case .message(let title, let message):
                    Alert(title: title, message: Text(message), dismissButton: .default(Text(L.done)))
                case .erase:
                    Alert(
                        title: L.dataEraseTitle,
                        message: Text(L.dataEraseMessage),
                        primaryButton: .destructive(Text(L.dataEraseConfirm)) { clearAllData() },
                        secondaryButton: .cancel(Text(L.cancel))
                    )
                case .sample:
                    Alert(
                        title: L.dataSample,
                        message: Text(L.dataSampleHint),
                        primaryButton: .default(Text(L.add)) { addSampleData() },
                        secondaryButton: .cancel(Text(L.cancel))
                    )
                }
            }
        }
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        Section(L.sectionAppearance) {
            Picker(selection: appState.appearanceBinding) {
                ForEach(AppAppearance.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.lg, bottom: Spacing.sm, trailing: Spacing.lg))
        }
    }

    private var languageSection: some View {
        Section(L.sectionLanguage) {
            Picker(selection: appState.languageBinding) {
                ForEach(AppLanguage.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.lg, bottom: Spacing.sm, trailing: Spacing.lg))
        }
    }

    private var currencySection: some View {
        Section(L.sectionCurrency) {
            Picker(selection: appState.currencyBinding) {
                ForEach(CurrencyFormatter.supported) { item in
                    Text(item.name).tag(item.code)
                }
            }
        }
    }

    private var dataSection: some View {
        Section(L.sectionData) {
            LabeledContent(L.dataTransactions, value: "\(transactions.count)")
            LabeledContent(L.dataCategories, value: "\(categories.count)")
            LabeledContent(L.dataBudgets, value: "\(budgets.count)")

            Button {
                activeAlert = .sample
            } label: {
                Label(L.dataSample, systemImage: "wand.and.stars")
            }

            Button(role: .destructive) {
                activeAlert = .erase
            } label: {
                Label(L.dataErase, systemImage: "trash")
            }
        }
    }

    private var backupSection: some View {
        Section {
            Button {
                exportJSON()
            } label: {
                Label(L.backupJSON, systemImage: "arrow.down.doc")
            }

            Button {
                exportCSV()
            } label: {
                Label(L.backupCSV, systemImage: "tablecells")
            }

            Button {
                isImporting = true
            } label: {
                Label(L.backupImport, systemImage: "arrow.up.doc")
            }
        } header: {
            Text(L.sectionBackup)
        } footer: {
            Text(L.backupHint)
        }
    }

    private var categoriesSection: some View {
        Section(L.sectionCategories) {
            NavigationLink {
                CategoryManagerView()
            } label: {
                Label(L.manageCategories, systemImage: "tag.fill")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent(L.aboutVersion, value: appVersion)
            LabeledContent(L.aboutStorage, value: "")
        } header: {
            Text(L.sectionAbout)
        } footer: {
            Text(L.aboutPrivacy)
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
        let csv = CSVExporter.makeCSV(
            transactions: transactions,
            header: appState.string("csv.header"),
            otherCategory: appState.string("category.other")
        )
        guard let data = csv.data(using: .utf8) else { return }
        exportDocument = ExportDocument(data: data)
        isExportingCSV = true
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        if case .failure = result {
            activeAlert = .message(L.sectionBackup, appState.string("settings.export.failed"))
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
                activeAlert = .message(
                    L.sectionBackup,
                    appState.string("settings.import.success", arguments: summary.transactionsAdded)
                )
            } catch {
                activeAlert = .message(L.sectionBackup, appState.string("settings.import.failed"))
            }
        case .failure:
            activeAlert = .message(L.sectionBackup, appState.string("settings.import.failed"))
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
