import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    
    private let apiKey = "0TUVI5LevZyNwde48Mtw72VZv1Tfsn4f"
    private let apiURL = "https://api.mistral.ai/v1/chat/completions"
    
    func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespaces)
        guard !userMessage.isEmpty else { return }
        
        // Aggiungi messaggio utente
        messages.append(Message(content: userMessage, isUser: true, timestamp: Date()))
        inputText = ""
        isLoading = true
        
        // Chiama API Mistral
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
                    return
                }
                
                guard let data = data else { 
                    self?.messages.append(Message(content: "❌ Nessuna risposta dal server", isUser: false, timestamp: Date()))
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
            }
        }.resume()
    }
    
    func clearChat() {
        messages.removeAll()
    }
}

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}