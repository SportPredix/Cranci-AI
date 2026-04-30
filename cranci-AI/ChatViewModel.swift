import Foundation
import Combine

// MARK: - Chat Session Model
struct ChatSession: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var messages: [Message]
    var createdDate: Date
    var lastModified: Date
    
    func getPreview() -> String {
        messages.first(where: { $0.isUser })?.content ?? "Nuova chat"
    }
}

// MARK: - Message Model
struct Message: Identifiable, Codable {
    let id: UUID = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case content, isUser, timestamp
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(isUser, forKey: .isUser)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.content = try container.decode(String.self, forKey: .content)
        self.isUser = try container.decode(Bool.self, forKey: .isUser)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    init(content: String, isUser: Bool, timestamp: Date) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// MARK: - Chat View Model
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var chatSessions: [ChatSession] = []
    @Published var currentChatID: UUID?
    
    private let apiKey = "0TUVI5LevZyNwde48Mtw72VZv1Tfsn4f"
    private let apiURL = "https://api.mistral.ai/v1/chat/completions"
    private let storageKey = "cranci_ai_chats"
    
    init() {
        loadChats()
        if chatSessions.isEmpty {
            createNewChat()
        } else {
            loadChat(chatSessions.last!.id)
        }
    }
    
    // MARK: - Chat Management
    func createNewChat() {
        let newChat = ChatSession(
            title: "Chat - \(formatDate(Date()))",
            messages: [],
            createdDate: Date(),
            lastModified: Date()
        )
        chatSessions.insert(newChat, at: 0)
        currentChatID = newChat.id
        messages = []
        saveChats()
    }
    
    func loadChat(_ chatID: UUID) {
        if let chat = chatSessions.first(where: { $0.id == chatID }) {
            messages = chat.messages
            currentChatID = chatID
        }
    }
    
    func deleteChat(_ chatID: UUID) {
        chatSessions.removeAll { $0.id == chatID }
        if currentChatID == chatID {
            if let lastChat = chatSessions.first {
                loadChat(lastChat.id)
            } else {
                createNewChat()
            }
        }
        saveChats()
    }
    
    // MARK: - Message Management
    func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespaces)
        guard !userMessage.isEmpty else { return }
        
        messages.append(Message(content: userMessage, isUser: true, timestamp: Date()))
        inputText = ""
        isLoading = true
        updateCurrentChat()
        
        callMistralAPI(userMessage)
    }
    
    private func callMistralAPI(_ message: String) {
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let messages = self.messages.map { msg in
            [
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.content
            ] as [String : Any]
        }
        
        let payload: [String: Any] = [
            "model": "mistral-small-latest",
            "messages": messages
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.messages.append(Message(content: "❌ Errore: \(error.localizedDescription)", isUser: false, timestamp: Date()))
                    self?.updateCurrentChat()
                    return
                }
                
                guard let data = data else { 
                    self?.messages.append(Message(content: "❌ Nessuna risposta dal server", isUser: false, timestamp: Date()))
                    self?.updateCurrentChat()
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    self?.messages.append(Message(content: content, isUser: false, timestamp: Date()))
                } else {
                    self?.messages.append(Message(content: "❌ Errore nella risposta dell'API", isUser: false, timestamp: Date()))
                }
                self?.updateCurrentChat()
            }
        }.resume()
    }
    
    func clearChat() {
        messages.removeAll()
        updateCurrentChat()
    }
    
    // MARK: - Persistence
    private func updateCurrentChat() {
        if let index = chatSessions.firstIndex(where: { $0.id == currentChatID }) {
            chatSessions[index].messages = messages
            chatSessions[index].lastModified = Date()
            saveChats()
        }
    }
    
    private func saveChats() {
        if let encoded = try? JSONEncoder().encode(chatSessions) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadChats() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([ChatSession].self, from: data) {
            chatSessions = decoded.sorted { $0.lastModified > $1.lastModified }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
}