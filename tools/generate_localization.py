"""Nguồn chân lý cho bản dịch EN/VI của app.

Sinh ra `ExpenseTracker/Localizable.xcstrings` (String Catalog của Xcode).
Dùng khi thêm/sửa chuỗi: sửa dict trong file này rồi chạy lại script.

    python tools/generate_localization.py

Kiểm tra thêm: script sẽ đối chiếu key trong Swift với catalog và báo lệch.
"""
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT = os.path.join(ROOT, "ExpenseTracker", "Localizable.xcstrings")
SWIFT_DIR = os.path.join(ROOT, "ExpenseTracker")

SOURCE_LANGUAGE = "en"

# key -> (English, Vietnamese)
STRINGS = {
    # ---------------- Tabs ----------------
    "tab.transactions": ("Transactions", "Giao dịch"),
    "tab.stats": ("Stats", "Thống kê"),
    "tab.budget": ("Budget", "Ngân sách"),
    "tab.settings": ("Settings", "Cài đặt"),

    # ---------------- Common ----------------
    "common.save": ("Save", "Lưu"),
    "common.cancel": ("Cancel", "Huỷ"),
    "common.done": ("Done", "Xong"),
    "common.delete": ("Delete", "Xoá"),
    "common.add": ("Add", "Thêm"),
    "common.previousMonth": ("Previous month", "Tháng trước"),
    "common.nextMonth": ("Next month", "Tháng sau"),

    # ---------------- Transactions ----------------
    "transactions.title": ("Transactions", "Giao dịch"),
    "transactions.totalSpent": ("Total spent", "Tổng chi"),
    "transactions.dailyAverage": ("Daily average", "Trung bình mỗi ngày"),
    "transactions.searchPrompt": ("Search notes or categories", "Tìm theo ghi chú hoặc danh mục"),
    "transactions.filterAll": ("All", "Tất cả"),
    "transactions.filterCategory": ("Category", "Danh mục"),
    "transactions.empty.title": ("No spending yet", "Chưa có chi tiêu nào"),
    "transactions.empty.message": (
        "Add your first transaction to see where your money goes.",
        "Thêm giao dịch đầu tiên để biết tiền của bạn đi đâu.",
    ),
    "transactions.empty.action": ("Add a transaction", "Thêm giao dịch"),
    "transactions.empty.search": ("Nothing matches", "Không có kết quả"),
    "transactions.empty.searchMessage": (
        "Try another keyword or clear the filter.",
        "Thử từ khoá khác hoặc bỏ bộ lọc.",
    ),
    "transactions.delete.title": ("Delete this transaction?", "Xoá giao dịch này?"),
    "transactions.delete.message": ("This can't be undone.", "Thao tác này không thể hoàn tác."),
    "transactions.add.title": ("New transaction", "Giao dịch mới"),
    "transactions.edit.title": ("Edit transaction", "Sửa giao dịch"),
    "transactions.type.expense": ("Expense", "Chi tiêu"),
    "transactions.type.income": ("Income", "Thu nhập"),
    "transactions.amount": ("Amount", "Số tiền"),
    "transactions.category": ("Category", "Danh mục"),
    "transactions.noCategory": ("No category", "Chưa có danh mục"),
    "transactions.details": ("Details", "Chi tiết"),
    "transactions.date": ("Date", "Ngày"),
    "transactions.note": ("Note", "Ghi chú"),
    "transactions.notePlaceholder": ("Optional note", "Ghi chú (không bắt buộc)"),
    "transactions.amountPlaceholder": ("0", "0"),

    # ---------------- Stats ----------------
    "stats.title": ("Stats", "Thống kê"),
    "stats.chart.byCategory": ("By category", "Theo danh mục"),
    "stats.chart.byDay": ("By day", "Theo ngày"),
    "stats.empty": ("Nothing to chart yet", "Chưa có gì để vẽ"),
    "stats.empty.hint": (
        "Add a transaction and the breakdown appears here.",
        "Thêm một giao dịch và biểu đồ sẽ hiện ở đây.",
    ),
    "stats.total": ("Total", "Tổng"),
    "stats.spent": ("Spent", "Đã chi"),
    "stats.breakdown": ("Breakdown", "Phân tích theo danh mục"),
    "stats.vsLastMonth": ("vs. last month", "so với tháng trước"),
    "stats.noLastMonth": ("No data for last month", "Chưa có dữ liệu tháng trước"),
    "stats.up": ("%@ more than last month", "%@ nhiều hơn tháng trước"),
    "stats.down": ("%@ less than last month", "%@ ít hơn tháng trước"),
    "stats.flat": ("%@ level with last month", "%@ bằng tháng trước"),

    # ---------------- Export CSV ----------------
    "csv.header": ("Date,Category,Note,Amount", "Ngày,Danh mục,Ghi chú,Số tiền"),

    # ---------------- Budget ----------------
    "budget.title": ("Budget", "Ngân sách"),
    "budget.total.title": ("Monthly budget", "Ngân sách tháng"),
    "budget.total.set": ("Set a monthly limit", "Đặt hạn mức cho tháng"),
    "budget.total.setHint": (
        "Pick a limit and watch the bar move as you spend.",
        "Chọn một hạn mức và theo dõi thanh tiến trình khi bạn chi tiêu.",
    ),
    "budget.remaining": ("Remaining", "Còn lại"),
    "budget.over": ("Over by", "Vượt"),
    "budget.categories.title": ("Category limits", "Hạn mức theo danh mục"),
    "budget.categories.empty": ("No category limits yet", "Chưa có hạn mức theo danh mục"),
    "budget.categories.emptyHint": (
        "Limit a category to spot overspending early.",
        "Đặt hạn mức cho một danh mục để phát hiện chi tiêu vượt sớm.",
    ),
    "budget.add": ("Add category limit", "Thêm hạn mức"),
    "budget.editor.new": ("New limit", "Hạn mức mới"),
    "budget.editor.edit": ("Edit limit", "Sửa hạn mức"),
    "budget.editor.limit": ("Limit", "Hạn mức"),
    "budget.editor.month": ("Month", "Tháng"),
    "budget.editor.category": ("Category", "Danh mục"),
    "budget.editor.conflict": (
        "A limit for this month and category already exists.",
        "Đã có hạn mức cho tháng và danh mục này.",
    ),
    "budget.daysLeft.one": ("%d day left", "Còn %d ngày"),
    "budget.daysLeft.other": ("%d days left", "Còn %d ngày"),

    # ---------------- Settings ----------------
    "settings.title": ("Settings", "Cài đặt"),
    "settings.section.appearance": ("Appearance", "Giao diện"),
    "settings.appearance.system": ("System", "Hệ thống"),
    "settings.appearance.light": ("Light", "Sáng"),
    "settings.appearance.dark": ("Dark", "Tối"),
    "settings.section.language": ("Language", "Ngôn ngữ"),
    "settings.section.currency": ("Currency", "Tiền tệ"),
    "settings.section.data": ("Data", "Dữ liệu"),
    "settings.data.transactions": ("Transactions", "Giao dịch"),
    "settings.data.categories": ("Categories", "Danh mục"),
    "settings.data.budgets": ("Budgets", "Hạn mức"),
    "settings.data.sample": ("Load sample data", "Thêm dữ liệu mẫu"),
    "settings.data.sampleHint": (
        "Add about 25 sample transactions to explore the app.",
        "Thêm khoảng 25 giao dịch mẫu để khám phá app.",
    ),
    "settings.data.erase": ("Erase all data", "Xoá toàn bộ dữ liệu"),
    "settings.data.eraseTitle": ("Erase all data?", "Xoá toàn bộ dữ liệu?"),
    "settings.data.eraseMessage": (
        "Every transaction, budget and custom category is removed. This can't be undone.",
        "Toàn bộ giao dịch, hạn mức và danh mục tùy chỉnh sẽ bị xoá. Không thể hoàn tác.",
    ),
    "settings.data.eraseConfirm": ("Erase everything", "Xoá tất cả"),
    "settings.section.backup": ("Backup & restore", "Sao lưu & khôi phục"),
    "settings.backup.json": ("Export full backup (JSON)", "Sao lưu toàn bộ (JSON)"),
    "settings.backup.csv": ("Export transactions (CSV)", "Xuất giao dịch (CSV)"),
    "settings.backup.import": ("Import from JSON", "Nhập từ JSON"),
    "settings.backup.hint": (
        "JSON keeps everything so you can restore it later. CSV opens in Excel or Numbers.",
        "JSON chứa mọi thứ để khôi phục sau. CSV mở bằng Excel hoặc Numbers.",
    ),
    "settings.section.categories": ("Categories", "Danh mục"),
    "settings.categories.manage": ("Manage categories", "Quản lý danh mục"),
    "settings.section.about": ("About", "Thông tin"),
    "settings.about.version": ("Version", "Phiên bản"),
    "settings.about.storage": ("Stored on this device", "Lưu trên thiết bị này"),
    "settings.about.privacy": (
        "Everything stays on your iPhone. The app never sends data anywhere.",
        "Mọi dữ liệu nằm trên iPhone của bạn. App không gửi dữ liệu đi bất cứ đâu.",
    ),
    "settings.import.success": ("Imported %d transactions.", "Đã nhập %d giao dịch."),
    "settings.import.failed": (
        "Couldn't read that file. Choose a JSON backup exported by this app.",
        "Không đọc được file. Hãy chọn file JSON do app này xuất ra.",
    ),
    "settings.export.failed": ("Couldn't export the file. Try again.", "Không xuất được file. Hãy thử lại."),

    # ---------------- Category manager ----------------
    "categories.title": ("Categories", "Danh mục"),
    "categories.add": ("New category", "Danh mục mới"),
    "categories.edit": ("Edit category", "Sửa danh mục"),
    "categories.name": ("Name", "Tên"),
    "categories.namePlaceholder": ("e.g. Coffee", "Ví dụ: Cà phê"),
    "categories.icon": ("Icon", "Biểu tượng"),
    "categories.color": ("Color", "Màu"),
    "categories.builtin": ("Built-in", "Mặc định"),
    "categories.count.one": ("%d transaction", "%d giao dịch"),
    "categories.count.other": ("%d transactions", "%d giao dịch"),
    "categories.deleteConfirm": ("Delete category?", "Xoá danh mục?"),
    "categories.deleteMessage": (
        "Transactions in this category are kept but lose their category.",
        "Giao dịch thuộc danh mục này vẫn được giữ nhưng sẽ mất danh mục.",
    ),

    # ---------------- Built-in category names ----------------
    "category.food": ("Food & drink", "Ăn uống"),
    "category.transport": ("Transport", "Đi lại"),
    "category.shopping": ("Shopping", "Mua sắm"),
    "category.bills": ("Bills", "Hóa đơn"),
    "category.health": ("Health", "Sức khoẻ"),
    "category.entertainment": ("Entertainment", "Giải trí"),
    "category.education": ("Education", "Học tập"),
    "category.home": ("Home", "Nhà cửa"),
    "category.gifts": ("Gifts", "Quà tặng"),
    "category.income": ("Income", "Thu nhập"),
    "category.other": ("Other", "Khác"),
}


