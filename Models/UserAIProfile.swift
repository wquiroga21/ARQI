//
//  UserAIProfile.swift
//  SeniorProject
//
//  Created by William Quiroga on 2/21/25.
//

import Foundation
import SwiftUI

class UserAIProfile: ObservableObject {
    @Published var id: UUID = UUID()
    @Published var aiName: String = ""
    @Published var aiTone: String = "Balanced"
    @Published var selectedTraits: [String] = []
    @Published var hasCompletedInitialSetup: Bool = false
    @Published var interactionStyle: InteractionStyle?
    @Published var perspectiveType: String = "Balanced"
    @Published var prioritizesNewIdeas: Bool = false
    @Published var isResettingProfile: Bool = false
    @Published var isFirstLaunch: Bool
    
    // AI Connection Settings
    @Published var aiServerAddress: String = ""
    @Published var aiModel: String = "mistral"
    @Published var aiPersonality: String = ""

    /// ✅ **Added missing available traits**
    let availableTraits = [
        "Strategic", "Empathetic", "Creative", "Critical",
        "Analytical", "Intuitive", "Practical", "Visionary"
    ]
    
    // Available AI models
    let availableAIModels = [
        "mistral", "llama2", "codellama", "phi2", "orca-mini"
    ]

    enum InteractionStyle: String {
        case active = "active"
        case thoughtful = "thoughtful"
        case selective = "selective"
    }

    private let defaults = UserDefaults.standard
    private let idKey = "userProfileId"
    private let traitsKey = "selectedTraits"
    private let setupKey = "hasCompletedInitialSetup"
    private let styleKey = "interactionStyle"
    private let perspectiveKey = "perspectiveType"
    private let prioritizeIdeasKey = "prioritizesNewIdeas"
    private let aiNameKey = "aiName"
    private let aiToneKey = "aiTone"
    
    // Keys for AI connection settings
    private let aiServerAddressKey = "ai_server_address"
    private let aiModelKey = "ai_model"
    private let aiPersonalityKey = "ai_personality"

    init() {
        self.isFirstLaunch = !defaults.bool(forKey: "hasLaunchedBefore")
        self.isResettingProfile = false
        self.selectedTraits = []
        self.perspectiveType = defaults.string(forKey: perspectiveKey) ?? "Balanced"
        self.prioritizesNewIdeas = defaults.bool(forKey: prioritizeIdeasKey)

        if let idString = defaults.string(forKey: idKey), let savedId = UUID(uuidString: idString) {
            self.id = savedId
        } else {
            let newId = UUID()
            self.id = newId
            defaults.set(newId.uuidString, forKey: idKey)
        }

        if !self.isFirstLaunch {
            if let savedName = defaults.string(forKey: aiNameKey) {
                aiName = savedName
            }
            if let savedTone = defaults.string(forKey: aiToneKey) {
                aiTone = savedTone
            }
            if let styleRaw = defaults.string(forKey: styleKey) {
                interactionStyle = InteractionStyle(rawValue: styleRaw)
            }
            if let savedTraits = defaults.array(forKey: traitsKey) as? [String] {
                selectedTraits = savedTraits
            }
            
            // Load AI connection settings
            if let serverAddress = defaults.string(forKey: aiServerAddressKey) {
                aiServerAddress = serverAddress
            }
            if let model = defaults.string(forKey: aiModelKey) {
                aiModel = model
            }
            if let personality = defaults.string(forKey: aiPersonalityKey) {
                aiPersonality = personality
            } else {
                // Default personality based on tone
                aiPersonality = getDefaultPersonalityPrompt(for: aiTone)
            }
        }

        hasCompletedInitialSetup = defaults.bool(forKey: setupKey)
    }

    /// ✅ **Save AI Name & Tone**
    func saveAIPersonality(name: String, tone: String) {
        self.aiName = name
        self.aiTone = tone
        hasCompletedInitialSetup = true
        
        // Set a default personality prompt based on tone
        if aiPersonality.isEmpty {
            aiPersonality = getDefaultPersonalityPrompt(for: tone)
            defaults.set(aiPersonality, forKey: aiPersonalityKey)
        }

        defaults.set(name, forKey: aiNameKey)
        defaults.set(tone, forKey: aiToneKey)
        defaults.set(true, forKey: setupKey)
    }
    
