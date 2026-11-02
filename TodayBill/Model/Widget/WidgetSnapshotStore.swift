import Foundation

/// 스냅샷을 App Group 컨테이너의 파일 하나로 보관한다.
/// 디렉터리를 주입받으므로 App Group 없이도 테스트할 수 있다.
struct WidgetSnapshotStore {
    static let appGroupIdentifier = "group.Test.TodayBill"
    private static let fileName = "widget-snapshot.json"

    private let directory: URL?

    init(directory: URL?) {
        self.directory = directory
    }

    init() {
        self.init(directory: FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        ))
    }

    private var fileURL: URL? {
        directory?.appendingPathComponent(Self.fileName)
    }

    /// 실패는 삼킨다. 위젯이 갱신되지 않는 것이지 앱이 망가지는 것은 아니다.
    @discardableResult
    func write(_ snapshot: BillWidgetSnapshot) -> Bool {
        guard let fileURL else { return false }
        do {
            try JSONEncoder().encode(snapshot).write(to: fileURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// A failed read never deletes the path: it may already contain a newer atomic write.
    func read() -> BillWidgetSnapshot? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        do {
            return try JSONDecoder().decode(BillWidgetSnapshot.self, from: data)
        } catch {
            return nil
        }
    }
}
