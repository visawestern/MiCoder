import Foundation

enum ProviderConnectionStatusLogic {
    static func endpointLabel(
        selectedID: String,
        serverProviderIDs: [String],
        serverConnected: Bool,
        serverHost: String,
        serverPort: Int
    ) -> String {
        if serverConnected && serverProviderIDs.contains(selectedID) {
            return "\(serverHost):\(serverPort)"
        }
        return selectedID
    }

    static func isConnected(
        selectedID: String,
        serverProviderIDs: [String],
        serverConnected: Bool,
        autoFreeID: String,
        autoFreeReady: Bool,
        webConnected: Bool?,
        localEnabled: Bool,
        customReady: Bool,
        remembered: Bool?
    ) -> Bool {
        guard !selectedID.isEmpty else { return false }
        if serverProviderIDs.contains(selectedID) {
            return serverConnected
        }
        if selectedID == autoFreeID {
            return autoFreeReady
        }
        if selectedID.hasPrefix("web:") {
            return webConnected == true
        }
        if let remembered {
            return remembered
        }
        if localEnabled || customReady {
            return true
        }
        return false
    }
}
