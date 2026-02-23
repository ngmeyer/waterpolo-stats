import UIKit

/// Persists team avatar images to disk, keyed by team UUID.
/// Images are stored as JPEG in Documents/TeamAvatars/.
final class TeamAvatarStore {
    static let shared = TeamAvatarStore()
    private init() {}

    private var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("TeamAvatars", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func fileURL(for teamId: UUID) -> URL {
        directory.appendingPathComponent(teamId.uuidString + ".jpg")
    }

    func save(_ image: UIImage, for teamId: UUID) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: fileURL(for: teamId))
    }

    func load(for teamId: UUID) -> UIImage? {
        let url = fileURL(for: teamId)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func delete(for teamId: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: teamId))
    }
}