def build_catalog() -> dict:
    strings = {}
    for key, (en, vi) in sorted(STRINGS.items()):
        strings[key] = {
            "comment": f"Localized string: {key}",
            "extractionState": "manual",
            "localizations": {
                SOURCE_LANGUAGE: {
                    "stringUnit": {"state": "translated", "value": en}
                },
                "vi": {
                    "stringUnit": {"state": "translated", "value": vi}
                },
            },
        }
    return {
        "sourceLanguage": SOURCE_LANGUAGE,
        "strings": strings,
        "version": "1.0",
    }


def swift_keys() -> set:
    """Thu thập key được dùng trong code Swift.

    Hai nguồn:
    1. String literal dạng "dot.separated.key" — dùng cho `appState.string(...)`.
    2. `L.<tên>` — enum `L` trong Shared/Localization.swift là nguồn chân lý,
       nên key của nó luôn được coi là đã dùng.
    """
    literal = re.compile(r'"([a-z][a-z0-9]*(?:\.[a-zA-Z0-9]+)+)"')
    enum_member = re.compile(r'\bL\.(\w+)')
    keys = set()
    usages = []

    for dirpath, dirnames, filenames in os.walk(SWIFT_DIR):
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        for name in filenames:
            if not name.endswith(".swift"):
                continue
            with open(os.path.join(dirpath, name), "r", encoding="utf-8") as handle:
                source = handle.read()
            for candidate in literal.findall(source):
                if candidate.startswith(("http", "settings.currencyCode", "settings.selectedMonth")):
                    continue
                if candidate in STRINGS:
                    keys.add(candidate)
            # `L.xxx` chỉ tính là dùng ở nơi khác, không tính trong chính
            # file định nghĩa enum L.
            if name != "Localization.swift":
                usages.extend(enum_member.findall(source))

    # `L.xxx` -> tra key trong file Localization.swift.
    localization_path = os.path.join(SWIFT_DIR, "Shared", "Localization.swift")
    with open(localization_path, "r", encoding="utf-8") as handle:
        localization_source = handle.read()

    member_to_key = dict(
        re.findall(
            r'static var (\w+): LocalizedStringKey\s*\{\s*"([^"]+)"\s*\}',
            localization_source,
        )
    )
    for member in usages:
        key = member_to_key.get(member)
        if key:
            keys.add(key)

    return keys


def main() -> int:
    catalog = build_catalog()
    with open(OUT, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(catalog, handle, ensure_ascii=False, indent=2, sort_keys=True)
        handle.write("\n")

    used = swift_keys()
    defined = set(STRINGS.keys())

    missing = sorted(used - defined)
    unused = sorted(defined - used)

    print(f"Da sinh {OUT}")
    print(f"  {len(defined)} chuoi da dinh nghia")

    failed = False

    if missing:
        failed = True
        print(f"FAIL: {len(missing)} key dung trong Swift nhung chua co ban dich:")
        for key in missing:
            print(f"  - {key}")

    if unused:
        print(f"  ({len(unused)} key chua dung: {', '.join(unused[:12])}{'...' if len(unused) > 12 else ''})")

    if failed:
        return 1

    print("OK: moi key trong Swift deu co trong catalog")
    return 0


if __name__ == "__main__":
    sys.exit(main())
