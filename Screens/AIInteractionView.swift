//
//  AIInteractionView.swift
//  SeniorProject
//
//  Created by William Quiroga on 2/26/25.
//

import SwiftUI
import UIKit

struct AIInteractionView: View {
    @EnvironmentObject var aiProfile: UserAIProfile
    @EnvironmentObject var aiManager: AIManager
    @State private var userInput = ""
    @State private var messages: [ChatMessage] = []
    @State private var showSettings = false
    @State private var scrollToBottom = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    @State private var scrollProxy: ScrollViewProxy?
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header removed as requested
            
            // Error message display
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    Button(action: {
                        self.errorMessage = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            // Chat content
            chatListView
                .layoutPriority(1)
            
            // Input field at bottom
            messageInputField
                .background(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: -1)
        }
        .background(Color.appBackground)
        .ignoresSafeArea(.keyboard, edges: .bottom)  // Add this to ensure content adjusts properly
        .sheet(isPresented: $showSettings) {
            AISettingsView(aiManager: aiManager)
        }
        .onAppear {
            setupAIManager()
            
            // Register for keyboard notifications
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { _ in
                if let lastMessage = self.messages.last {
                    self.scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
            
            // Register for chat history cleared notification
            notificationCenter.addObserver(
                forName: Notification.Name("AIChatHistoryCleared"),
                object: nil,
                queue: .main
            ) { _ in
                self.handleChatHistoryCleared()
            }
            
            // Register for AI settings notification
            notificationCenter.addObserver(
                forName: Notification.Name("OpenAISettings"),
                object: nil,
                queue: .main
            ) { _ in
                self.showSettings = true
            }
            
            // Only show welcome message if no messages exist
            if messages.isEmpty {
                addSystemMessage("Hello! I'm your AI thinking partner. How can I help you today?")
            }
        }
        .onDisappear {
            // Remove specific keyboard observers when view disappears
            NotificationCenter.default.removeObserver(
                self,
                name: UIResponder.keyboardWillHideNotification,
                object: nil
            )
            
            NotificationCenter.default.removeObserver(
                self,
                name: Notification.Name("AIChatHistoryCleared"),
                object: nil
            )
            
            NotificationCenter.default.removeObserver(
                self,
                name: Notification.Name("OpenAISettings"),
                object: nil
            )
        }
    }
    
    private var connectionStatusView: some View {
        HStack(spacing: 4) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            // Status text
            Text(statusText)
                .font(.caption)
                .foregroundColor(Color.secondaryText)
        }
    }
    
    private var statusColor: Color {
        switch aiManager.serverConnectionStatus {
        case .connected:
            return Color.green
        case .disconnected, .error:
            return Color.red
        case .unknown:
            return Color.orange
        }
    }
    
    private var statusText: String {
        switch aiManager.serverConnectionStatus {
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        case .error:
            return "Connection Error"
        case .unknown:
            return "Checking connection..."
        }
    }
    
    private func setupAIManager() {
        // Load settings from UserDefaults
        if let serverAddress = UserDefaults.standard.string(forKey: "ai_server_address"),
           let model = UserDefaults.standard.string(forKey: "ai_model"),
           let personality = UserDefaults.standard.string(forKey: "ai_personality") {
            aiManager.configure(
                serverAddress: serverAddress,
                model: model,
                personality: personality
            )
        } else {
            // Default configuration
            aiManager.configure(
                serverAddress: "https://db53-4-43-60-6.ngrok-free.app/api/generate",
                model: "mistral:latest",
                personality: "You are a friendly AI assistant. Be helpful, concise, and accurate. IMPORTANT: Never generate or insert text prefixed with 'User:' as that makes it seem like you're speaking for the user. Only respond as yourself, the AI assistant."
            )
            
            // Also try alternative URLs if the default one doesn't work
            Task {
                if case .error = aiManager.serverConnectionStatus {
                    // Try alternative URL
                    aiManager.configure(
                        serverAddress: "https://6740-4-43-60-6.ngrok-free.app/api/generate",
                        model: "mistral:latest", 
                        personality: aiManager.personalityPrompt
                    )
                }
            }
        }
        
        // Load chat history if any exists, otherwise start fresh
        messages = aiManager.getChatHistory()
        
        // Only show welcome message if no messages exist
        if messages.isEmpty {
            // This is a brand new conversation
            addSystemMessage("Hello! I'm your AI thinking partner. How can I help you today?")
        }
        // Otherwise, keep the existing conversation history
    }
    
    private func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !aiManager.isProcessing else { return }
        
        let messageText = userInput
        userInput = ""
        
        // Dismiss keyboard
        hideKeyboard()
        
        // Add user message to UI
        let userMessage = ChatMessage(id: UUID(), content: messageText, isUser: true, timestamp: Date())
        messages.append(userMessage)
        
        // Check connection status
        if case .disconnected = aiManager.serverConnectionStatus {
            errorMessage = "Not connected to AI server. Please check your settings."
            return
        }
        
        // Generate AI response
        aiManager.generateResponse(userMessage: messageText) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // AI response is automatically added to chat history
                    let aiMessage = ChatMessage(id: UUID(), content: response, isUser: false, timestamp: Date())
                    messages.append(aiMessage)
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    addSystemMessage("Sorry, I encountered an error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func addSystemMessage(_ content: String) {
        let newMessage = ChatMessage(id: UUID(), content: content, isUser: false, timestamp: Date())
        messages.append(newMessage)
    }
    
    private var messageInputField: some View {
        HStack(spacing: 12) {
            // Text input field
            TextField("Type your message...", text: $userInput, axis: .vertical)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.secondaryCardBackground)
                .cornerRadius(24)
                .submitLabel(.send)
                .lineLimit(5)
                .disabled(aiManager.isProcessing)
                .focused($isInputFocused)
                .font(.system(size: 16))
                .onSubmit {
                    sendMessage()
                }
                .keyboardType(.default)
                .autocorrectionDisabled()
                .autocapitalization(.sentences)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            
            // Send button
            Button(action: sendMessage) {
                Circle()
                    .fill(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiManager.isProcessing 
                          ? Color.secondaryText.opacity(0.3) 
                          : Color.primaryAccent)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || aiManager.isProcessing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    // Chat list view
    private var chatListView: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                LazyVStack(spacing: 16) { // Increased spacing between messages
                    ForEach(messages) { message in
                        MessageRow(message: message)
                            .id(message.id) // Use the message ID for scrolling
                    }
                    
                    if aiManager.isProcessing {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                                .padding(.vertical, 12)
                            Spacer()
                        }
                    }
                    
                    // Empty view at the bottom to enhance scrolling capabilities
                    Color.clear
                        .frame(height: 24) // Minimum padding at bottom
                        .id("bottomID")
                }
                .padding(.horizontal, 8) // Horizontal padding for entire list
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
            .background(Color.appBackground)
            .onTapGesture {
                // Dismiss keyboard when tapping the chat area
                hideKeyboard()
            }
            .onAppear {
                // Store the proxy for use elsewhere
                DispatchQueue.main.async {
                    scrollProxy = scrollViewProxy
                    scrollToLastMessage()
                }
            }
            .onChange(of: messages.count) { _, _ in
                // Scroll to bottom when new messages are added
                DispatchQueue.main.async {
                    scrollToLastMessage()
                }
            }
        }
    }
    
