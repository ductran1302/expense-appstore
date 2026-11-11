import SwiftUI
import SwiftData

struct CategoryManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var editingCategory: ExpenseCategory?
    @State private var isAdding = false

    var body: some View {
        List {
            ForEach(categories) { category in
                Button {
                    editingCategory = category
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: category.colorHex).opacity(0.16))
                                .frame(width: 38, height: 38)
                            Image(systemName: category.symbol)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(hex: category.colorHex))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text("\(category.transactions.count) giao dịch")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if category.isBuiltIn {
                            Text("Mặc định")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(.tertiarySystemFill), in: Capsule())
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .onMove(perform: move)
            .onDelete(perform: delete)

            Button {
                isAdding = true
            } label: {
                Label("Thêm danh mục", systemImage: "plus.circle.fill")
            }
        }
        .navigationTitle("Danh mục")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(isPresented: $isAdding) {
            CategoryEditorView(category: nil)
        }
        .sheet(item: $editingCategory) { category in
            CategoryEditorView(category: category)
        }
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
        for index in offsets {
            let category = categories[index]
            // Danh mục mặc định được giữ lại để app luôn có danh mục dự phòng.
            guard !category.isBuiltIn else { continue }
            context.delete(category)
        }
        try? context.save()
    }
}

// MARK: - Editor

struct CategoryEditorView: View {
    let category: ExpenseCategory?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

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
        "airplane", "pawprint.fill", "cup.and.saucer.fill", "gift", "banknote.fill",
        "creditcard.fill", "wifi", "dumbbell.fill", "bicycle", "bus.fill",
        "tshirt.fill", "drop.fill", "leaf.fill", "phone.fill", "questionmark.circle.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Tên") {
                    TextField("Tên danh mục", text: $name)
                }

                Section("Biểu tượng") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                        ForEach(symbols, id: \.self) { item in
                            Button {
                                symbol = item
                            } label: {
                                Image(systemName: item)
                                    .font(.system(size: 17, weight: .semibold))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(symbol == item ? color : Color(.tertiarySystemGroupedBackground))
                                    )
                                    .foregroundStyle(symbol == item ? .white : Color.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Màu") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
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
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let category, !category.transactions.isEmpty {
                    Section {
                        LabeledContent("Số giao dịch", value: "\(category.transactions.count)")
                    } footer: {
                        Text("Khi xoá danh mục, các giao dịch liên quan sẽ được giữ nhưng mất danh mục.")
                    }
                }
            }
            .navigationTitle(category == nil ? "Thêm danh mục" : "Sửa danh mục")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { save() }
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
            let maxOrder = categoriesMaxOrder()
            let newCategory = ExpenseCategory(
                name: trimmed,
                symbol: symbol,
                colorHex: color.hexString,
                isBuiltIn: false,
                sortOrder: maxOrder + 1
            )
            context.insert(newCategory)
        }

        try? context.save()
        dismiss()
    }

    private func categoriesMaxOrder() -> Int {
        let descriptor = FetchDescriptor<ExpenseCategory>(sortBy: [SortDescriptor(\ExpenseCategory.sortOrder, order: .reverse)])
        let all = (try? context.fetch(descriptor)) ?? []
        return all.first?.sortOrder ?? 0
    }
}
