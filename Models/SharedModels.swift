import SwiftUI

// Define shared models here to avoid duplication

// Suggested mission model for explore features
struct SuggestedMission: Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let participantsCount: Int
} 