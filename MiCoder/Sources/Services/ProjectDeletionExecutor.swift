import Foundation

enum ProjectDeletionExecutor {
    @discardableResult
    static func deleteProjectData(
        projectPath: String,
        fileManager: FileManager = .default
    ) -> Bool {
        guard ProjectDeletionLogic.canDeleteProjectData(at: projectPath) else { return false }
        let root = ProjectDatabaseLocator.projectMimoDir(projectPath: projectPath).standardizedFileURL
        let projectRoot = URL(fileURLWithPath: projectPath).standardizedFileURL.path
        guard root.path.hasPrefix(projectRoot + "/") else { return false }
        // The executor still limits every deletion to this exact `.micoder` root.
        return removeContents(of: root, fileManager: fileManager)
    }

    private static func removeContents(of root: URL, fileManager: FileManager) -> Bool {
        guard fileManager.fileExists(atPath: root.path) else { return true }
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) else { return false }
        var urls: [URL] = []
        for case let url as URL in enumerator {
            urls.append(url)
        }
        let filesFirst = urls.sorted { lhs, rhs in
            lhs.pathComponents.count > rhs.pathComponents.count
        }
        for chunk in ProjectDeletionLogic.chunks(for: filesFirst) {
            for url in chunk {
                try? fileManager.removeItem(at: url)
            }
        }
        try? fileManager.removeItem(at: root)
        return !fileManager.fileExists(atPath: root.path)
    }
}