    /// Save AI connection settings
    func saveAIConnectionSettings(serverAddress: String, model: String, personality: String) {
        self.aiServerAddress = serverAddress
        self.aiModel = model
        self.aiPersonality = personality
        
        defaults.set(serverAddress, forKey: aiServerAddressKey)
        defaults.set(model, forKey: aiModelKey)
        defaults.set(personality, forKey: aiPersonalityKey)
    }

    /// ✅ **Add & Remove Traits**
    func addTrait(_ trait: String) {
        guard selectedTraits.count < 3, !selectedTraits.contains(trait) else { return }
        selectedTraits.append(trait)
        defaults.set(selectedTraits, forKey: traitsKey)
    }

    func removeTrait(_ trait: String) {
        selectedTraits.removeAll { $0 == trait }
        defaults.set(selectedTraits, forKey: traitsKey)
    }

    /// ✅ **Reset AI Profile**
    func resetProfile() {
        isResettingProfile = true
        selectedTraits = []
        interactionStyle = nil
        aiTone = "Balanced"
        perspectiveType = "Balanced"
        prioritizesNewIdeas = false
        hasCompletedInitialSetup = false
        aiName = ""
        
        // Don't reset AI connection settings when resetting profile

        defaults.removeObject(forKey: traitsKey)
        defaults.removeObject(forKey: styleKey)
        defaults.removeObject(forKey: aiToneKey)
        defaults.removeObject(forKey: aiNameKey)
        defaults.removeObject(forKey: perspectiveKey)
        defaults.removeObject(forKey: prioritizeIdeasKey)
        defaults.synchronize()
    }
    
    /// Reset AI connection settings
    func resetAIConnectionSettings() {
        aiServerAddress = ""
        aiModel = "mistral"
        aiPersonality = getDefaultPersonalityPrompt(for: aiTone)
        
        defaults.removeObject(forKey: aiServerAddressKey)
        defaults.removeObject(forKey: aiModelKey)
        defaults.removeObject(forKey: aiPersonalityKey)
    }

    /// ✅ **Save User Preferences**
    func savePreferences() {
        defaults.set(perspectiveType, forKey: perspectiveKey)
        defaults.set(prioritizesNewIdeas, forKey: prioritizeIdeasKey)
    }
    
    /// Get a default personality prompt based on the AI tone
    private func getDefaultPersonalityPrompt(for tone: String) -> String {
        switch tone {
        case "Analytical":
            return "You are an analytical AI assistant. Focus on facts, data, and logical analysis. Provide well-structured responses that break down complex topics."
        case "Creative":
            return "You are a creative AI assistant. Think outside the box and offer innovative perspectives and ideas. Use metaphors and analogies to explain concepts."
        case "Empathetic":
            return "You are an empathetic AI assistant. Be understanding, warm, and supportive. Focus on the emotional aspects of questions and respond with care and sensitivity."
        case "Academic":
            return "You are an academic AI assistant. Provide detailed, well-researched responses with scholarly depth. Reference concepts and principles where appropriate."
        case "Practical":
            return "You are a practical AI assistant. Focus on actionable advice and real-world applications. Keep explanations concise and implementation-focused."
        default: // Balanced
            return "You are a balanced AI assistant. Be helpful, concise, and accurate. Provide a mix of practical advice and deeper insights when appropriate."
        }
    }

    /// Reset to default settings
    func resetToDefaults() {
        aiName = ""
        aiTone = "Balanced"
        aiModel = "mistral"
        aiServerAddress = "https://your-default-server.com/api/generate"
        aiPersonality = "You are a friendly AI assistant. Be helpful, concise, and accurate."
        perspectiveType = "Balanced"
        selectedTraits = []
    }
}
