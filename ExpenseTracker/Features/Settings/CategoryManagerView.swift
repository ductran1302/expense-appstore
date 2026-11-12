import SwiftUI
import SwiftData

struct CategoryManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var editingCategory: ExpenseCategory?
    @State private var isAdding = false
    @State private var isShowingDeleteAlert = false
    @State private var pendingDeletions: [ExpenseCategory] = []

    var body: some View {
        List {
            ForEach(categories) { category in
                Button {
                    editingCategory = category
                } label: {
                    row(category)
                }
                .buttonStyle(.plain)
            }
            .onMove(perform: move)
            .onDelete(perform: delete)

            Button {
                isAdding = true
            } label: {
                Label(L.categoriesAdd, systemImage: "plus.circle.fill")
            }
        }
        .navigationTitle(L.categoriesTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(isPresented: $isAdding) {
            CategoryEditorView(category: nil)
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorView(category: category)
        }
        .alert(L.categoriesDeleteConfirm, isPresented: $isShowingDeleteAlert) {
            Button(L.delete, role: .destructive) {
                for category in pendingDeletions {
                    context.delete(category)
                }
                try? context.save()
                pendingDeletions = []
            }
            Button(L.cancel, role: .cancel) {
                pendingDeletions = []
            }
        } message: {
            Text(L.categoriesDeleteMessage)
        }
    }

    private func row(_ category: ExpenseCategory) -> some View {
        HStack(spacing: Spacing.md) {
            CategoryIconView(category: category, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(appState.categoryName(category))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(L.categoryCount(
                    category.transactions.count,
                    bundle: appState.localizationBundle,
                    locale: appState.locale
                ))
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            if category.isBuiltIn {
                Text(L.categoriesBuiltin)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(AppTheme.fill, in: Capsule())
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, category) in reordered.enumerated() {
            category.sortOrder = index
        }
        try? context.save()
    }

    private func delete(at offsets: IndexSet) {
        // Danh mục mặc định được giữ lại để app luôn có danh mục dự phòng.
        pendingDeletions = offsets
            .map { categories[$0] }
            .filter { !$0.isBuiltIn }
        guard !pendingDeletions.isEmpty else { return }
        isShowingDeleteAlert = true
    }
}

/// Biểu tượng danh mục, tự đổi độ tương phản theo giao diện.
struct CategoryIconView: View {
    let category: ExpenseCategory
    var size: CGFloat = 40

    @Environment(\.colorScheme) private var colorScheme

    private var tint: CategoryColor {
        CategoryColor(hex: category.colorHex, scheme: colorScheme)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.soft)
                .frame(width: size, height: size)
            Image(systemName: category.symbol)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(tint.base)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Editor

struct CategoryEditorView: View {
    let category: ExpenseCategory?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var name = ""
    @State private var symbol = "tag.fill"
    @State private var color = Color(hex: "#2F6BFF")
    @State private var didLoad = false

    /// Bảng màu gợi ý.
    private let palette: [String] = [
        "#FF6B35", "#F7931E", "#FDCB58", "#2ECC71", "#06D6A0",
        "#4ECDC4", "#45AAF2", "#118AB2", "#2F6BFF", "#5F27CD",
        "#A06CD5", "#E84393", "#EF476F", "#D63031", "#6C757D"
    ]

    private let symbols: [String] = [
        "fork.knife", "car.fill", "bag.fill", "bolt.fill", "heart.fill",
        "gamecontroller.fill", "book.fill", "house.fill", "gift.fill",
        "airplane", "pawprint.fill", "cup.and.saucer.fill", "banknote.fill",
        "creditcard.fill", "wifi", "dumbbell.fill", "bicycle", "bus.fill",
        "tshirt.fill", "drop.fill", "leaf.fill", "phone.fill", "questionmark.circle.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section(L.categoriesName) {
                    TextField(L.categoriesNamePlaceholder, text: $name)
                        .accessibilityLabel(L.categoriesName)
                }

                Section(L.categoriesIcon) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: 6), spacing: Spacing.md) {
                        ForEach(symbols, id: \.self) { item in
                            Button {
                                symbol = item
                            } label: {
                                Image(systemName: item)
                                    .font(.system(size: 17, weight: .semibold))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(symbol == item ? color : AppTheme.surfaceRaised)
                                    )
                                    .foregroundStyle(symbol == item ? .white : AppTheme.textPrimary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }

                Section(L.categoriesColor) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: 5), spacing: Spacing.md) {
                        ForEach(palette, id: \.self) { hex in
                            Button {
                                color = Color(hex: hex)
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if color.hexString == hex.uppercased() {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(hex)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
            .navigationTitle(category == nil ? L.categoriesAdd : L.categoriesEdit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.save) { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true

        if let category {
            name = category.name
            symbol = category.symbol
            color = Color(hex: category.colorHex)
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let category {
            category.name = trimmed
            category.symbol = symbol
            category.colorHex = color.hexString
        } else {
            let newCategory = ExpenseCategory(
                name: trimmed,
                symbol: symbol,
                colorHex: color.hexString,
                isBuiltIn: false,
                sortOrder: categoriesMaxOrder() + 1
            )
            context.insert(newCategory)
        }

        try? context.save()
        dismiss()
    }

    private func categoriesMaxOrder() -> Int {
        let descriptor = FetchDescriptor<ExpenseCategory>(
            sortBy: [SortDescriptor(\ExpenseCategory.sortOrder, order: .reverse)]
        )
        let all = (try? context.fetch(descriptor)) ?? []
        return all.first?.sortOrder ?? 0
    }
}