    // Helper function to scroll to bottom
    private func scrollToLastMessage() {
        withAnimation(.easeOut(duration: 0.2)) {
            if let lastID = messages.last?.id {
                scrollProxy?.scrollTo(lastID, anchor: .bottom)
            } else {
                scrollProxy?.scrollTo("bottomID", anchor: .bottom)
            }
        }
    }
    
    // Helper function to hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Function to handle complete conversation reset
    private func resetConversation() {
        // Clear AIManager history - this also clears UserDefaults storage
        aiManager.clearHistory()
        
        // Clear local messages array
        messages = []
        
        // Reset error message
        errorMessage = nil
        
        // Add a fresh welcome message
        addSystemMessage("Hello! I'm your AI thinking partner. How can I help you today?")
        
        // Provide user feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    // Handler for chat history cleared notification
    private func handleChatHistoryCleared() {
        // Update UI when chat history is cleared elsewhere
        DispatchQueue.main.async {
            // Clear in-memory chat history
            self.messages = []
            
            // Make sure UserDefaults is also cleared
            // This ensures chat history is completely removed from persistent storage
            // Pass false to postNotification to avoid an infinite loop
            self.aiManager.clearHistory(postNotification: false)
            
            // Add a fresh welcome message
            self.addSystemMessage("Hello! I'm your AI thinking partner. How can I help you today?")
        }
    }
}

// MARK: - UI Components
struct TypingIndicator: View {
    @State private var firstDotOpacity: Double = 0.3
    @State private var secondDotOpacity: Double = 0.3
    @State private var thirdDotOpacity: Double = 0.3
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 15) {
            // AI Avatar or circle
            Circle()
                .fill(Color.secondaryCardBackground)
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "brain")
                        .foregroundColor(Color.iconColor)
                        .font(.system(size: 16))
                )
            
            // Typing dots
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.secondaryText)
                        .frame(width: 7, height: 7)
                        .opacity(i == 0 ? firstDotOpacity : (i == 1 ? secondDotOpacity : thirdDotOpacity))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.secondaryCardBackground)
            .cornerRadius(16)
            
            Spacer()
        }
        .padding(.top, 4)
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        let animation = Animation.easeInOut(duration: 0.4).repeatForever()
        
        withAnimation(animation.delay(0.0)) {
            firstDotOpacity = 1.0
        }
        
        withAnimation(animation.delay(0.2)) {
            secondDotOpacity = 1.0
        }
        
        withAnimation(animation.delay(0.4)) {
            thirdDotOpacity = 1.0
        }
    }
}

// Message bubble view
struct MessageRow: View {
    let message: ChatMessage
    @State private var isAnimating = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 15) {
            if message.isUser {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.primaryAccent)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .cornerRadius(25, corners: [.topLeft, .topRight, .bottomLeft])
                        .frame(maxWidth: 300, alignment: .trailing)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                }
                
                // User Avatar
                Circle()
                    .fill(Color.cardBackground)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "person")
                            .foregroundColor(Color.iconColor)
                            .font(.system(size: 18))
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            } else {
                // AI Avatar with updated styling
                Circle()
                    .fill(Color(hex: "#E74C3C"))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.secondaryCardBackground)
                        .foregroundColor(Color.primaryText)
                        .cornerRadius(20)
                        .cornerRadius(25, corners: [.topLeft, .topRight, .bottomRight])
                        .frame(maxWidth: 300, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                }
                
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview
struct AIInteractionView_Previews: PreviewProvider {
    static var previews: some View {
        AIInteractionView()
            .environmentObject(UserAIProfile())
            .preferredColorScheme(.dark)
            .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
    }
}
