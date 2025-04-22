//
//  AIManager.swift
//  SeniorProject
//
//  Created by William Quiroga on 3/7/25.
//

import Foundation
import Combine

class AIManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var serverConnectionStatus: ServerStatus = .unknown
    @Published var availableModels: [String] = ["mistral:latest", "llama2"] // Default list that will be updated
    @Published var isLoadingModels = false
    
    // MARK: - Private Properties
    private var chatHistory: [ChatMessage] = []
    // Change these from private to published
    @Published var serverAddress: String = UserDefaults.standard.string(forKey: "serverAddress") ?? "https://db53-4-43-60-6.ngrok-free.app"
    @Published var currentModel: String = UserDefaults.standard.string(forKey: "currentModel") ?? "mistral:latest"
    @Published var personalityPrompt: String = UserDefaults.standard.string(forKey: "personalityPrompt") ?? "You are a helpful AI assistant. Be helpful, concise, and accurate. IMPORTANT: Never generate or insert text prefixed with 'User:' as that makes it seem like you're speaking for the user. Only respond as yourself, the AI assistant."
    
    private var chatHistoryKey: String
    private let chatType: ChatType
    
    enum ChatType {
        case mainChat
        case debate
        
        var historyKey: String {
            switch self {
            case .mainChat:
                return "ai_main_chat_history"
            case .debate:
                return "ai_debate_chat_history"
            }
        }
    }
    
    // MARK: - Types
    enum ServerStatus {
        case unknown, connected, disconnected, error(String)
    }
    
    // MARK: - Initialization
    init(chatType: ChatType = .mainChat, serverAddress: String? = nil, model: String? = nil, personality: String? = nil) {
        self.chatType = chatType
        self.chatHistoryKey = chatType.historyKey
        
        if let serverAddress = serverAddress {
            self.serverAddress = serverAddress
        } else {
            // Set default server address to ngrok URL if not already set
            // Try the latest ngrok URL first
            let ngrokUrls = [
                "https://db53-4-43-60-6.ngrok-free.app/api/generate",
                "https://6740-4-43-60-6.ngrok-free.app/api/generate"
            ]
            
            // Set a default ngrok URL
            UserDefaults.standard.setValue(ngrokUrls[0], forKey: "serverAddress")
            self.serverAddress = ngrokUrls[0]
            
            // Try each URL in the background
            Task {
                for url in ngrokUrls {
                    self.serverAddress = url
                    self.testServerConnection()
                    // Wait a bit to see if connection succeeds
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    if case .connected = self.serverConnectionStatus {
                        print("AIManager - Successfully connected to \(url)")
                        UserDefaults.standard.setValue(url, forKey: "serverAddress")
                        break
                    }
                }
            }
        }
        if let model = model {
            self.currentModel = model
        } else {
            // Set default model based on chat type
            switch chatType {
            case .mainChat:
                UserDefaults.standard.setValue("mistral:latest", forKey: "currentModel")
                UserDefaults.standard.setValue("mistral:latest", forKey: "ai_model")
                self.currentModel = "mistral:latest"
            case .debate:
                self.currentModel = "gemma3:latest"
            }
        }
        if let personality = personality {
            self.personalityPrompt = personality
        }
        
        // Load chat history from UserDefaults
        loadChatHistoryFromUserDefaults()
        
        // Test connection on init
        testServerConnection()
        
        // Fetch available models after initialization
        Task {
            await fetchAvailableModels()
        }
    }
    
    // MARK: - Public Methods
    /// Configure the AI manager with new settings
    func configure(serverAddress: String? = nil, model: String? = nil, personality: String? = nil) {
        if let serverAddress = serverAddress {
            self.serverAddress = serverAddress
            
            // When server address changes, fetch available models
            Task {
                await fetchAvailableModels()
            }
        }
        if let model = model {
            self.currentModel = model
        }
        if let personality = personality {
            self.personalityPrompt = personality
        }
        
        // Test connection with new settings
        testServerConnection()
    }
    
    /// Generate a response from the AI model
    func generateResponse(userMessage: String, model: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        guard !userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.failure(AIError.emptyInput))
            return
        }
        
        isProcessing = true
        
        // Create a chat message and add it to history
        let message = ChatMessage(id: UUID(), content: userMessage, isUser: true, timestamp: Date())
        chatHistory.append(message)
        // Save to UserDefaults after adding the user message
        saveChatHistoryToUserDefaults()
        
        // Construct the full prompt with history and personality
        let fullPrompt = constructPromptWithHistory(newMessage: userMessage)
        
        // Create the request body
        let requestBody: [String: Any] = [
            "model": model ?? currentModel,
            "prompt": fullPrompt,
            "stream": false
        ]
        
        // Construct the URL from the server address
        var urlString = serverAddress
        
        // Make sure the URL ends with /api/generate
        if !urlString.hasSuffix("/api/generate") {
            if urlString.hasSuffix("/") {
                urlString += "api/generate"
            } else {
                urlString += "/api/generate"
            }
        }
        
        print("AIManager - Using URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            isProcessing = false
            completion(.failure(AIError.invalidURL))
            return
        }
        
        // Create and configure the URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Increase timeout interval to give more time for the request
        request.timeoutInterval = 30
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            isProcessing = false
            completion(.failure(error))
            return
        }
        
        // Make the network request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                
                if let error = error {
                    // Provide better error handling for timeouts
                    if let urlError = error as? URLError, urlError.code == .timedOut {
                        self.serverConnectionStatus = .error("Connection timed out. Check if the AI server at \(self.serverAddress) is running.")
                        print("AIManager - Connection timed out to \(self.serverAddress). The server might be down or the ngrok tunnel expired.")
                        
                        // Suggest trying a different server
                        completion(.failure(AIError.connectionSuggestion(message: "Connection timed out. The server might be down or the ngrok tunnel expired. Try updating to a new ngrok URL in AI Settings.")))
                    } else {
                        self.serverConnectionStatus = .error(error.localizedDescription)
                        print("AIManager - Request failed with error: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(AIError.invalidResponse))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(AIError.serverError(statusCode: httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(AIError.noData))
                    return
                }
                
                do {
                    if let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let responseText = responseJSON["response"] as? String {
                        
                        // Sanitize the response to remove any simulated user messages
                        let sanitizedResponse = self.sanitizeAIResponse(responseText)
                        
                        // Add AI response to chat history
                        let aiMessage = ChatMessage(id: UUID(), content: sanitizedResponse, isUser: false, timestamp: Date())
                        self.chatHistory.append(aiMessage)
                        // Save to UserDefaults after adding AI response
                        self.saveChatHistoryToUserDefaults()
                        
                        completion(.success(sanitizedResponse))
                    } else {
                        completion(.failure(AIError.invalidData))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    /// Get the complete chat history
    func getChatHistory() -> [ChatMessage] {
        return chatHistory
    }
    
    /// Clear the chat history
    func clearHistory(postNotification: Bool = true) {
        // Clear in-memory chat history
        chatHistory.removeAll()
        
        // Clear chat history from UserDefaults
        UserDefaults.standard.removeObject(forKey: chatHistoryKey)
        UserDefaults.standard.synchronize()
        
        // Log the reset for debugging
        print("AIManager - Chat history completely reset")
        
        // Force a check connection to ensure fresh state
        testServerConnection()
        
        // Notify observers that history has been cleared, but only if not called from a notification handler
        if postNotification {
            NotificationCenter.default.post(name: Notification.Name("AIChatHistoryCleared"), object: nil)
        }
    }
    
    /// Save chat history to UserDefaults
    private func saveChatHistoryToUserDefaults() {
        // Convert ChatMessage objects to dictionaries
        let chatHistoryDicts = chatHistory.map { message -> [String: Any] in
            return [
                "id": message.id.uuidString,
                "content": message.content,
                "isUser": message.isUser,
                "timestamp": message.timestamp.timeIntervalSince1970
            ]
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(chatHistoryDicts, forKey: chatHistoryKey)
    }
    
    /// Load chat history from UserDefaults
    private func loadChatHistoryFromUserDefaults() {
        guard let chatHistoryDicts = UserDefaults.standard.array(forKey: chatHistoryKey) as? [[String: Any]] else {
            return
        }
        
        // Convert dictionaries back to ChatMessage objects
        chatHistory = chatHistoryDicts.compactMap { dict -> ChatMessage? in
            guard let idString = dict["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let content = dict["content"] as? String,
                  let isUser = dict["isUser"] as? Bool,
                  let timeInterval = dict["timestamp"] as? TimeInterval else {
                return nil
            }
            
            let timestamp = Date(timeIntervalSince1970: timeInterval)
            return ChatMessage(id: id, content: content, isUser: isUser, timestamp: timestamp)
        }
    }
    
    /// Test if the server is accessible
    func testServerConnection() {
        serverConnectionStatus = .unknown
        
        // Create URL for tags endpoint instead of health
        var urlString = serverAddress
        
        // Extract base URL (remove /api/generate if it exists)
        if urlString.hasSuffix("/api/generate") {
            urlString = String(urlString.dropLast("/api/generate".count))
        }
        
        // Append /api/tags which is a known working endpoint
        if urlString.hasSuffix("/") {
            urlString += "api/tags"
        } else {
            urlString += "/api/tags"
        }
        
        print("AIManager - Testing connection to: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            serverConnectionStatus = .error("Invalid server URL")
            return
        }
        
        var request = URLRequest(url: url)
        // Use a shorter timeout for connection testing
        request.timeoutInterval = 5
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    if let urlError = error as? URLError {
                        switch urlError.code {
                        case .timedOut:
                            self.serverConnectionStatus = .error("Connection timed out. Server may be unavailable.")
                        case .cannotConnectToHost:
                            self.serverConnectionStatus = .error("Cannot connect to server. Check if address is correct.")
                        case .notConnectedToInternet:
                            self.serverConnectionStatus = .error("No internet connection.")
                        default:
                            self.serverConnectionStatus = .error(error.localizedDescription)
                        }
                    } else {
                        self.serverConnectionStatus = .error(error.localizedDescription)
                    }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.serverConnectionStatus = .unknown
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    self.serverConnectionStatus = .connected
                    print("Successfully connected to AI server at \(urlString)")
                    
                    // Since we've already fetched the model list data, we could parse it here
                    if let data = data {
                        do {
                            struct OllamaModelsResponse: Codable {
                                struct Model: Codable {
                                    let name: String
                                }
                                let models: [Model]
                            }
                            
                            // Try to parse the models data
                            let modelsResponse = try JSONDecoder().decode(OllamaModelsResponse.self, from: data)
                            let modelNames = modelsResponse.models.map { $0.name }
                            print("Found \(modelNames.count) models during connection test")
                            
                            // Update models if we don't already have them
                            if self.availableModels.isEmpty || self.availableModels == ["mistral:latest", "llama2"] {
                                self.availableModels = modelNames
                            }
                        } catch {
                            // Just log the error - we've already confirmed the connection works
                            print("Could not parse models during connection test: \(error.localizedDescription)")
                        }
                    }
                } else {
                    self.serverConnectionStatus = .error("Server returned status code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    // Fetch available models from Ollama
    @MainActor
    func fetchAvailableModels() async {
        isLoadingModels = true
        
        // Create OllamaService instance to fetch models
        let ollamaService = OllamaService()
        
        // Configure OllamaService with the current server address
        var baseURL = serverAddress
        if !baseURL.hasSuffix("/api/generate") {
            if baseURL.hasSuffix("/") {
                baseURL += "api/generate"
            } else {
                baseURL += "/api/generate"
            }
        }
        
        await ollamaService.configure(baseURL: baseURL)
        
        do {
            let models = try await ollamaService.fetchAvailableModels()
            self.availableModels = models
            print("AIManager - Updated available models: \(models.joined(separator: ", "))")
            
            // If the current model is not in the available models list and we have models,
            // update to the first available model
            if !models.isEmpty && !models.contains(currentModel) {
                self.currentModel = models[0]
                print("AIManager - Current model not available, switched to: \(models[0])")
                UserDefaults.standard.set(models[0], forKey: "currentModel")
                UserDefaults.standard.set(models[0], forKey: "ai_model")
            }
        } catch {
            print("AIManager - Failed to fetch models: \(error.localizedDescription)")
            // Keep the default models if fetching fails
        }
        
        isLoadingModels = false
    }
    
    /// Add a message to chat history without generating a response
    func addMessageToChat(content: String, isUserMessage: Bool) {
        let message = ChatMessage(
            id: UUID(),
            content: content,
            isUser: isUserMessage,
            timestamp: Date()
        )
        
        chatHistory.append(message)
        saveChatHistoryToUserDefaults()
    }
    
    /// Generate content without affecting chat history
    /// This is used for background operations like generating topics
    func generateContentWithoutChatHistory(prompt: String, model: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.failure(AIError.emptyInput))
            return
        }
        
        isProcessing = true
        let modelToUse = model ?? currentModel
        print("AIManager - Generating content without chat history using model: \(modelToUse)")
        
        // Create the request body - no chat history, just the prompt
        let requestBody: [String: Any] = [
            "model": modelToUse,
            "prompt": prompt,
            "stream": false
        ]
        
        // Use the direct URL we know works from the console output
        let urlString = "https://db53-4-43-60-6.ngrok-free.app/api/generate"
        print("AIManager - Using direct URL for content generation: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            isProcessing = false
            print("AIManager - Invalid URL for content generation")
            completion(.failure(AIError.invalidURL))
            return
        }
        
        // Create and configure the URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        do {
            let requestData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = requestData
            print("AIManager - Sending content generation request to \(urlString)")
        } catch {
            isProcessing = false
            print("AIManager - Failed to serialize request data: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        // Add timeout handling
        let timeoutTimer = DispatchSource.makeTimerSource(queue: .main)
        timeoutTimer.setEventHandler { [weak self] in
            guard let self = self else { return }
            print("AIManager - Content generation request timed out after 30 seconds")
            self.isProcessing = false
            completion(.failure(AIError.timeout))
        }
        timeoutTimer.schedule(deadline: .now() + 30)
        timeoutTimer.resume()
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            timeoutTimer.cancel()
            
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                
                if let error = error {
                    print("AIManager - Content generation error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("AIManager - Content generation invalid response")
                    completion(.failure(AIError.invalidResponse))
                    return
                }
                
                print("AIManager - Content generation response status: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    print("AIManager - Content generation server error: \(httpResponse.statusCode)")
                    if let data = data, let errorText = String(data: data, encoding: .utf8) {
                        print("AIManager - Error response: \(errorText)")
                    }
                    completion(.failure(AIError.serverError(statusCode: httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    print("AIManager - Content generation no data")
                    completion(.failure(AIError.noData))
                    return
                }
                
                do {
                    if let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let responseText = responseJSON["response"] as? String {
                            // Return the response without adding to chat history
                            print("AIManager - Content generation success: received response")
                            completion(.success(responseText))
                        } else {
                            print("AIManager - Content generation success but missing response field. Full JSON: \(responseJSON)")
                            completion(.failure(AIError.invalidData))
                        }
                    } else {
                        print("AIManager - Content generation invalid data format")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("AIManager - Raw response: \(responseString)")
                        }
                        completion(.failure(AIError.invalidData))
                    }
                } catch {
                    print("AIManager - Content generation JSON parsing error: \(error.localizedDescription)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("AIManager - Raw response: \(responseString)")
                    }
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    // MARK: - Private Methods
    private func constructPromptWithHistory(newMessage: String) -> String {
        // Start with clear instructions about role and behavior
        var fullPrompt = personalityPrompt + "\n\n"
        fullPrompt += "IMPORTANT INSTRUCTION: You are ONLY responding as the assistant. DO NOT generate text as if you were the user. DO NOT start your responses with 'User:' or attempt to continue the conversation as the user. Never simulate the user's side of the conversation.\n\n"
        
        // Format conversation history more clearly
        fullPrompt += "--- Conversation History ---\n"
        
        // Add relevant chat history (limit to last X messages to avoid token limits)
        let relevantHistory = chatHistory.suffix(10) // Last 10 messages
        
        // Only include chat history if it exists and is not empty
        if !relevantHistory.isEmpty {
            for message in relevantHistory {
                let role = message.isUser ? "User" : "Assistant"
                fullPrompt += "\(role): \(message.content)\n"
            }
        }
        
        // Add the new message and explicitly indicate where the AI should respond
        fullPrompt += "User: \(newMessage)\n"
        fullPrompt += "Assistant: "
        
        return fullPrompt
    }
    
    private func sanitizeAIResponse(_ response: String) -> String {
        // Split the response by lines to look for "User:" prefixes
        let lines = response.split(separator: "\n")
        var sanitizedLines: [String] = []
        var insideUserBlock = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if this line starts a user block
            if trimmedLine.starts(with: "User:") || trimmedLine == "User" {
                insideUserBlock = true
                continue
            }
            
            // Check if this line might start a new AI/Assistant block
            if trimmedLine.starts(with: "AI:") || trimmedLine.starts(with: "Assistant:") || trimmedLine == "AI" || trimmedLine == "Assistant" {
                insideUserBlock = false
            }
            
            // Only include lines that aren't part of a user block
            if !insideUserBlock {
                sanitizedLines.append(String(line))
            }
        }
        
        // Join the sanitized lines back together
        var sanitized = sanitizedLines.joined(separator: "\n")
        
        // Remove any explicit "AI:" or "Assistant:" prefixes from the beginning
        sanitized = sanitized.replacingOccurrences(of: "^AI:\\s*", with: "", options: .regularExpression)
        sanitized = sanitized.replacingOccurrences(of: "^Assistant:\\s*", with: "", options: .regularExpression)
        
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Error Types
enum AIError: Error, LocalizedError {
    case emptyInput
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case noData
    case invalidData
    case timeout
    case connectionSuggestion(message: String)
    
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Please enter a message"
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .noData:
            return "No data received from server"
        case .invalidData:
            return "Could not parse server response"
        case .timeout:
            return "Connection timed out"
        case .connectionSuggestion(let message):
            return message
        }
    }
}

// MARK: - Enhanced ChatMessage
struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}
