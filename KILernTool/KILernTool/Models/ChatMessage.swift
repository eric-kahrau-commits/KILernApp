import Foundation

enum ChatSender: Equatable {
    case user
    case ai
}

struct ChatMessage: Identifiable {
    let id: UUID = UUID()
    let sender: ChatSender
    let text: String
    let timestamp: Date = Date()
}
