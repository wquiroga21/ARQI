//
//  Constants.swift
//  SeniorProject
//
//  Created by William Quiroga on 2/26/25.
//

import Foundation

struct Constants {
    // MARK: - API Keys
    // Note: In a production app, these would be secured using Keychain or environment variables
    static let openAIAPIKey = "YOUR_OPENAI_API_KEY" // Replace with actual key in production
    
    // MARK: - API Endpoints
    static let openAIEndpoint = "https://api.openai.com/v1/chat/completions"
    
    // MARK: - AI Configuration
    static let defaultModel = "gpt-4"
    static let fallbackModel = "gpt-3.5-turbo"
    static let maxTokens = 1000
    static let temperature = 0.7
    static let presencePenalty = 0.0
    static let frequencyPenalty = 0.0
    
    // MARK: - Storage Keys
    static let userProfileKey = "user_profile"
    static let aiSettingsKey = "ai_settings"
    static let conversationsKey = "conversations"
    
    // MARK: - Chat Configuration
    static let maxStoredConversations = 20
    static let maxMessagesPerConversation = 100
    
    // MARK: - UI Configuration
    static let primaryColor = "primaryColor" // Color asset name
    static let secondaryColor = "secondaryColor" // Color asset name
    static let accentColor = "accentColor" // Color asset name
    
    // MARK: - App Configuration
    static let appName = "AI Companion"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Feature Flags
    static let enableAIMissions = true
    static let enableMultimodalInput = true
    static let enableVoiceInteraction = true
    static let enableDebugMode = false // Set to true for development
}
