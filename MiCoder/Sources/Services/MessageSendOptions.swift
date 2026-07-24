import Foundation

struct MessageSendOptions: Equatable {
    let agent: String
    let modelID: String?
    let providerID: String?
    let variant: String?
    let messageID: String?
    let permission: [String: String]?

    init(agent: String, modelID: String? = nil, providerID: String? = nil, variant: String? = nil, messageID: String? = nil, permission: [String: String]? = nil) {
        self.agent = agent
        self.modelID = modelID
        self.providerID = providerID
        self.variant = variant
        self.messageID = messageID
        self.permission = permission
    }

    func requestBody(parts: [[String: Any]]) -> [String: Any] {
        var body: [String: Any] = [
            "parts": parts,
            "agent": agent
        ]
        if let modelID, !modelID.isEmpty, let providerID, !providerID.isEmpty {
            body["model"] = [
                "providerID": providerID,
                "modelID": modelID
            ]
        }
        if let variant {
            body["variant"] = variant
        }
        if let messageID, !messageID.isEmpty {
            body["messageID"] = messageID
        }
        if let permission, !permission.isEmpty {
            body["permission"] = permission
        }
        return body
    }
}
