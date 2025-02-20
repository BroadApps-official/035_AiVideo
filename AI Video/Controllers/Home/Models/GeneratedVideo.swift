import Foundation

struct GeneratedVideo: Codable {
    var id: String
    let prompt: String?
    var isFinished: Bool

    var cacheURL: URL {
        return CacheManager.shared.generatedVideosDirectory.appendingPathComponent("\(id).mp4")
    }
}
