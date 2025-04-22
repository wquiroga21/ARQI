//
//  AIInteractionModel.swift
//  SeniorProject
//
//  Created by William Quiroga on 2/26/25.
//

import Foundation
import Combine

class AIInteractionModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isTyping: Bool = false
    @Published var conversationContext: String = ""
    @Published var error: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let session = URLSession.shared
    private let useMockResponses = Constants.enableDebugMode
    
    // Maximum number of previous messages to consider for context
    private let contextWindowSize = 10
    
    // Response generation options
    enum ResponseStyle {
        case balanced
        case challenging
        case supportive
    }
    
    // Add a message from the user
    func addUserMessage(_ content: String) {
        let message = AIMessage(id: UUID(), content: content, isFromUser: true, timestamp: Date())
        messages.append(message)
        updateContext()
    }
    
    // Add a message from the AI
    func addAIMessage(_ content: String) {
        let message = AIMessage(id: UUID(), content: content, isFromUser: false, timestamp: Date())
        messages.append(message)
        updateContext()
    }
    
    // Generate AI response based on profile settings
    func generateResponse(userInput: String, perspectiveType: String, traits: [String], prioritizeNewIdeas: Bool) {
        isTyping = true
        error = nil
        
        // For simulating in development
        if Constants.enableDebugMode {
            simulateResponse(userInput: userInput, perspectiveType: perspectiveType, traits: traits, prioritizeNewIdeas: prioritizeNewIdeas)
            return
        }
        
        // Create system prompt based on AI personality settings
        let systemPrompt = createSystemPrompt(perspectiveType: perspectiveType, traits: traits, prioritizeNewIdeas: prioritizeNewIdeas)
        
        // Format messages for OpenAI API
        var apiMessages = [["role": "system", "content": systemPrompt]]
        
        // Add conversation history (limited by context window)
        let historyMessages = messages.suffix(contextWindowSize - 1) // -1 to account for the new message
        for message in historyMessages {
            let role = message.isFromUser ? "user" : "assistant"
            apiMessages.append(["role": role, "content": message.content])
        }
        
        // Call OpenAI API
        sendChatCompletionRequest(messages: apiMessages) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isTyping = false
                
                switch result {
                case .success(let response):
                    self.addAIMessage(response)
                case .failure(let err):
                    self.error = "Error: \(err.localizedDescription)"
                    print("OpenAI API error: \(err)")
                }
            }
        }
    }
    
    // Create a system prompt based on AI personality settings
    private func createSystemPrompt(perspectiveType: String, traits: [String], prioritizeNewIdeas: Bool) -> String {
        var prompt = "You are an AI assistant that provides thoughtful, helpful responses. "
        
        // Add perspective type influence
        switch perspectiveType.lowercased() {
        case "challenger":
            prompt += "You tend to challenge assumptions and play devil's advocate to help the user see different perspectives. "
        case "supportive":
            prompt += "You are supportive and affirming, focusing on building upon the user's ideas in a positive way. "
        default: // Balanced
            prompt += "You present balanced perspectives, showing multiple sides of issues without strong bias. "
        }
        
        // Add traits influence
        if !traits.isEmpty {
            prompt += "Your personality exhibits these traits: "
            for (index, trait) in traits.enumerated() {
                if index > 0 {
                    prompt += ", "
                }
                
                switch trait.lowercased() {
                case "strategic":
                    prompt += "strategic thinking (considering long-term implications and planning)"
                case "empathetic":
                    prompt += "empathy (understanding emotions and connecting with people's feelings)"
                case "creative":
                    prompt += "creativity (generating novel ideas and unconventional approaches)"
                case "critical":
                    prompt += "critical thinking (evaluating ideas with careful skepticism and attention to detail)"
                case "analytical":
                    prompt += "analytical thinking (breaking down complex problems into components)"
                case "intuitive":
                    prompt += "intuition (trusting gut feelings and instinctive judgments)"
                case "practical":
                    prompt += "practicality (focusing on what works in real-world applications)"
                case "visionary":
                    prompt += "visionary thinking (imagining future possibilities and opportunities)"
                default:
                    prompt += "balanced perspective (considering multiple viewpoints)"
                }
            }
            prompt += ". "
        }
        
        // Add new ideas preference
        if prioritizeNewIdeas {
            prompt += "You prioritize sharing new, innovative ideas even if they're unconventional. "
        } else {
            prompt += "You focus on developing and refining existing ideas rather than introducing entirely new concepts. "
        }
        
        // Add communication style guidance
        prompt += "Keep your responses conversational, concise, and directly address the user's needs. Avoid unnecessary disclaimers or repetitive phrases."
        
        return prompt
    }
    
    // MARK: - OpenAI Service (Integrated)
    
    func sendChatCompletionRequest(messages: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
        // Use mock responses in debug mode
        if useMockResponses {
            generateMockResponse(for: messages, completion: completion)
            return
        }
        
        guard let url = URL(string: Constants.openAIEndpoint) else {
            completion(.failure(NSError(domain: "OpenAIService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Check if API key is set
        guard Constants.openAIAPIKey != "YOUR_OPENAI_API_KEY" else {
            completion(.failure(NSError(domain: "OpenAIService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API key not configured. Please set a valid API key in Constants.swift"])))
            return
        }
        
        // Prepare request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(Constants.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "model": Constants.defaultModel,
            "messages": messages,
            "max_tokens": Constants.maxTokens,
            "temperature": Constants.temperature,
            "presence_penalty": Constants.presencePenalty,
            "frequency_penalty": Constants.frequencyPenalty
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Send request
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenAIService", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    // Try to get error message
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        completion(.failure(NSError(domain: "OpenAIAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: message])))
                    } else {
                        completion(.failure(NSError(domain: "OpenAIService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    private func generateMockResponse(for messages: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
        // Extract the last user message
        let lastUserMessage = messages.last { $0["role"] == "user" }?["content"] ?? ""
        
        // Find any system message for context
        let systemMessage = messages.first { $0["role"] == "system" }?["content"] ?? ""
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.5...1.5)) {
            // Generate response based on the input
            let response = self.createMockResponse(to: lastUserMessage, systemPrompt: systemMessage)
            completion(.success(response))
        }
    }
    
    private func createMockResponse(to userMessage: String, systemPrompt: String) -> String {
        // Default mock responses
        let defaultResponses = [
            "That's an interesting point. I'd like to explore that further with you.",
            "I understand where you're coming from. Let me offer a different perspective.",
            "Based on what you've shared, I think we should consider a few different angles.",
            "I appreciate you sharing that. I'm wondering what led you to that conclusion?",
            "That's a complex topic. There are several ways we could approach this."
        ]
        
        // Question detection
        if userMessage.contains("?") {
            return "That's a good question. While I don't have access to real-time data in this demo mode, I can tell you that " + defaultResponses.randomElement()!.lowercased()
        }
        
        // Greeting detection
        if userMessage.lowercased().contains("hello") || userMessage.lowercased().contains("hi") {
            return "Hello! I'm your AI assistant running in demo mode. How can I help you today?"
        }
        
        // Help request detection
        if userMessage.lowercased().contains("help") {
            return "I'd be happy to help! Please keep in mind I'm running in demo mode, so my responses are pre-generated. In the full version, I'll be able to provide more personalized assistance."
        }
        
        // Default response if nothing specific is detected
        return defaultResponses.randomElement()!
    }
    
    // Simulate response for development/testing
    private func simulateResponse(userInput: String, perspectiveType: String, traits: [String], prioritizeNewIdeas: Bool) {
        let responseStyle: ResponseStyle
        
        switch perspectiveType.lowercased() {
        case "challenger":
            responseStyle = .challenging
        case "supportive":
            responseStyle = .supportive
        default:
            responseStyle = .balanced
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let response = self.createSimulatedResponse(
                to: userInput,
                style: responseStyle,
                traits: traits,
                prioritizeNewIdeas: prioritizeNewIdeas
            )
            
            self.addAIMessage(response)
            self.isTyping = false
        }
    }
    
    // Simulate AI response based on user input and AI settings
    private func createSimulatedResponse(to userInput: String, style: ResponseStyle, traits: [String], prioritizeNewIdeas: Bool) -> String {
        var response = ""
        
        // Base response on style
        switch style {
        case .challenging:
            response += "That's an interesting perspective. Have you considered an alternative view? "
        case .supportive:
            response += "I appreciate your insight. Building on that idea, "
        case .balanced:
            response += "Let me think about that. On one hand, "
        }
        
        // Add influence from traits
        if !traits.isEmpty {
            let trait = traits.first!.lowercased()
            
            switch trait {
            case "strategic":
                response += "From a strategic perspective, it's worth considering the long-term implications. "
            case "empathetic":
                response += "If we look at this from multiple perspectives, we might gain deeper understanding. "
            case "creative":
                response += "This opens up creative possibilities like reimagining the approach. "
            case "analytical":
                response += "Breaking this down analytically reveals several key components to evaluate. "
            default:
                response += "Looking at the underlying patterns helps clarify the situation. "
            }
        }
        
        // Add new ideas influence
        if prioritizeNewIdeas {
            response += "Here's a novel approach that might be worth exploring further."
        } else {
            response += "Let's focus on refining this existing idea to strengthen it."
        }
        
        return response
    }
    
    // Update conversation context for AI memory
    private func updateContext() {
        // Get last few messages for context
        let recentMessages = messages.suffix(contextWindowSize)
        
        // Format the context
        conversationContext = recentMessages.map { message in
            let role = message.isFromUser ? "User" : "AI"
            return "\(role): \(message.content)"
        }.joined(separator: "\n")
    }
    
    // Save the current conversation to Firestore
    func saveConversation(userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let firestoreManager = FirestoreManager()
        firestoreManager.saveConversation(userId: userId, messages: messages, completion: completion)
    }
    
    // Load a conversation from Firestore
    func loadConversation(userId: String, conversationId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let firestoreManager = FirestoreManager()
        firestoreManager.getConversation(userId: userId, conversationId: conversationId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let loadedMessages):
                self.messages = loadedMessages
                self.updateContext()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Clear the conversation
    func clearConversation() {
        messages.removeAll()
        conversationContext = ""
        error = nil
    }
}

// Message model for AI interactions
struct AIMessage: Identifiable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}
