import UIKit

/// Persists player avatar images to disk, keyed by player UUID.
/// Images are stored as JPEG in Documents/PlayerAvatars/.
final class PlayerAvatarStore {
    static let shared = PlayerAvatarStore()
    private init() {}

    private var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("PlayerAvatars", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func fileURL(for playerId: UUID) -> URL {
        directory.appendingPathComponent(playerId.uuidString + ".jpg")
    }

    func save(_ image: UIImage, for playerId: UUID) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: fileURL(for: playerId))
    }

    func load(for playerId: UUID) -> UIImage? {
        let url = fileURL(for: playerId)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func delete(for playerId: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: playerId))
    }
}
