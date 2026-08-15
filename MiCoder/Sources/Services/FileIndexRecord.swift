import Foundation

/// One indexed file's metadata (plan Раздел 7 Блок 3 п.22).
struct FileIndexRecord: Codable, Equatable {
    let path: String
    var hash: String
    var size: Int
    var lastModified: TimeInterval
    var language: String
}
