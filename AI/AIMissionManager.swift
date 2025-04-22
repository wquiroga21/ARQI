//
//  AIMissionManager.swift
//  SeniorProject
//
//  Created by William Quiroga on 3/5/25.
//

import SwiftUI
import Combine

@MainActor
public class AIMissionManager: ObservableObject {
    @Published var activeMissions: [AIMission] = []
    @Published var completedMissions: [AIMission] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var availableModels: [String] = []
    
    // Expose AIManager for other views to use
    let aiManager = AIManager(chatType: .mainChat)
    
    private var cancellables = Set<AnyCancellable>()
    private let ollamaService: OllamaService
    
    public init() {
        self.ollamaService = OllamaService()
        // Configure the Ollama service with the default URL
        Task {
            await self.ollamaService.configure(baseURL: "https://db53-4-43-60-6.ngrok-free.app/api/generate")
            await self.refreshAvailableModels()
        }
    }
    
    public func refreshAvailableModels() async {
        do {
            let models = try await ollamaService.fetchAvailableModels()
            // Ensure UI updates happen on main thread
            await MainActor.run {
                self.availableModels = models
            }
        } catch {
            print("AIMissionManager - Failed to fetch models: \(error.localizedDescription)")
            // Set error state on main thread
            await MainActor.run {
                self.error = "Failed to fetch available models: \(error.localizedDescription)"
            }
        }
    }
    
    // Load missions for a user
    public func loadMissions(for userId: String) {
        // Always load missions regardless of user ID
        self.activeMissions = []
        self.completedMissions = []
        
        // Add some default missions for all users
        let defaultMissions = [
            AIMission(
                id: "default1",
                topic: "AI and Society",
                description: "Explore the impact of AI on modern society",
                status: .inProgress,
                insights: [],
                startedAt: Date(),
                completedAt: nil,
                progress: 0.0
            ),
            AIMission(
                id: "default2",
                topic: "Future of Work",
                description: "Analyze how technology is changing the workplace",
                status: .inProgress,
                insights: [],
                startedAt: Date(),
                completedAt: nil,
                progress: 0.0
            ),
            AIMission(
                id: "default3",
                topic: "Climate Solutions",
                description: "Investigate innovative approaches to climate change",
                status: .inProgress,
                insights: [],
                startedAt: Date(),
                completedAt: nil,
                progress: 0.0
            )
        ]
        
        self.activeMissions = defaultMissions
        
        // Notify observers that missions have been loaded
        objectWillChange.send()
    }
    
    // Start a new mission
    public func startMission(userId: String, topic: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !topic.isEmpty else {
            let error = NSError(domain: "AIMissionError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Topic cannot be empty"])
            completion(.failure(error))
            return
        }
        
        self.isLoading = true
        self.error = nil
        
        // Create a new mission
        let newMission = AIMission(
            id: UUID().uuidString,
            topic: topic,
            description: "Explore and analyze perspectives on \(topic)",
            status: .inProgress,
            insights: [],
            startedAt: Date(),
            completedAt: nil,
            progress: 0.1
        )
        
        // Add to active missions
        self.activeMissions.append(newMission)
        
        // Notify observers
        self.objectWillChange.send()
        
        // Complete with success
        self.isLoading = false
        completion(.success(()))
        
        // Start mission progress simulation
        Task {
            await MainActor.run {
                self.simulateMissionProgress(userId: userId, missionId: newMission.id)
            }
        }
    }
    
    // Simulate mission progress
    public func simulateMissionProgress(userId: String, missionId: String, model: String = "mistral:latest") {
        // Find the mission in active missions
        guard let missionIndex = activeMissions.firstIndex(where: { $0.id == missionId }) else {
            print("Mission not found: \(missionId)")
            return
        }
        
        // Create a copy of the mission to modify
        var missionCopy = activeMissions[missionIndex]
        
        // Update mission status
        missionCopy.status = .inProgress
        activeMissions[missionIndex] = missionCopy
        
        // Notify observers of the change
        objectWillChange.send()
        
        // Generate insights using AI
        Task {
            do {
                let prompt = "Generate 5 key insights about \(missionCopy.topic). Each insight should be a single sentence."
                let response = try await self.ollamaService.generateResponse(prompt: prompt, model: model)
                
                // Process the response into insights
                let insights = response.components(separatedBy: "\n")
                    .filter { !$0.isEmpty }
                    .prefix(5)
                    .map { insight in
                        AIMissionInsight(
                            id: UUID().uuidString,
                            content: insight.trimmingCharacters(in: .whitespacesAndNewlines),
                            timestamp: Date()
                        )
                    }
                
                // Update the mission with insights
                await MainActor.run {
                    if let index = self.activeMissions.firstIndex(where: { $0.id == missionId }) {
                        var updatedMission = self.activeMissions[index]
                        updatedMission.insights = Array(insights)
                        updatedMission.status = .completed
                        updatedMission.completedAt = Date()
                        updatedMission.progress = 1.0
                        
                        // Move to completed missions
                        self.activeMissions.remove(at: index)
                        self.completedMissions.append(updatedMission)
                        
                        // Notify observers
                        self.objectWillChange.send()
                    }
                }
            } catch {
                print("Error generating insights: \(error)")
                
                // Update mission status to failed
                await MainActor.run {
                    if let index = self.activeMissions.firstIndex(where: { $0.id == missionId }) {
                        var updatedMission = self.activeMissions[index]
                        updatedMission.status = .failed
                        updatedMission.progress = 0.0
                        self.activeMissions[index] = updatedMission
                        
                        // Notify observers
                        self.objectWillChange.send()
                    }
                }
            }
        }
    }
}
